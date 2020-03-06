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

    // MARK: - Private Properties

    private let element: ElementType

    private var queue: [(instance: AnimationInstance, driver: DisplayLinkDriver)] = []

    // MARK: - Public Methods

    /// Adds the animation to the queue.
    ///
    /// If the queue was previously empty, the animation will begin immediately. If the queue was previously not empty,
    /// the animation will begin when the last animation in the queue has completed.
    @discardableResult
    public func enqueue(animation: Animation<ElementType>) -> AnimationInstance {
        let driver = DisplayLinkDriver(
            delay: 0,
            duration: animation.duration,
            repeatStyle: animation.repeatStyle,
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

    /// Cancels all pending animations currently in the queue.
    public func cancelPendingAnimations() {
        queue.forEach { (instance, _) in
            if case .pending = instance.status {
                instance.cancel()
            }
        }

        purgeCompletedAndCanceledAnimations()
    }

    // MARK: - Private Methods

    private func advanceToNextAnimationIfReady() {
        guard let currentAnimation = queue.first else {
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
