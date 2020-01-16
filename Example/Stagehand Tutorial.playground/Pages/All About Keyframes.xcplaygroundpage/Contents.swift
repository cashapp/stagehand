//: [Previous](@previous)

import Stagehand

/*:

 ## Defining Keyframes

 Stagehands uses keyframes in the traditional sense of the term in the animation world. That is, a keyframe represents
 the value for a specific property at a specific point in time. For each frame in between the keyframes, the value for
 that property will be interpolated between the values defined by the keyframes. Frames before the first keyframe will
 use the value of that keyframe; likewise with frames after the last keyframe.

 Since our `Animation` is generic over the type of element we are animating, we can use the power of Swift key paths to
 animate any property that can be interpolated. One of the most common use cases for this is adding keyframes for
 properties of subviews on a custom `UIView` subclass.

 */

final class MySpecialView: UIView {

    let leftView: UIView = .init()

    let rightView: UIView = .init()

}

var fadeFromLeftToRightAnimation = Animation<MySpecialView>()

// Over the first half of the animation, fade out the left view.
fadeFromLeftToRightAnimation.addKeyframe(for: \.leftView.alpha, at: 0.0, value: 1)
fadeFromLeftToRightAnimation.addKeyframe(for: \.leftView.alpha, at: 0.5, value: 0)

// Over the second half of the animation, fade in the right view.
fadeFromLeftToRightAnimation.addKeyframe(for: \.rightView.alpha, at: 0.5, value: 0)
fadeFromLeftToRightAnimation.addKeyframe(for: \.rightView.alpha, at: 1.0, value: 1)

/*:

 We've now created an animation where the left view fades out (from an alpha of 1 to 0) over the first half of our
 animation. Since the last keyframe for the left view has a value of `0`, the alpha will remain there through the rest
 of the animation. Since the first keyframe for the right view has a value of `0`, it will start there. Then over the
 second half of the animation it will fade in.

 With only two subviews, this is easy to read - but what happens when we start adding in more subviews? Or more
 properties to animate? Check out the [Composing Animations](Composing%20Animations) page to see how we can make
 multi-part animations like this one easier to reason about.

 */

/*:

 ## Making Keyframes Relative to the Initial Value

 So far we've seen keyframes define fixed values at each timestamp. Sometimes, to make our animations more reusable, we
 need to define the keyframes relative to the value of the property at the beginning of the animation. To do this, we
 can use relative keyframes, which take a closure that transforms the initial value of the property into the value for
 the property at that keyframe.

 */

var rotateAnimation = Animation<UIView>()

// Rotate the view 90 degrees from its current position.
rotateAnimation.addKeyframe(for: \.transform, at: 0, relativeValue: { $0 })
rotateAnimation.addKeyframe(for: \.transform, at: 1, relativeValue: { $0.rotated(by: .pi / 4) })

/*:

 Keyframes with static and relative values can be mixed together, even for the same property.

 A common use case for this is having a property start the animation at its current value, before being animated to a
 new (fixed) value.

 */

var fadeOutAnimation = Animation<UIView>()

// Fade the view from its current alpha down to 0.
fadeOutAnimation.addKeyframe(for: \.alpha, at: 0, relativeValue: { $0 })
fadeOutAnimation.addKeyframe(for: \.alpha, at: 1, value: 0)

/*:

 ## Animating Different Types of Properties

 Stagehand ships with support for animating properties of a variety of common types. This includes floating point types,
 many of the CoreGraphics geometric types (`CGPoint`, `CGSize`, etc.), colors, etc. These aren't the only types you can
 add keyframes for, however - check out the [Animating Custom Properties](Animating%20Custom%20Properties) page for more
 on how to support animating properties of custom types.

 */

//: [Next](@next)
