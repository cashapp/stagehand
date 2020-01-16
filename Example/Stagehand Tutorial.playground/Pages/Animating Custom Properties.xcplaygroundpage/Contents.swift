//: [Previous](@previous)

/*:

 # Animating Custom Properties

 Stagehand comes with the ability to animate a wide variety of common property types out of the box. Any property of one
 of these types can be animated using keyframes. Sometimes we need to animate custom types though.

 As an example, let's define a `Border` value type that wraps the border-related properties of a view:

 */

import UIKit

struct Border {

    var width: CGFloat

    var color: UIColor?

    static let none: Border = .init(width: 0, color: nil)

}

extension UIView {

    var border: Border {
        get {
            return .init(
                width: layer.borderWidth,
                color: layer.borderColor.map(UIColor.init)
            )
        }
        set {
            layer.borderWidth = newValue.width
            layer.borderColor = newValue.color?.cgColor
        }
    }

}

/*:

 In its current form, we can't add keyframes for the `\UIView.border` property, since we don't know how to interpolate
 the values. Fortunately, all we need to do is make `Border` conform to the `AnimatableProperty` protocol. This
 conformance tells Stagehand how to interpolate between two values of the given type.

 Since our `Border` type is made up of properties that we do know how to animate, we can simply create a new `Border`
 value with each of the properties interpolated.

 */

import Stagehand

extension Border: AnimatableProperty {

    static func value(between initialValue: Border, and finalValue: Border, at progress: Double) -> Border {
        return .init(
            width: CGFloat.value(between: initialValue.width, and: finalValue.width, at: progress),
            color: UIColor.optionalValue(between: initialValue.color, and: finalValue.color, at: progress)
        )
    }

}

/*:

 Now that we know how to interpolate our `Border` type, we can add it to an animation.

 */

var animation = Animation<UIView>()

animation.addKeyframe(for: \.border, at: 0, relativeValue: { $0 })
animation.addKeyframe(for: \.border, at: 1, value: .none)

/*:

 ## Interpolating Optional Values

 This works great when our property is non-optional. But what happens when the value could be `nil`? The expected
 behavior isn't always obvious, so Stagehand disables this by default. If you want to animate optional values, you can
 enable this by conforming to the `AnimatableOptionalProperty` protocol.

 As an example, let's add the ability to animate between two different `Border?` values. What's between a `nil` border
 and a non-`nil` border? When we get a `nil` initial or final value, we will treat it as a zero-width border that is the
 same color as the other value. This will enable us to animate in/out our border where only the width changes.

 */

extension Border: AnimatableOptionalProperty {

    static func optionalValue(between initialValue: Border?, and finalValue: Border?, at progress: Double) -> Border? {
        guard progress > 0 else {
            return initialValue
        }

        guard progress < 1 else {
            return finalValue
        }

        switch (initialValue, finalValue) {
        case (nil, nil):
            return nil

        case let (.some(initialValue), .some(finalValue)):
            return Border.value(between: initialValue, and: finalValue, at: progress)

        case let (nil, .some(finalValue)):
            return Border.value(
                between: .init(width: 0, color: finalValue.color),
                and: finalValue,
                at: progress
            )

        case let (.some(initialValue), nil):
            return Border.value(
                between: initialValue,
                and: .init(width: 0, color: initialValue.color),
                at: progress
            )
        }
    }

}

//: [Next](@next)
