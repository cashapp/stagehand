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
    /// - parameter duration: The end-to-end duration of the animation. If `nil`, the animation's `implicitDuration`
    /// will be used as the end-to-end duration.
    public func performInteractive(
        on element: ElementType,
        duration: TimeInterval? = nil
    ) -> InteractiveAnimationInstance {
        return InteractiveAnimationInstance(
            animation: self,
            element: element,
            duration: duration ?? self.implicitDuration
        )
    }

}

// MARK: -

public final class InteractiveAnimationInstance: AnimationInstance {

    // MARK: - Life Cycle

    internal init<ElementType: AnyObject>(
        animation: Animation<ElementType>,
        element: ElementType,
        duration: TimeInterval
    ) {
        let driver = InteractiveDriver(duration: duration)

        self.interactiveDriver = driver

        super.init(animation: animation, element: element, driver: driver)
    }

    // MARK: - Private Properties

    private let interactiveDriver: InteractiveDriver

    // MARK: - Public Methods

    /// Updates the progress of the animation to the `relativeTimestamp` immediately.
    ///
    /// If the animation is currently running automatically (from calling `animate(to:using:duration:)`), the animation
    /// will be paused at the new `relativeTimestamp`.
    ///
    /// - parameter relativeTimestamp: The target relative timestamp.
    public func updateProgress(to relativeTimestamp: Double) {
        switch status {
        case .pending, .animating:
            break

        case .complete, .canceled:
            // If the animation is already complete, or was canceled, we can't animate it again.
            return
        }

        interactiveDriver.updateProgress(to: relativeTimestamp)
    }

    /// Begins animating a segment of the animation from the current relative timestamp to a specific point in the
    /// animation.
    ///
    /// The `curve` will be applied to the segment on top of any existing animation curve.
    ///
    /// The duration of the animation segment will be determined based on the follow order of preference:
    /// 1. The explicit segment duration, if specified
    /// 2. A relative portion of the explicit end-to-end duration, if specified
    /// 3. A relative portion of the animation's implicit duration
    ///
    /// - parameter relativeTimestamp: The target relative timestamp.
    /// - parameter curve: The curve to apply over the segment of the animation.
    /// - parameter duration: The duration over which to perfom the specified segment of the animation.
    public func animate(
        to relativeTimestamp: Double,
        using curve: AnimationCurve = LinearAnimationCurve(),
        duration: TimeInterval? = nil
    ) {
        switch status {
        case .pending, .animating:
            break

        case .complete, .canceled:
            // If the animation is already complete, or was canceled, we can't animate it again.
            return
        }

        interactiveDriver.animate(to: relativeTimestamp, using: curve, duration: duration)
    }

}

// MARK: -

extension InteractiveAnimationInstance {

    /// Animate in reverse to the beginning of the animation.
    ///
    /// The `curve` is applied on top of the animation's curve.
    public func animateToBeginning(
        using curve: AnimationCurve = LinearAnimationCurve(),
        duration: TimeInterval? = nil
    ) {
        animate(to: 0, using: curve, duration: duration)
    }

    /// Animate forward to the end of the animation.
    ///
    /// The `curve` is applied on top of the animation's curve.
    public func animateToEnd(
        using curve: AnimationCurve = LinearAnimationCurve(),
        duration: TimeInterval? = nil
    ) {
        animate(to: 1, using: curve, duration: duration)
    }

}
