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

import UIKit

/// An `Animation` is the core data structure that defines an animation that can be applied to any elements of a
/// specific type (`ElementType`). Animations consist of a series of keyframes, property assignments, and execution
/// blocks.
///
/// Most simple animations can be made using keyframes. Keyframes defines the value of a given property at a specific
/// point in the animation. During the animation, the value of each property is interpolated between the values in the
/// animation's keyframes.
///
/// Property assignments also specify the value of a given property at a specific point in the animation, but do not
/// interpolate the value between these points. Property assignments can be used for values that cannot be interpolated,
/// or should change in discrete assignments, rather than continuosly over the course of the animation.
///
/// Execution blocks enable code to be executed at a specific point in the animation. Execution blocks are similar to
/// property assignments in that they enable discrete changes, except in a slightly more free-form manner. For even less
/// structured changes, per-frame execution blocks can be added to be executed every time the animation renders a frame.
///
/// Animations are composable. Complex animations can be composed of smaller logical pieces by constructing a hierarchy
/// of child animations.
public struct Animation<ElementType: AnyObject> {

    // MARK: - Public Types

    public struct FrameContext {

        /// The element being animated.
        public let element: ElementType

        /// Value in the range [0, 1] representing the uncurved progress of the animation.
        public let uncurvedProgress: Double

        /// Value representing the progress into the animation, adjusted based on the animation's curve.
        public let progress: Double

    }

    public typealias PerFrameExecutionBlock = (FrameContext) -> Void

    // MARK: - Life Cycle

    public init() { }

    // MARK: - Public Properties

    /// The duration of the animation.
    ///
    /// More specifically, this is the duration of one cycle of the animation. An animation that repeats will take a
    /// total duration equal to the duration of one cycle (the animation's `implicitDuration`) multiplied by the number
    /// of cycles (as specified by the animation's `implicitRepeatStyle`).
    ///
    /// When animations are composed, the duration is controlled by the top-most parent animation. This means that the
    /// `implicitDuration` of any child animations are ignored.
    public var implicitDuration: TimeInterval = 1

    /// The way in which the animation should repeat.
    ///
    /// When animations are composed, the repeat style is controlled by the top-most parent animation. This means that
    /// the `implicitRepeatStyle` of any child animations are ignored.
    public var implicitRepeatStyle: AnimationRepeatStyle = .noRepeat

    /// The curve applied to the animation.
    ///
    /// Curves in child animations are applied on top of the curve already applied by their parent. This allows each
    /// child animation to have a different animation curve.
    public var curve: AnimationCurve = LinearAnimationCurve()

    // MARK: - Internal Computed Properties

    internal var propertiesWithKeyframes: Set<PartialKeyPath<ElementType>> {
        var properties = Set(keyframeSeriesByProperty.keys)

        for child in children {
            properties.formUnion(child.animation.propertiesWithKeyframes)
        }

        return properties
    }

    /// The relative timestamps corresponding to keyframes in the animation, without any curves applied.
    internal var keyframeRelativeTimestamps: [Double] {
        var keyframeRelativeTimestamps = Set(keyframeSeriesByProperty.flatMap { $0.value.keyframeRelativeTimestamps })

        for child in children {
            // The relative timestamps of child keyframes are relative to the child animation and are uncurved.
            let childKeyframeRelativeTimestamps = child.animation.keyframeRelativeTimestamps

            let adjustedRelativeTimestamps: [Double] = childKeyframeRelativeTimestamps
                .flatMap { childRelativeTimestamp -> [Double] in
                    /// Convert the timestamp to be relative to the curved progress of this animation by adjusting the
                    /// range to the start timestamp and duration of the child.
                    let timestampInParent = child.relativeStartTimestamp + childRelativeTimestamp * child.relativeDuration

                    /// Convert the timestamp to be relative to the uncurved progress of this animation.
                    return curve.rawProgress(for: timestampInParent)
                }
            keyframeRelativeTimestamps.formUnion(Set(adjustedRelativeTimestamps))
        }

        return keyframeRelativeTimestamps.sorted()
    }

    // MARK: - Internal Properties

    internal var keyframeSeriesByProperty: [PartialKeyPath<ElementType>: AnyKeyframeSeries] = [:]

    internal private(set) var assignments: [Assignment] = []

    internal private(set) var executionBlocks: [ExecutionBlock] = []

