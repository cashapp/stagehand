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

internal final class InteractiveDriver: Driver {

    // MARK: - Life Cycle

    internal init(
        duration: TimeInterval
    ) {
        self.totalDuration = duration
    }

    // MARK: - Private Types

    private struct Frame {

        var relativeTimestamp: Double

        var executingInReverse: Bool

    }

    private struct AutomaticContext {

        var displayLink: CADisplayLink

        var startTime: TimeInterval

        var animationCurve: AnimationCurve

        var startRelativeTimestamp: Double

        var endRelativeTimestamp: Double

        /// The current progress, based on the display link's timestamp, with the `animationCurve` applied.
        func currentRelativeTimestamp(totalDuration: TimeInterval) -> Double {
            let relativeDuration = (endRelativeTimestamp - startRelativeTimestamp)
            let duration = abs(relativeDuration * totalDuration)
            let progress = (displayLink.timestamp - startTime) / duration
            let curvedProgress = animationCurve.adjustedProgress(for: progress)
            let rawRelativeTimestamp = (relativeDuration * curvedProgress + startRelativeTimestamp)
            return rawRelativeTimestamp.clamped(in: 0...1)
        }

    }

    private enum Mode {

        case manual(relativeTimestamp: Double)

        case automatic(AutomaticContext)

    }

    // MARK: - Private Properties

    private let totalDuration: TimeInterval

    private var lastRenderedFrame: Frame?

    private var mode: Mode = .manual(relativeTimestamp: 0)

    // MARK: - Driver

    // Note that the animation instance is held strongly here. This creates a retain cycle between the driver and the
    // animation instance. This allows the pair to continue animating even when the consumer discards the result of
    // `Animation.perform(...)` and doesn't hold a reference to the animation instance. Once the animation completes,
    // this reference will be set to `nil` and the retain cycle will be broken.
    var animationInstance: DrivenAnimationInstance!

    func animationInstanceDidInitialize() {
        // No-op.
    }

    func animationInstanceDidCancel(behavior: AnimationInstance.CancelationBehavior) {
        switch behavior {
        case .revert:
            mode = .manual(relativeTimestamp: 0)

        case .halt:
            switch mode {
            case .manual:
                break // No-op.

            case let .automatic(context):
                mode = .manual(relativeTimestamp: context.currentRelativeTimestamp(totalDuration: totalDuration))

                context.displayLink.invalidate()
            }

        case .complete:
            mode = .manual(relativeTimestamp: 1)
        }
    }

    // MARK: - Public Methods

    func animateToBeginning(using curve: AnimationCurve) {
        // Invalidate any in-progress automatic animation.
        if case let .automatic(context) = mode {
            context.displayLink.invalidate()
        }

        let context = AutomaticContext(
            displayLink: .init(target: self, selector: #selector(renderCurrentFrame)),
            startTime: CACurrentMediaTime(),
            animationCurve: curve,
            startRelativeTimestamp: lastRenderedFrame?.relativeTimestamp ?? 0,
            endRelativeTimestamp: 0
        )

        mode = .automatic(context)

        context.displayLink.add(to: .current, forMode: .common)
    }

    func animateToEnd(using curve: AnimationCurve) {
        // Invalidate any in-progress automatic animation.
        if case let .automatic(context) = mode {
            context.displayLink.invalidate()
        }

        let context = AutomaticContext(
            displayLink: .init(target: self, selector: #selector(renderCurrentFrame)),
            startTime: CACurrentMediaTime(),
            animationCurve: curve,
            startRelativeTimestamp: lastRenderedFrame?.relativeTimestamp ?? 0,
            endRelativeTimestamp: 1
        )

        mode = .automatic(context)

        context.displayLink.add(to: .current, forMode: .common)
    }

    func updateProgress(to relativeTimestamp: Double) {
        // Invalidate any in-progress automatic animation.
        if case let .automatic(context) = mode {
            context.displayLink.invalidate()
        }

        mode = .manual(relativeTimestamp: relativeTimestamp)

        renderCurrentFrame()
    }

    // MARK: - Private Methods

    @objc private func renderCurrentFrame() {
        let relativeTimestamp: Double
        switch mode {
        case let .manual(relativeTimestamp: manualTimestamp):
            relativeTimestamp = manualTimestamp

        case let .automatic(context):
            relativeTimestamp = context.currentRelativeTimestamp(totalDuration: totalDuration)
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
