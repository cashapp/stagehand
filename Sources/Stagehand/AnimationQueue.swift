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

    private let queue: AnimationInstanceQueue = .init()

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

        queue.enqueue(instance: instance, driver: driver)

        return instance
    }

    /// Cancels all pending animations currently in the queue.
    public func cancelPendingAnimations() {
        queue.cancelPendingAnimations()
    }

}