    internal private(set) var perFrameExecutionBlocks: [PerFrameExecutionBlock] = []

    internal var children: [ChildAnimation] = []

    // MARK: - Public Methods - Construction

    /// Add a keyframe for the given `property` with a fixed value.
    ///
    /// - parameter property: The key path for the property to be animated.
    /// - parameter relativeTimestamp: The relative timestamp at which this should be the value of the property. Must
    /// be in the range [0,1], where 0 is the beginning of the animation and 1 is the end.
    /// - parameter value: The value of the property at this keyframe.
    public mutating func addKeyframe<PropertyType: AnimatableProperty>(
        for property: WritableKeyPath<ElementType, PropertyType>,
        at relativeTimestamp: Double,
        value: PropertyType
    ) {
        addKeyframe(for: property, at: relativeTimestamp, relativeValue: { _ in value })
    }

    /// Add a keyframe for the given `property` with a fixed value.
    ///
    /// - parameter property: The key path for the property to be animated.
    /// - parameter relativeTimestamp: The relative timestamp at which this should be the value of the property. Must
    /// be in the range [0,1], where 0 is the beginning of the animation and 1 is the end.
    /// - parameter value: The value of the property at this keyframe.
    public mutating func addKeyframe<PropertyType: AnimatableOptionalProperty>(
        for property: WritableKeyPath<ElementType, PropertyType?>,
        at relativeTimestamp: Double,
        value: PropertyType
    ) {
        // This method shouldn't be necessary to define, since the property type is really `Optional`. Unfortunately,
        // Swift sometimes has trouble resolving inferred key paths (i.e. key paths that don't specify the class name)
        // for optional property types with a non-optional value. This makes inferred key paths work in this situation,
        // since this method will be preferred.

        addKeyframe(for: property, at: relativeTimestamp, relativeValue: { _ in value })
    }

    /// Add a keyframe for the given `property` with a value relative to the property's value at the beginning of the
    /// animation.
    ///
    /// - parameter property: The key path for the property to be animated.
    /// - parameter relativeTimestamp: The relative timestamp at which this should be the value of the property. Must
    /// be in the range [0,1], where 0 is the beginning of the animation and 1 is the end.
    /// - parameter relativeValue: The value of the property at this keyframe, determined from the `initialValue` of the
    /// property when the animation begins.
    public mutating func addKeyframe<PropertyType: AnimatableProperty>(
        for property: WritableKeyPath<ElementType, PropertyType>,
        at relativeTimestamp: Double,
        relativeValue: @escaping (_ initialValue: PropertyType) -> PropertyType
    ) {
        if var keyframeSeries = keyframeSeriesByProperty[property] as? KeyframeSeries<PropertyType> {
            keyframeSeries.valuesByRelativeTimestamp[relativeTimestamp] = relativeValue
            keyframeSeriesByProperty[property] = keyframeSeries

        } else {
            let keyframeSeries = KeyframeSeries(
                property: property,
                valuesByRelativeTimestamp: [
                    relativeTimestamp: relativeValue
                ]
            )
            keyframeSeriesByProperty[property] = keyframeSeries
        }
    }

    /// Add an assignment for the given `property` at the `relativeTimestamp`.
    ///
    /// When the animation is run in reverse, the property will be returned to its value prior to the assignment.
    ///
    /// The behavior of property assignments is undefined when used with an animation curve that overshoots (i.e.
    /// provides a value outside of the range [0,1]).
    ///
    /// - parameter property: The key path for the property to be assigned.
    /// - parameter relativeTimestamp: The relative timestamp at which this should be the value of the property, based
    /// on the curved progress of the animation. Must be in the range [0,1], where 0 is the beginning of the animation
    /// and 1 is the end.
    /// - parameter value: The value to assign to the property.
    public mutating func addAssignment<PropertyType>(
        for property: WritableKeyPath<ElementType, PropertyType>,
        at relativeTimestamp: Double,
        value: PropertyType
    ) {
        assignments.append(.init(
            relativeTimestamp: relativeTimestamp,
            assignBlock: { element in
                var element = element
                element[keyPath: property] = value
            },
            generateReverseAssignBlock: { element in
                let originalValue = element[keyPath: property]
                return { element in
                    var element = element
                    element[keyPath: property] = originalValue
                }
            }
        ))
    }

