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

import QuartzCore

/// An animation driver that is controlled by a `CADisplayLink`. This driver is intended for use with non-interactive
/// animations that have a specified duration.
@MainActor
internal final class DisplayLinkDriver: Driver {

    // MARK: - Life Cycle

    internal init(
        delay: TimeInterval,
        duration: TimeInterval,
        repeatStyle: AnimationRepeatStyle,
        completion: ((Bool) -> Void)?,
        displayLinkFactory: DisplayLinkFactory = CADisplayLink.init(target:selector:)
    ) {
        self.delay = delay
        self.duration = (duration * systemAnimationCoefficient())
        self.repeatStyle = repeatStyle
        self.completions = [completion].compactMap { $0 }

        self.displayLink = displayLinkFactory(self, #selector(renderCurrentFrame))
    }

    // MARK: - Private Types

    private struct Frame {

        var relativeTimestamp: Double

        var executingInReverse: Bool

    }

    private enum Status {

        case active

        case completed(success: Bool)

    }

    // MARK: - Private Properties

    private let delay: TimeInterval

    private let duration: TimeInterval

    private let repeatStyle: AnimationRepeatStyle

    private var completions: [(Bool) -> Void]

    private var displayLink: DisplayLinkDriverDisplayLink?

    private var startTime: TimeInterval?

    private var lastRenderedFrame: Frame?

    private var status: Status = .active

    // MARK: - Private Computed Properties

    private var totalRelativeDuration: Double {
        switch repeatStyle {
        case .repeating(count: 0, autoreversing: _):
            return .infinity

        case let .repeating(count: count, autoreversing: _):
            return Double(count)
        }
    }

    private var finalCycleIsReversed: Bool {
        switch repeatStyle {
        case .repeating(count: _, autoreversing: false),
             .repeating(count: 0, autoreversing: _):
            return false

        case let .repeating(count: count, autoreversing: true):
            return count % 2 == 0
        }
    }

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
        switch (behavior, finalCycleIsReversed) {
        case (.revert, _), (.complete, true):
            if let lastRenderedFrame = lastRenderedFrame, lastRenderedFrame.executingInReverse {
                animationInstance.executeBlocks(from: lastRenderedFrame.relativeTimestamp, .exclusive, to: 0)

            } else if let lastRenderedFrame = lastRenderedFrame {
                animationInstance.executeBlocks(from: lastRenderedFrame.relativeTimestamp, .exclusive, to: 1)
                animationInstance.executeBlocks(from: 1, .inclusive, to: 0)

            } else {
                // No-op. We haven't rendered any frames yet, so there's nothing to revert.
            }

            animationInstance.renderFrame(at: 0)

        case (.halt, _):
            break

        case (.complete, false):
            if let lastRenderedFrame = lastRenderedFrame, !lastRenderedFrame.executingInReverse {
                animationInstance.executeBlocks(from: lastRenderedFrame.relativeTimestamp, .exclusive, to: 1)

            } else if let lastRenderedFrame = lastRenderedFrame {
                animationInstance.executeBlocks(from: lastRenderedFrame.relativeTimestamp, .exclusive, to: 0)
                animationInstance.executeBlocks(from: 0, .inclusive, to: 1)

            } else {
                animationInstance.executeBlocks(from: 0, .inclusive, to: 1)
            }

            animationInstance.renderFrame(at: 1)
        }

        complete(success: false)
    }

    // MARK: - Internal Methods

    func start(timeFactory: () -> CFTimeInterval = CACurrentMediaTime) {
        displayLink?.add(to: .main, forMode: .common)
        startTime = timeFactory()

        // If there's no delay, render the first frame immediately rather than waiting until the next run loop. This
        // ensures that animations start immediately, and specifically that the final state of zero duration animations
        // are applied without any delay.
        if delay == 0 {
            renderCurrentFrame()
        }
    }

    func addCompletion(_ completion: @escaping (Bool) -> Void) {
        completions.append(completion)
    }

