//
//  Copyright 2020 Square Inc.
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
import QuartzCore

internal final class InteractiveDriver: Driver {

    // MARK: - Life Cycle

    internal init(duration: TimeInterval) {
        self.endToEndDuration = duration
    }

    // MARK: - Private Types

    private struct Frame {

        var relativeTimestamp: Double

        var executingInReverse: Bool

    }

    private struct AutomaticContext {

        /// The display link that's driving the current context.
        var displayLink: CADisplayLink

        /// The time at which the display link was added to the run loop.
        var startTime: TimeInterval

        /// The duration of the segment between the `startRelativeTimestamp` and `endRelativeTimestamp`.
        var segmentDuration: TimeInterval

        /// The animation curve applied on top of the segment between the `startRelativeTimestamp` and
        /// `endRelativeTimestamp`.
        var segmentCurve: AnimationCurve

        var startRelativeTimestamp: Double

        var endRelativeTimestamp: Double

        /// The current progress, based on the display link's timestamp, with the `segmentCurve` applied.
        func currentRelativeTimestamp() -> Double {
            let relativeDuration = (endRelativeTimestamp - startRelativeTimestamp)
            let progress = (displayLink.timestamp - startTime) / segmentDuration
            let curvedProgress = segmentCurve.adjustedProgress(for: progress)
            let rawRelativeTimestamp = (relativeDuration * curvedProgress + startRelativeTimestamp)
            return rawRelativeTimestamp.clamped(in: 0...1)
        }

    }

    private enum Mode {

        case manual(relativeTimestamp: Double)

        case automatic(AutomaticContext)

    }

    private enum Status {

        case active

        case completed(success: Bool)

    }

    // MARK: - Private Properties

    private let endToEndDuration: TimeInterval

    private var lastRenderedFrame: Frame?

    private var mode: Mode = .manual(relativeTimestamp: 0)

    private var status: Status = .active

    // MARK: - Driver

    /// The animation instance that owns this driver.
    ///
    /// Note that the animation instance is held strongly here. This creates a retain cycle between the driver and the
    /// animation instance. This allows the pair to continue animating even when the consumer discards the result of
    /// `Animation.performInteractive(...)` and doesn't hold a reference to the animation instance. Once the animation
    /// completes, this reference will be set to `nil` and the retain cycle will be broken.
    var animationInstance: DrivenAnimationInstance!

    func animationInstanceDidInitialize() {
        // No-op.
    }

    func animationInstanceDidCancel(behavior: AnimationInstance.CancelationBehavior) {
        switch status {
        case .active:
            break

        case .completed:
            // We're already complete. Nothing to do here.
            return
        }

        switch behavior {
        case .revert:
            mode = .manual(relativeTimestamp: 0)

        case .halt:
            switch mode {
            case .manual:
                break // No-op.

            case let .automatic(context):
                mode = .manual(relativeTimestamp: context.currentRelativeTimestamp())

                context.displayLink.invalidate()
            }

        case .complete:
            mode = .manual(relativeTimestamp: 1)
        }

        renderCurrentFrame()
        status = .completed(success: false)
        animationInstance = nil
    }

    // MARK: - Public Methods

    func animate(
        to targetRelativeTimestamp: Double,
        using curve: AnimationCurve,
        duration: TimeInterval?
    ) {
        switch status {
        case .active:
            break

        case .completed:
            // The animation has already completed, so there's nothing to animate.
            return
        }

        // Invalidate any in-progress automatic animation.
        if case let .automatic(context) = mode {
            context.displayLink.invalidate()
        }

        let startRelativeTimestamp = lastRenderedFrame?.relativeTimestamp ?? 0
        let segmentRelativeDuration = (targetRelativeTimestamp - startRelativeTimestamp)
        let segmentDuration = duration ?? abs(segmentRelativeDuration * endToEndDuration)

        let context = AutomaticContext(
            displayLink: .init(target: self, selector: #selector(renderCurrentFrame)),
            startTime: CACurrentMediaTime(),
            segmentDuration: segmentDuration,
            segmentCurve: curve,
            startRelativeTimestamp: startRelativeTimestamp,
            endRelativeTimestamp: targetRelativeTimestamp
        )

        mode = .automatic(context)

        context.displayLink.add(to: .current, forMode: .common)
    }

    func updateProgress(to relativeTimestamp: Double) {
        switch status {
        case .active:
            break

        case .completed:
            return
        }

        // Invalidate any in-progress automatic animation.
        if case let .automatic(context) = mode {
            context.displayLink.invalidate()
        }

        mode = .manual(relativeTimestamp: relativeTimestamp)

        renderCurrentFrame()
    }

    // MARK: - Private Methods

    @objc private func renderCurrentFrame() {
        switch status {
        case .active:
            break

        case .completed:
            return
        }

        let relativeTimestamp: Double
        switch mode {
        case let .manual(relativeTimestamp: manualTimestamp):
            relativeTimestamp = manualTimestamp

        case let .automatic(context):
            relativeTimestamp = context.currentRelativeTimestamp()
        }

        if let lastRenderedFrame = lastRenderedFrame {
            animationInstance.executeBlocks(
                from: lastRenderedFrame.relativeTimestamp,
                .exclusive,
                to: relativeTimestamp
            )

        } else {
            animationInstance.executeBlocks(
                from: 0,
                .inclusive,
                to: relativeTimestamp
            )
        }

        animationInstance.renderFrame(at: relativeTimestamp)

        lastRenderedFrame = .init(relativeTimestamp: relativeTimestamp, executingInReverse: false)

        if case let .automatic(context) = mode, context.endRelativeTimestamp == relativeTimestamp {
            // The automatic part of the animation is complete.
            context.displayLink.invalidate()
            mode = .manual(relativeTimestamp: relativeTimestamp)
        }
    }

}