    /// Add an execution block at the given `relativeTimestamp`.
    ///
    /// This method takes two closures to execute at the given timestamp, one to be executed when the animation is
    /// run in the forward direction and another to be executed when the animation is run in reverse.
    ///
    /// If an animation autoreverses, an execution block at the boundary of a cycle (i.e. having a `relativeTimestamp`
    /// of either `0` or `1`) will be executed once in the direction of that cycle, then again in the direction of the
    /// next cycle, unless it is the final cycle.
    ///
    /// If an animation loops, but does not autoreverse, between cycles each execution block will be executed in reverse
    /// order. This allows execution blocks to be treated as discrete units where the `reverseBlock` is the opposite of
    /// the `forwardBlock`, in effect reverting the changes made by the `forwardBlock`. The default value of
    /// `reverseBlock` is a no-op closure, as a convenience for defining execution blocks for animations that are only
    /// intended to run in the forward direction, or for which the action taken in the `forwardBlock` does not need to
    /// be reverted (e.g. playing a sound or triggering a haptic).
    ///
    /// When an animation is cancelled, the execution blocks will be executed such that each cycle will be completed in
    /// full. This allows execution blocks to depend on the effects of prior execution blocks. If you have an execution
    /// block that should _not_ execute when cancelling (e.g. if it has side effects outside the animation), you can
    /// check the `status` of the animation instance in the block.
    ///
    /// The behavior of execution blocks is undefined when used with an animation curve that overshoots (i.e. provides a
    /// value outside of the range [0,1]).
    ///
    /// - parameter forwardBlock: The closure to execute when the animation is run in the forward direction.
    /// - parameter reverseBlock: The closure to execute when the animation is run in the reverse direction.
    /// - parameter relativeTimestamp: The relative timestamp at which this should be the value of the property, based
    /// on the curved progress of the animation. Must be in the range [0,1], where 0 is the beginning of the animation
    /// and 1 is the end.
    public mutating func addExecution(
        onForward forwardBlock: @escaping (ElementType) -> Void,
        onReverse reverseBlock: @escaping (ElementType) -> Void = { _ in },
        at relativeTimestamp: Double
    ) {
        executionBlocks.append(.init(
            relativeTimestamp: relativeTimestamp,
            forwardBlock: forwardBlock,
            reverseBlock: reverseBlock
        ))
    }

    /// Add an execution block that will be called during each frame of the animation.
    ///
    /// The per-frame execution blocks will executed after the keyframes, property assignments, and other execution
    /// blocks for the given frame have been applied.
    ///
    /// - parameter block: The block to call during each frame of the animation.
    public mutating func addPerFrameExecution(
        _ block: @escaping PerFrameExecutionBlock
    ) {
        perFrameExecutionBlocks.append(block)
    }