    @objc func renderCurrentFrame() {
        switch status {
        case .active:
            break

        case let .completed(success: success):
            displayLink?.invalidate()
            displayLink = nil

            animationInstance = nil

            completions.forEach { $0(success) }
            completions = []

            return
        }

        guard let displayLink = displayLink, let startTime = startTime else {
            return
        }

        // Ensure the delay has passed before starting the animation. If the timestamp is zero, the display link hasn't
        // been added to the run loop yet, so this must be calling through from the `start()` call.
        guard displayLink.timestamp >= (startTime + delay) || displayLink.timestamp == 0 else {
            return
        }

        // Calculate the relative timestamp into the animation, where 0 is the beginning of the animation (after the
        // delay), 1 is the end of the first cycle, 2 is the end of the second cycle, etc.
        let relativeTimestamp: Double
        if duration == 0 {
            relativeTimestamp = 1

        } else {
            let currentTimestamp = displayLink.timestamp.clamped(min: startTime, max: .greatestFiniteMagnitude)
            relativeTimestamp = (currentTimestamp - startTime - delay) / duration
        }

        // Calculate the metrics for the current cycle. The relative timestamp for a forward cycle goes from 0 to 1, and
        // for a reverse cycle goes from 1 to 0.
        let relativeTimestampInCycle: Double
        let cycle: Int
        let currentCycleIsReversed: Bool
        switch repeatStyle {
        case .repeating(count: 1, autoreversing: _):
            relativeTimestampInCycle = relativeTimestamp.clamped(in: 0...1)

            cycle = 1
            currentCycleIsReversed = false

        case let .repeating(count: count, autoreversing: autoreversing):
            // Calculate what cycle the animation is in, indexed starting at 0.
            let lastCycle = (count == 0) ? Int.max : Int(count - 1)
            cycle = Int(relativeTimestamp).clamped(in: 0...lastCycle)

            currentCycleIsReversed = (autoreversing && cycle % 2 != 0)

            if currentCycleIsReversed {
                relativeTimestampInCycle = (1 - (relativeTimestamp - Double(cycle))).clamped(in: 0...1)
            } else {
                relativeTimestampInCycle = (relativeTimestamp - Double(cycle)).clamped(in: 0...1)
            }
        }

        if let lastRenderedFrame = lastRenderedFrame {
            switch (lastRenderedFrame.executingInReverse, currentCycleIsReversed) {
            case (false, false):
                if relativeTimestampInCycle > lastRenderedFrame.relativeTimestamp {
                    animationInstance.executeBlocks(from: lastRenderedFrame.relativeTimestamp, .exclusive, to: relativeTimestampInCycle)

                } else {
                    // Both cycles are running forward, but the timestamp we're running to is earlier. Run through the
                    // rest of the last cycle, run in reverse back to the beginning, then run the rest of the way into
                    // the next cycle.
                    animationInstance.executeBlocks(from: lastRenderedFrame.relativeTimestamp, .exclusive, to: 1)
                    animationInstance.executeBlocks(from: 1, .inclusive, to: 0)
                    animationInstance.executeBlocks(from: 0, .inclusive, to: relativeTimestampInCycle)
                }

            case (false, true):
                animationInstance.executeBlocks(from: lastRenderedFrame.relativeTimestamp, .exclusive, to: 1)
                animationInstance.executeBlocks(from: 1, .inclusive, to: relativeTimestampInCycle)

            case (true, true):
                if relativeTimestampInCycle < lastRenderedFrame.relativeTimestamp {
                    animationInstance.executeBlocks(from: lastRenderedFrame.relativeTimestamp, .exclusive, to: relativeTimestampInCycle)

                } else {
                    // Both cycles are running in reverse, but the timestamp we're running to is later. Run through the
                    // rest of the last cycle, run forward through to the end, then run the rest of the way into the
                    // next cycle.
                    animationInstance.executeBlocks(from: lastRenderedFrame.relativeTimestamp, .exclusive, to: 0)
                    animationInstance.executeBlocks(from: 0, .inclusive, to: 1)
                    animationInstance.executeBlocks(from: 1, .inclusive, to: relativeTimestampInCycle)
                }

            case (true, false):
                animationInstance.executeBlocks(from: lastRenderedFrame.relativeTimestamp, .exclusive, to: 0)
                animationInstance.executeBlocks(from: 0, .inclusive, to: relativeTimestampInCycle)
            }

        } else if currentCycleIsReversed {
            // The only way this is possible is if we skipped the first cycle (since the first cycle should always run
            // forward). Run an entire cycle forward, then run the reverse cycle to the relative timestamp.
            animationInstance.executeBlocks(from: 0, .inclusive, to: 1)
            animationInstance.executeBlocks(from: 1, .inclusive, to: relativeTimestampInCycle)

        } else {
            // This is the first cycle. Run from the beginning to the frame's timestamp.
            animationInstance.executeBlocks(from: 0, .inclusive, to: relativeTimestampInCycle)
        }

        animationInstance.renderFrame(at: relativeTimestampInCycle)

        lastRenderedFrame = .init(
            relativeTimestamp: relativeTimestampInCycle,
            executingInReverse: currentCycleIsReversed
        )

        if relativeTimestamp >= totalRelativeDuration {
            animationInstance?.markAnimationAsComplete()
            complete(success: true)
        }
    }

    // MARK: - Private Methods

    private func complete(success: Bool) {
        // Set the status to `completed` in order to stop rendering frames. We'll call the completion handlers and
        // invalidate the display link on the next display loop pass. This ensures that the final frame is drawn to
        // the screen before the completion handlers are called, in case they do work that would otherwise cause a
        // delay in drawing.
        status = .completed(success: success)
    }

}

// MARK: -

/// Returns the animation drag coefficient defined by UIKit. In the simulator, this will return 1 when slow animations
/// are disabled, and a larger value when slow animations are enabled. On device, this will always return 1.
///
/// Based on <https://stackoverflow.com/a/30323585>.
private func systemAnimationCoefficient() -> Double {
    #if targetEnvironment(simulator)
    let RTLD_DEFAULT = UnsafeMutableRawPointer(bitPattern: -2)

    guard let uiAnimationDragCoefficientSymbol = dlsym(RTLD_DEFAULT, "UIAnimationDragCoefficient") else {
        return 1
    }

    typealias VoidToFloatFunc = @convention(c) () -> Float
    let UIAnimationDragCoefficient = unsafeBitCast(uiAnimationDragCoefficientSymbol, to: VoidToFloatFunc.self)
    return Double(UIAnimationDragCoefficient())
    #else
    return 1
    #endif
}
