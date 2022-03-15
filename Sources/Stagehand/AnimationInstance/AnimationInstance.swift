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
/// `perform(on:delay:duration:repeatStyle:completion:)` method to begin the animation. That method will return an
/// instance of this class. The `AnimationInstance` can then be used to track the `status` of the animation, or to
/// cancel it.
public final class AnimationInstance {

    // MARK: - Life Cycle

    internal init<ElementType: AnyObject>(
        animation: Animation<ElementType>,
        element: ElementType,
        driver: Driver
    ) {
        var animation = animation.optimized()
        animation.computeKeyframeProperties(for: element)

        self.animationCurve = animation.curve
        self.keyframeRelativeTimestamps = animation.keyframeRelativeTimestamps

        self.renderer = Renderer(animation: animation, element: element)
        self.executor = Executor(animation: animation, element: element)

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

    private let executor: Executor

    private let perFrameExecutionBlocks: [(Double) -> Void]

    /// The relative timestamps corresponding to keyframes in the animation, without any curves applied.
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

    // MARK: - Internal Methods

    func executeBlocks(
        from startingRelativeTimestamp: Double,
        _ fromInclusivity: Executor.Inclusivity,
        to endingRelativeTimestamp: Double
    ) {
        executor.executeBlocks(from: startingRelativeTimestamp, fromInclusivity, to: endingRelativeTimestamp)
    }

    /// Renders the frame at the specific timestamp, including rendering any keyframes between the timestamp between the
    /// previously rendered frame and the specific timestamp.
    ///
    /// - parameter relativeTimestamp: The relative timestamp to render, with no curves applied.
    func renderFrame(
        at relativeTimestamp: Double
    ) {
        // If our renderer doesn't have an element to render, halt the animation since there's nothing to do.
        guard renderer.canRenderFrame() else {
            cancel(behavior: .halt)
            return
        }

        status = .animating(progress: relativeTimestamp)

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

        lastRenderedFrameRelativeTimestamp = relativeTimestamp
    }

    func markAnimationAsComplete() {
        status = .complete
    }

}