    /// Add a child animation.
    ///
    /// The `childAnimation`'s `implicitDuration` and `implicitRepeatStyle` will be ignored.
    ///
    /// Keyframes in a child animation for the same property as keyframes in the parent will be overridden by the values
    /// of the keyframes in the parent.
    ///
    /// - parameter childAnimation: The child animation to be performed on the `subelement`.
    /// - parameter subelement: The key path for the subelement on which the child animation should be performed.
    /// - parameter relativeStartTimestamp: The relative timestamp at which the animation should begin.  Must be in the
    ///  range [0,1), where 0 is the beginning of the animation and 1 is the end.
    /// - parameter relativeDuration: The relative duration over which the child animation should be performed. Must be
    /// in the range (0,(1 - relativeStartTimestamp)], where 0 is the beginning of the animation and 1 is the end.
    public mutating func addChild<SubelementType: AnyObject>(
        _ childAnimation: Animation<SubelementType>,
        for subelement: KeyPath<ElementType, SubelementType>,
        startingAt relativeStartTimestamp: Double,
        relativeDuration: Double
    ) {
        var child = ChildAnimation(
            animation: .init(),
            relativeStartTimestamp: relativeStartTimestamp,
            relativeDuration: relativeDuration
        )

        child.animation.curve = childAnimation.curve

        // Map the child's keyframes into the child animation.
        for (_, childKeyframeSeries) in childAnimation.keyframeSeriesByProperty {
            let (property, keyframeSeries) = childKeyframeSeries.mapForParentElement(subelement)

            child.animation.keyframeSeriesByProperty[property] = keyframeSeries
        }

        // Map the child's property assignments into the child animation.
        child.animation.assignments = childAnimation.assignments.map { childAssignment in
            return Assignment(
                relativeTimestamp: childAssignment.relativeTimestamp,
                assignBlock: { element in
                    childAssignment.assignBlock(element[keyPath: subelement])
                },
                generateReverseAssignBlock: { element in
                    let subelementAssignBlock = childAssignment.generateReverseAssignBlock(element[keyPath: subelement])
                    return { element in
                        subelementAssignBlock(element[keyPath: subelement])
                    }
                }
            )
        }

        // Map the child's execution blocks into the child animation.
        child.animation.executionBlocks = childAnimation.executionBlocks.map { childExecutionBlock in
            return ExecutionBlock(
                relativeTimestamp: childExecutionBlock.relativeTimestamp,
                forwardBlock: { element in
                    childExecutionBlock.forwardBlock(element[keyPath: subelement])
                },
                reverseBlock: { element in
                    childExecutionBlock.reverseBlock(element[keyPath: subelement])
                }
            )
        }

        // Collapse per-frame execution blocks from the child into the parent.
        perFrameExecutionBlocks.append(
            contentsOf: childAnimation.perFrameExecutionBlocks.map { childExecutionBlock in
                return { context in
                    guard context.progress >= relativeStartTimestamp else {
                        // The child animation hasn't started yet.
                        return
                    }

                    guard context.progress <= (relativeStartTimestamp + relativeDuration) else {
                        // The child animation already ended.
                        return
                    }

                    // The uncurved progress of the child animation is based on the curved progress of the parent.
                    let uncurvedProgress = (context.progress - relativeStartTimestamp) / relativeDuration

                    childExecutionBlock(
                        .init(
                            element: context.element[keyPath: subelement],
                            uncurvedProgress: uncurvedProgress,
                            progress: childAnimation.curve.adjustedProgress(for: uncurvedProgress)
                        )
                    )
                }
            }
        )

        // Integrate the grandchildren.
        for grandchild in childAnimation.children {
            child.animation.addChild(
                grandchild.animation,
                for: subelement,
                startingAt: grandchild.relativeStartTimestamp,
                relativeDuration: grandchild.relativeDuration
            )
        }

        children.append(child)
    }

    // MARK: - Public Methods - Execution

    /// Perform the animation on the given `element`.
    ///
    /// The duration for each cycle of the animation will be determined in order of preference by:
    /// 1. An explicit duration, if provided via the `duration` parameter
    /// 2. The animation's implicit duration, as specified by the `implicitDuration` property
    ///
    /// The repeat style for the animation will be determined in order of preference by:
    /// 1. An explicit repeat style, if provided via the `repeatStyle` parameter
    /// 2. The animation's implicit repeat style, as specified by the `implicitRepeatStyle` property
    ///
    /// - parameter element: The element to be animated.
    /// - parameter delay: The time interval to wait before performing the animation.
    /// - parameter duration: The duration to use for each cycle the animation.
    /// - parameter repeatStyle: The repeat style to use for the animation.
    /// - parameter completion: The completion block to call when the animation has concluded, with a parameter
    /// indicated whether the animation completed (as opposed to being cancelled).
    /// - returns: An animation instance that can be used to check the status of or cancel the animation.
    @discardableResult
    public func perform(
        on element: ElementType,
        delay: TimeInterval = 0,
        duration: TimeInterval? = nil,
        repeatStyle: AnimationRepeatStyle? = nil,
        completion: ((_ finished: Bool) -> Void)? = nil
    ) -> AnimationInstance {
        let driver = DisplayLinkDriver(
            delay: delay,
            duration: duration ?? implicitDuration,
            repeatStyle: repeatStyle ?? implicitRepeatStyle,
            completion: completion
        )

        let instance = AnimationInstance(
            animation: self,
            element: element,
            driver: driver
        )

        driver.start()

        return instance
    }

    // MARK: - Internal Methods

