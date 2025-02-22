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

/// An `AnimationQueue` is a container for a set of animations that should be executed in sequence.
public final class AnimationQueue<ElementType: AnyObject> {

    // MARK: - Life Cycle

    public init(element: ElementType) {
        self.element = element
    }

    // MARK: - Public Properties

    public var hasInProgressAnimation: Bool {
        inProgressAnimationInstance != nil
    }

    // MARK: - Private Properties

    private let element: ElementType

    private var queue: [(instance: AnimationInstance, driver: DisplayLinkDriver)] = []

    // MARK: - Public Methods

    /// Adds the animation to the queue.
    ///
    /// If the queue was previously empty, the animation will begin immediately. If the queue was previously not empty,
    /// the animation will begin when the last animation in the queue has completed.
    ///
    /// The duration for each cycle of the animation will be determined in order of preference by:
    /// 1. An explicit duration, if provided via the `duration` parameter
    /// 2. The animation's implicit duration, as specified by the animation's `implicitDuration` property
    ///
    /// The repeat style for the animation will be determined in order of preference by:
    /// 1. An explicit repeat style, if provided via the `repeatStyle` parameter
    /// 2. The animation's implicit repeat style, as specified by the animation's `implicitRepeatStyle` property
    ///
    /// - parameter animation: The animation to add to the queue.
    /// - parameter duration: The duration to use for each cycle of the animation.
    /// - parameter repeatStyle: The repeat style to use for the animation.
    /// - returns: An animation instance that can be used to check the status of or cancel the animation.
    @discardableResult
    public func enqueue(
        animation: Animation<ElementType>,
        duration: TimeInterval? = nil,
        repeatStyle: AnimationRepeatStyle? = nil
    ) -> AnimationInstance {
        let driver = DisplayLinkDriver(
            delay: 0,
            duration: duration ?? animation.implicitDuration,
            repeatStyle: repeatStyle ?? animation.implicitRepeatStyle,
            completion: nil
        )

        let instance = AnimationInstance(
            animation: animation,
            element: element,
            driver: driver
        )

        queue.append((instance, driver))

        advanceToNextAnimationIfReady()

        return instance
    }

    public func cancelInProgressAnimation(behavior: AnimationInstance.CancelationBehavior = .halt) {
        inProgressAnimationInstance?.cancel(behavior: behavior)
    }

    /// Cancels all pending animations currently in the queue.
    public func cancelPendingAnimations() {
        queue.forEach { (instance, _) in
            if case .pending = instance.status {
                instance.cancel()
            }
        }

        purgeCompletedAndCanceledAnimations()
    }

    public func pauseBeforeNextAnimation() {
        pauseAdvancement = true
    }

    public func resume() {
        pauseAdvancement = false
        advanceToNextAnimationIfReady()
    }

    // MARK: - Private Methods

    private var pauseAdvancement = false

    private var inProgressAnimationInstance: AnimationInstance? {
        guard let currentAnimationInstance = queue.first?.instance else {
            return nil
        }

        switch currentAnimationInstance.status {
        case .pending, .animating:
            return currentAnimationInstance
        case .complete, .canceled:
            return nil
        }
    }

    private func advanceToNextAnimationIfReady() {
        guard !pauseAdvancement, let currentAnimation = queue.first else {
            return
        }

        switch currentAnimation.instance.status {
        case .pending:
            // The current animation hasn't started yet. It will be started below.
            break

        case .animating:
            // The current animation isn't complete yet.
            return

        case .complete, .canceled:
            // The current animation is complete. It will be purged below, then the next animation (if one is enqueued)
            // wil be started.
            break
        }

        purgeCompletedAndCanceledAnimations()

        guard let nextAnimation = queue.first else {
            // We've emptied the queue, nothing to do now.
            return
        }

        nextAnimation.driver.addCompletion { [weak self] _ in
            self?.advanceToNextAnimationIfReady()
        }

        nextAnimation.driver.start()
    }

    private func purgeCompletedAndCanceledAnimations() {
        queue.removeAll { (instance, _) -> Bool in
            switch instance.status {
            case .complete, .canceled:
                return true
            case .pending, .animating:
                return false
            }
        }
    }

}
