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

extension Animation {

    /// Begins an interactive animation on the given `element`.
    ///
    /// The animation will not be applied to the `element` until an action is taken with the returned
    /// `InteractiveAnimationInstance`, either by setting the progress directly or starting progression to the beggining
    /// or end of the animation.
    ///
    /// - parameter element: The element to be animated.
    public func performInteractive(
        on element: ElementType
    ) -> InteractiveAnimationInstance {
        return InteractiveAnimationInstance(
            animation: self,
            element: element
        )
    }

}

// MARK: -

public final class InteractiveAnimationInstance: AnimationInstance {

    // MARK: - Life Cycle

    internal init<ElementType: AnyObject>(
        animation: Animation<ElementType>,
        element: ElementType
    ) {
        let driver = InteractiveDriver(duration: animation.duration)

        self.interactiveDriver = driver

        super.init(animation: animation, element: element, driver: driver)
    }

    // MARK: - Private Properties

    private let interactiveDriver: InteractiveDriver

    // MARK: - Public Methods

    /// Updates the progress of the animation to the `relativeTimestamp`.
    ///
    /// If the animation is currently running on its own (from calling either `animateToBeginning(using:)` or
    /// `animateToEnd(using:)`), the animation will be paused.
    public func updateProgress(to relativeTimestamp: Double) {
        interactiveDriver.updateProgress(to: relativeTimestamp)
    }

    /// Animate in reverse to the beginning of the animation.
    ///
    /// The `curve` is applied on top of the animation's curve.
    public func animateToBeginning(using curve: AnimationCurve = LinearAnimationCurve()) {
        interactiveDriver.animateToBeginning(using: curve)
    }

    /// Animate forward to the end of the animation.
    ///
    /// The `curve` is applied on top of the animation's curve.
    public func animateToEnd(using curve: AnimationCurve = LinearAnimationCurve()) {
        interactiveDriver.animateToEnd(using: curve)
    }

}