    /// Applies the animatable properties (those defined by keyframes, including collection keyframes) to the `element`
    /// at the given `relativeTimestamp`.
    ///
    /// - parameter element: The element being animated.
    /// - parameter relativeTimestamp: The raw (non-curved) timestamp at which to apply the values.
    /// - parameter initialValues: A dictionary mapping the property animated by each keyframe series to the value of
    /// that property when the animation began.
    internal func apply(
        to element: inout ElementType,
        at relativeTimestamp: Double,
        initialValues: [PartialKeyPath<ElementType>: Any]
    ) {
        let adjustedRelativeTimestamp = curve.adjustedProgress(for: relativeTimestamp)

        for child in children {
            // Allow for the child to be rendered _slightly_ outside its applied timestamp range to account for rounding
            // error when applying a timestamp corresponding to a keyframe.
            let ε = 0.0000000001

            guard adjustedRelativeTimestamp >= child.relativeStartTimestamp - ε else {
                continue
            }

            guard adjustedRelativeTimestamp <= (child.relativeStartTimestamp + child.relativeDuration) + ε else {
                continue
            }

            child.animation.apply(
                to: &element,
                at: (adjustedRelativeTimestamp - child.relativeStartTimestamp) / child.relativeDuration,
                initialValues: initialValues
            )
        }

        var element = element as AnyObject

        for series in self.keyframeSeriesByProperty {
            series.value.applyToElement(
                &element,
                at: adjustedRelativeTimestamp,
                initialValue: initialValues[series.key]!
            )
        }
    }

    /// Applies the first value of each animatable property (those defined by keyframes, _not_ including collection
    /// keyframes) to the `element`.
    ///
    /// - parameter element: The element being animated.
    /// - parameter initialValues: A dictionary mapping the property animated by each keyframe series to the value of
    /// that property when the animation began.
    internal func applyInitialKeyframes(
        to element: inout ElementType,
        initialValues: [PartialKeyPath<ElementType>: Any]
    ) {
        var element = element as AnyObject

        for property in propertiesWithKeyframes {
            let keyframeSeries = self.keyframeSeries(for: property)!.0
            keyframeSeries.applyToElement(&element, at: 0, initialValue: initialValues[property]!)
        }
    }

    // MARK: - Private Methods

    private func keyframeSeries(for property: PartialKeyPath<ElementType>) -> (AnyKeyframeSeries, startingAt: Double)? {
        if let keyframeSeries = keyframeSeriesByProperty[property] {
            return (keyframeSeries, startingAt: 0)
        }

        var earliestKeyframeSeries: (AnyKeyframeSeries, Double)?
        for child in children.sorted(by: { $0.relativeStartTimestamp < $1.relativeStartTimestamp }) {
            if let candidateKeyframeSeries = child.animation.keyframeSeries(for: property) {
                let adjustedStartTimestamp = child.relativeStartTimestamp + candidateKeyframeSeries.startingAt * child.relativeDuration

                if earliestKeyframeSeries == nil {
                    earliestKeyframeSeries = candidateKeyframeSeries
                } else if let existingKeyframeSeries = earliestKeyframeSeries, adjustedStartTimestamp <= existingKeyframeSeries.1 {
                    earliestKeyframeSeries = candidateKeyframeSeries
                }
            }
        }

        return earliestKeyframeSeries
    }

}

// MARK: -

public enum AnimationRepeatStyle: Equatable {

    /// Animation will execute `count` times.
    ///
    /// - `count`: The number of times the animation will be executed. A count of `0` represents an animation that
    /// repeats indefinitely (until canceled). A count of `1` will run the animation a single time from start to end.
    /// - `autoreversing`: Whether or not the animation should alternative direction on each execution. The first
    /// execution will always run in the forwards direction, optionally alternating begining on the second run.
    case repeating(count: UInt, autoreversing: Bool)

    /// Animation will execute once.
    public static let noRepeat: AnimationRepeatStyle = .repeating(count: 1, autoreversing: false)

    /// Animation will execute indefinitely (until canceled).
    /// - parameter autoreversing: Whether or not the animation should alternative direction on each cycle. The first
    /// cycle will always run in the forwards direction, optionally alternating begining on the second cycle.
    public static func infinitelyRepeating(autoreversing: Bool) -> AnimationRepeatStyle {
        return .repeating(count: 0, autoreversing: autoreversing)
    }

}

// MARK: -

extension Animation {

    private struct KeyframeSeries<PropertyType: AnimatableProperty>: AnyKeyframeSeries {

        // MARK: - Public Properties

        var property: WritableKeyPath<ElementType, PropertyType>

        var valuesByRelativeTimestamp: [Double: (PropertyType) -> PropertyType]

        // MARK: - Public Methods

