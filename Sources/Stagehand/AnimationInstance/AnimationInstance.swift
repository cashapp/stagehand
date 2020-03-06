//
//  Copyright 2019 Square Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

/// An instance of an animation that has been triggered to begin.
///
/// Do not create an `AnimationInstance` directly. Instead, construct an `Animation`, then call the animation's
/// `perform(on:delay:completion:)` method to begin the animation. That method will return an instance of this class.
/// The `AnimationInstance` can then be used to track the `status` of the animation, or to cancel it.
public final class AnimationInstance {

    // MARK: - Life Cycle

    internal init<ElementType: AnyObject>(
        animation: Animation<ElementType>,
        element: ElementType,
        driver: Driver
    ) {
        let animation = animation.optimized()

        self.animationCurve = animation.curve
        self.keyframeRelativeTimestamps = animation.keyframeRelativeTimestamps

        self.renderer = Renderer(animation: animation, element: element)

        let executionBlocks: [ExecutionBlock] = animation.executionBlocks
            .map { executionBlock in
                return ExecutionBlock(
                    relativeTimestamp: executionBlock.relativeTimestamp,
                    forwardBlock: { [weak element] _ in
                        guard let element = element else {
                            return
                        }

                        executionBlock.forwardBlock(element)
                    },
                    reverseBlock: { [weak element] in
                        guard let element = element else {
                            return
                        }

                        executionBlock.reverseBlock(element)
                    }
                )
            }

        let assignmentBlocks: [ExecutionBlock] = animation.assignments
            .map { assignment in
                return ExecutionBlock(
                    relativeTimestamp: assignment.relativeTimestamp,
                    forwardBlock: { [weak element] executionBlock in
                        guard let element = element else {
                            return
                        }

                        let reverseAssignment = assignment.generateReverseAssignBlock(element)
                        executionBlock.reverseBlock = { reverseAssignment(element) }

                        assignment.assignBlock(element)
                    },
                    reverseBlock: {
                        // No-op. This block will be replaced when the `forwardBlock` is invoked.
                    }
                )
            }

        self.sortedExecutionBlocks = (executionBlocks + assignmentBlocks)
            .sorted { $0.relativeTimestamp < $1.relativeTimestamp }

        self.perFrameExecutionBlocks = animation.perFrameExecutionBlocks
            .map { block in
                return { [weak element] relativeTimestamp in
                    guard let element = element else {
                        return
                    }

                    block(
                        .init(
                            element: element,
                            uncurvedProgress: relativeTimestamp,
                            progress: animation.curve.adjustedProgress(for: relativeTimestamp)
                        )
                    )
                }
            }

        self.driver = driver

        driver.animationInstance = self
        driver.animationInstanceDidInitialize()
    }

    // MARK: - Public Properties

    public enum Status {

        /// The animation has not yet begun.
        case pending

        /// The animation is in progress.
        ///
        /// - `progress`: Value in range [0,1] representing the progress of the animation, where 0 is the first frame
        /// and 1 is final frame.
        case animating(progress: Double)

        /// The animation has successfully completed.
        case complete

        /// The animation was canceled with the specified behavior.
        case canceled(behavior: CancelationBehavior)

    }

    public private(set) var status: Status = .pending

    // MARK: - Private Properties

    private let driver: Driver

    private let animationCurve: AnimationCurve

    private let renderer: AnyRenderer

    private var sortedExecutionBlocks: [ExecutionBlock]

    private let perFrameExecutionBlocks: [(Double) -> Void]

    private let keyframeRelativeTimestamps: [Double]

    private var lastRenderedFrameRelativeTimestamp: Double?

    // MARK: - Public Methods - Cancelation

    public enum CancelationBehavior {

        /// Return the element back to its state at the beginning of the animation.
        case revert

        /// Stop the animation at its current progress.
        case halt

        /// Apply the final values of the animation.
        case complete

    }

    /// Cancel the animation using the specified `behavior`.
    ///
    /// If the animation has already concluded (either by completing normally, or by having already been cancelled),
    /// this method is a no-op.
    public func cancel(behavior: CancelationBehavior = .halt) {
        switch status {
        case .pending, .animating:
            break

        case .complete, .canceled:
            // If the animation is already complete, or was canceled, there is nothing to cancel.
            return
        }

        status = .canceled(behavior: behavior)
        driver.animationInstanceDidCancel(behavior: behavior)
    }

