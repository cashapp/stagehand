//: [Previous](@previous)

import PlaygroundSupport

/*:

 # Creating a Basic Animation in Stagehand

 Constructing an animation begins by building an `Animation` - a value type that is generic over the type of element
 that will be animated. For our example, we'll be animating a `UIView`. Our `Animation` struct holds all of the
 information about what our animation will do.

 To get started, let's create an animation and set its duration to 2 seconds.

 */

import Stagehand

var basicAnimation = Animation<UIView>()

basicAnimation.implicitDuration = 2

/*:

 ## Using Keyframes

 The easiest way to add content to our animation is by adding keyframes. Keyframes let us interpolate properties between
 specified values over the course of the animation.

 */

// Start out at full opacity, then fade to 50% at the halfway point, then back to full opacity by the end.
basicAnimation.addKeyframe(for: \.alpha, at: 0.0, value: 1.0)
basicAnimation.addKeyframe(for: \.alpha, at: 0.5, value: 0.5)
basicAnimation.addKeyframe(for: \.alpha, at: 1.0, value: 1.0)

/*:

 We can add keyframes for as many properties as we want to our animation. The order we add the keyframes doesn't matter.

 */

// Start and end at the original size.
basicAnimation.addKeyframe(for: \.transform, at: 0.0, value: .identity)
basicAnimation.addKeyframe(for: \.transform, at: 1.0, value: .identity)

// At the midpoint, increase the scale by 10%.
basicAnimation.addKeyframe(for: \.transform, at: 0.5, value: .init(scaleX: 1.1, y: 1.1))

/*:

 Keyframes have a lot of power (read the [All About Keyframes](All%20About%20Keyframes) page to get a taste of what all
 they can do), but there are also other things our animation can control. Check out the
 [Executing Code During Animations](Executing%20Code%20During%20Animations) to find out more.

 */

/*:

 ## Executing Our Animation

 Now that we've constructed our animation, it's time to execute it on a view. Note that we haven't actually created our
 view yet! Stagehand allows for a separation of construction and execution, so we don't need to know what instance we'll
 be animating, only what the type will be.

 */

let view = UIView(frame: .init(x: 0, y: 0, width: 100, height: 100))
view.backgroundColor = .red
PlaygroundPage.current.liveView = WrapperView(wrappedView: view)

/*:

 Now that we have our view ready to go, we can execute the animation. The simplest way to do this is using the
 `perform(on:delay:completion:)` method.

 */

basicAnimation.perform(on: view)

/*:

 Read on to the [Advanced Execution of Animations](Advanced%20Execution%20of%20Animations) page to read more about the
 power of separating construction and execution.

 */

//: [Next](@next)