        func apply(to element: inout ElementType, at relativeTimestamp: Double, initialValue: PropertyType) {
            if let value = valuesByRelativeTimestamp[relativeTimestamp] {
                element[keyPath: property] = value(initialValue)
            } else {
                let values = valuesByRelativeTimestamp.sorted { $0.key < $1.key }

                guard let previousIndex = values.lastIndex(where: { $0.key < relativeTimestamp }) else {
                    element[keyPath: property] = values.first!.value(initialValue)
                    return
                }

                let (previousTimestamp, previousValue) = values[previousIndex]

                let nextIndex = values.index(after: previousIndex)
                guard nextIndex != values.endIndex else {
                    element[keyPath: property] = previousValue(initialValue)
                    return
                }

                let (nextTimestamp, nextValue) = values[nextIndex]

                element[keyPath: property] = PropertyType.value(
                    between: previousValue(initialValue),
                    and: nextValue(initialValue),
                    at: ((relativeTimestamp - previousTimestamp) / (nextTimestamp - previousTimestamp))
                )
            }
        }

        func mapForParent<ParentElementType: AnyObject>(
            _ subelementPath: KeyPath<ParentElementType, ElementType>
        ) -> (PartialKeyPath<ParentElementType>, Animation<ParentElementType>.KeyframeSeries<PropertyType>) {
            // This is not a type-safe cast because `appending(path:)` doesn't know that the `ParentElementType` is a
            // reference type. Given the `AnyObject` restriction, it should be safe to assume that we will always get
            // back a `ReferenceWritableKeyPath` since we're appending a writable key path to a key path for a reference
            // type.
            let mappedProperty = subelementPath.appending(path: property) as! ReferenceWritableKeyPath<ParentElementType, PropertyType>

            return (mappedProperty, .init(
                property: mappedProperty,
                valuesByRelativeTimestamp: valuesByRelativeTimestamp
            ))
        }

        // MARK: - AnyKeyframeSeries

        var propertyPath: AnyKeyPath {
            return property
        }

        var keyframeRelativeTimestamps: [Double] {
            return valuesByRelativeTimestamp.keys.sorted()
        }

        func applyToElement(_ element: inout AnyObject, at relativeTimestamp: Double, initialValue: Any) {
            var element = element as! ElementType
            apply(to: &element, at: relativeTimestamp, initialValue: initialValue as! PropertyType)
        }

        func mapForParentElement<ParentElementType: AnyObject>(
            _ subelementPath: PartialKeyPath<ParentElementType>
        ) -> (PartialKeyPath<ParentElementType>, AnyKeyframeSeries) {
            let (keyPath, keyframeSeries) = mapForParent(
                subelementPath as! KeyPath<ParentElementType, ElementType>
            )
            return (keyPath, keyframeSeries)
        }

    }

}

internal protocol AnyKeyframeSeries {

    var propertyPath: AnyKeyPath { get }

    var keyframeRelativeTimestamps: [Double] { get }

    func applyToElement(_ element: inout AnyObject, at relativeTimestamp: Double, initialValue: Any)

    func mapForParentElement<ParentElementType: AnyObject>(
        _ subelementPath: PartialKeyPath<ParentElementType>
    ) -> (PartialKeyPath<ParentElementType>, AnyKeyframeSeries)

}

// MARK: -

extension Animation {

    internal struct Assignment {

        var relativeTimestamp: Double

        var assignBlock: (ElementType) -> Void

        var generateReverseAssignBlock: (ElementType) -> ((ElementType) -> Void)

    }

}

// MARK: -

extension Animation {

    internal struct ExecutionBlock {

        var relativeTimestamp: Double

        var forwardBlock: (ElementType) -> Void

        var reverseBlock: (ElementType) -> Void

    }

}

// MARK: -

extension Animation {

    internal struct ChildAnimation {

        /// The base animation of the child.
        ///
        /// This animation is stripped of any execution blocks, per frame execution blocks, and property assignments.
        /// When the child is added, these are removed and collapsed into the parent. The child's animation is used
        /// only to store the keyframe series associated with it, since collapsing these into the parent would lose
        /// any animation curve applied to the child.
        ///
        /// This animation's `implicitDuration` and `implicitRepeatStyle` can be ignored.
        var animation: Animation<ElementType>

        var relativeStartTimestamp: Double

        var relativeDuration: Double

    }

}