    // MARK: - Internal Methods - Execution

    internal enum Inclusivity {

        case inclusive
        case exclusive

        // MARK: - Private Computed Properties

        fileprivate var forwardFromCompare: (Double, Double) -> Bool {
            switch self {
            case .inclusive:
                return (>=)
            case .exclusive:
                return (>)
            }
        }

        fileprivate var reverseFromCompare: (Double, Double) -> Bool {
            switch self {
            case .inclusive:
                return (<=)
            case .exclusive:
                return (<)
            }
        }

    }

    func executeBlocks(
        from startingRelativeTimestamp: Double,
        _ fromInclusivity: Inclusivity,
        to endingRelativeTimestamp: Double
    ) {
        if endingRelativeTimestamp >= startingRelativeTimestamp {
            // Iterate forward through the execution blocks.
            for (index, executionBlock) in sortedExecutionBlocks.enumerated() {
                let relativeTimestamp = executionBlock.relativeTimestamp
                if fromInclusivity.forwardFromCompare(relativeTimestamp, startingRelativeTimestamp) && relativeTimestamp <= endingRelativeTimestamp {
                    // Perform the forward invocation of the execution block. When executing a property assignment, the
                    // forward block will set the reverse block, so update the stored execution block.
                    var executionBlock = executionBlock
                    executionBlock.forwardBlock(&executionBlock)
                    sortedExecutionBlocks[index] = executionBlock
                }
            }

        } else {
            // Iterate in reverse through the execution blocks.
            for executionBlock in sortedExecutionBlocks.reversed() {
                let relativeTimestamp = executionBlock.relativeTimestamp
                if fromInclusivity.reverseFromCompare(relativeTimestamp, startingRelativeTimestamp) && relativeTimestamp >= endingRelativeTimestamp {
                    executionBlock.reverseBlock()
                }
            }
        }
    }

    func renderFrame(
        at relativeTimestamp: Double
    ) {
        // If our renderer doesn't have an element to render, halt the animation since there's nothing to do.
        guard renderer.canRenderFrame() else {
            cancel(behavior: .halt)
            return
        }

        // If we skipped any keyframes since the last frame we rendered, render them now. If we don't do this, we might
        // skip rendering the last keyframe of a child animation, leaving the properties of that animation in their
        // value just shy of the value specified by the final keyframe.
        let skippedKeyframesToRender: [Double]

        if let lastRenderedTimestamp = lastRenderedFrameRelativeTimestamp {
            let skippedRangeToCheck = ClosedRange(unorderedBounds: (lastRenderedTimestamp, relativeTimestamp))
            skippedKeyframesToRender = keyframeRelativeTimestamps.filter { skippedRangeToCheck.contains($0) }

        } else {
            // We haven't rendered any frames yet. Render the initial value of each property (even if it doesn't start
            // at a relative timestamp of 0).
            renderer.renderInitialFrame()

            // If the first relative timestamp we get is greater than 0 (which is unlikely in the production usage, but
            // happens a lot in snapshot tests), we might be missing some keyframes.
            if relativeTimestamp > 0 {
                let skippedRangeToCheck = 0..<relativeTimestamp
                skippedKeyframesToRender = keyframeRelativeTimestamps.filter { skippedRangeToCheck.contains($0) }

            } else {
                skippedKeyframesToRender = []
            }
        }

        for keyframe in skippedKeyframesToRender {
            renderer.renderFrame(at: keyframe)
        }

        renderer.renderFrame(at: relativeTimestamp)

        perFrameExecutionBlocks.forEach { $0(relativeTimestamp) }

        status = .animating(progress: relativeTimestamp)

        lastRenderedFrameRelativeTimestamp = relativeTimestamp
    }

    func markAnimationAsComplete() {
        status = .complete
    }

}

// MARK: -

extension AnimationInstance {

    private struct ExecutionBlock {

        var relativeTimestamp: Double

        var forwardBlock: (inout ExecutionBlock) -> Void

        var reverseBlock: () -> Void

    }

}

// MARK: -

extension ClosedRange {

    fileprivate init(unorderedBounds bounds: (Bound, Bound)) {
        if bounds.0 < bounds.1 {
            self = (bounds.0...bounds.1)
        } else {
            self = (bounds.1...bounds.0)
        }
    }

}
