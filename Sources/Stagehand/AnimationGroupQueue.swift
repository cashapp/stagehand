//
//  Copyright 2021 Square Inc.
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

/// An animation queue for performing a set of `AnimationGroup`s in sequence.
public final class AnimationGroupQueue {

    // MARK: - Life Cycle

    public init() {}

    // MARK: - Private Properties

    private var queue: AnimationInstanceQueue = .init()

    // MARK: - Public Methods

    @discardableResult
    public func enqueue(
        animationGroup: AnimationGroup,
        duration: TimeInterval? = nil,
        repeatStyle: AnimationRepeatStyle? = nil
    ) -> AnimationInstance {
        let driver = DisplayLinkDriver(
            delay: 0,
            duration: duration ?? animationGroup.implicitDuration,
            repeatStyle: repeatStyle ?? animationGroup.implicitRepeatStyle,
            completion: { finished in
                animationGroup.completions.forEach { $0(finished) }
            }
        )

        let instance = AnimationInstance(
            animation: animationGroup.animation,
            element: animationGroup.elementContainer,
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
