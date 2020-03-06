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

/// An `AnimationGroup` is a container for a series of animations that allows them to be executed as a single unit.
///
/// Animation groups break the concept of separating construction and execution, since the element that the animation
/// will be performed on must be known when the group is constructed. They make it possible, however, to animate
/// elements in cases where each of the elements in the group cannot be accessed via key paths from a single shared
/// parent element.
///
/// Unlike normal animations, animation groups hold a strong reference to each of the elements they animate. This means
/// that the animation group must be cancelled manually when all other strong references to the elements are removed if
/// the elements should be deallocated.
public struct AnimationGroup {

    // MARK: - Life Cycle

    public init() { }

    // MARK: - Public Properties

    /// The duration of the animation group.
    public var duration: TimeInterval {
        get {
            return animation.duration
        }
        set {
            animation.duration = newValue
        }
    }

    /// The way in which the animation group should repeat.
    public var repeatStyle: AnimationRepeatStyle {
        get {
            return animation.repeatStyle
        }
        set {
            animation.repeatStyle = newValue
        }
    }

    /// The curve applied to the animation group.
    public var curve: AnimationCurve {
        get {
            return animation.curve
        }
        set {
            animation.curve = newValue
        }
    }

    // MARK: - Internal Properties

    internal private(set) var animation: Animation<ElementContainer> = .init()

    internal let elementContainer: ElementContainer = .init()

    // MARK: - Private Properties

    private var completions: [(Bool) -> Void] = []

    // MARK: - Public Methods

    /// Add an animation to the group.
    ///
    /// The `elementAnimation`'s `duration` and `repeatStyle` will be ignored.
    ///
    /// - parameter elementAnimation: The animation to be performed on the `element`.
    /// - parameter element: The element to be animated.
    /// - parameter relativeStartTimestamp: The relative timestamp at which the animation should begin.  Must be in the
    ///  range [0,1), where 0 is the beginning of the animation and 1 is the end.
    /// - parameter relativeDuration: The relative duration over which the child animation should be performed. Must be
    /// in the range (0,(1 - relativeStartTimestamp)], where 0 is the beginning of the animation and 1 is the end.
    public mutating func addAnimation<ElementType: AnyObject>(
        _ elementAnimation: Animation<ElementType>,
        for element: ElementType,
        startingAt relativeStartTimestamp: Double,
        relativeDuration: Double
    ) {
        let elementIndex = elementContainer.addElement(element)

        animation.addChild(
            elementAnimation,
            for: \ElementContainer.[elementIndex],
            startingAt: relativeStartTimestamp,
            relativeDuration: relativeDuration
        )
    }

    /// Add a completion handler to be called when the animation completes.
    public mutating func addCompletionHandler(
        _ completion: @escaping (_ finished: Bool) -> Void
    ) {
        completions.append(completion)
    }

    /// Perform the animations in the group.
    ///
    /// - parameter delay: The time interval to wait before performing the animation.
    /// - parameter completion: The completion block to call when the animation has concluded, with a parameter
    /// indicated whether the animation completed (as opposed to being cancelled).
    @discardableResult
    public func perform(
        delay: TimeInterval = 0,
        completion groupCompletion: ((_ finished: Bool) -> Void)? = nil
    ) -> AnimationInstance {
        return animation.perform(
            on: elementContainer,
            delay: delay,
            completion: { finished in
                self.completions.forEach { $0(finished) }
                groupCompletion?(finished)
            }
        )
    }

}

// MARK: -

extension AnimationGroup {

    internal final class ElementContainer {

        // MARK: - Private Accessors

        fileprivate subscript<ElementType: AnyObject>(index: Int) -> ElementType {
            get {
                return elements[index] as! ElementType
            }
            set {
                elements[index] = newValue
            }
        }

        // MARK: - Private Methods

        fileprivate func addElement(_ element: AnyObject) -> Int {
            let nextIndex = elements.endIndex
            elements.append(element)
            return nextIndex
        }

        // MARK: - Private Properties

        private var elements: [AnyObject] = []

    }

}
