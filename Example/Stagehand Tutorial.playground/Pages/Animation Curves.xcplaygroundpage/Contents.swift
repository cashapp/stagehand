//: [Previous](@previous)

import PlaygroundSupport
import Stagehand

/*:

 # Animation Curves

 One of the easiest ways to make an animation feel more polished is by adding an animation curve. Animation curves
 control the way that properties will be interpolated.

 For sake of example, let's build an animation with the default (linear) animation curve.

 */

var shakeAnimation = Animation<UIView>()

shakeAnimation.addKeyframe(for: \.transform, at: 0, value: .identity)
shakeAnimation.addKeyframe(for: \.transform, at: 0.25, value: .init(translationX: 40, y: 0))
shakeAnimation.addKeyframe(for: \.transform, at: 0.75, value: .init(translationX: -40, y: 0))
shakeAnimation.addKeyframe(for: \.transform, at: 1, value: .identity)

let view = UIView(frame: .init(x: 0, y: 0, width: 100, height: 100))
view.backgroundColor = .red
PlaygroundPage.current.liveView = WrapperView(wrappedView: view, outset: 50)

// This is the default value, but for the sake of explanation...
shakeAnimation.curve = LinearAnimationCurve()

let linearInstance = shakeAnimation.perform(on: view, delay: 1)

/*:

 Run the playground up to this point to see what the default animation looks like.

 It gets the point across, but feels very flat and mechanical. Let's add some life to our animation by setting the curve
 to an ease-in ease-out curve. This means that the animation will start out slowly (ease in), speed up in the middle,
 then slow down at the end (ease out).

 */

linearInstance.cancel()

shakeAnimation.curve = CubicBezierAnimationCurve.easeInEaseOut

shakeAnimation.perform(on: view, delay: 1)

/*:

 Run the playground up to this point to see the difference.

 With the simple addition of an animation curve, our animation now feels much more fluid. Check out the "Animation
 Curves" screen in the demo app to see what each of the provided curves looks like.

 */

/*:

 UIKit animations let you apply a curve to the whole animation. With the composibility Stagehand provides, you can apply
 different curves to different parts of an animation.

 */

var childAnimation = Animation<UIView>()

childAnimation.addKeyframe(for: \.transform, at: 0, value: .identity)
childAnimation.addKeyframe(for: \.transform, at: 1, value: .init(translationX: 200, y: 0))

var raceAnimation = Animation<RaceCarView>()

// Animate the top view using a linear curve.
raceAnimation.addChild(childAnimation, for: \.topView, startingAt: 0, relativeDuration: 1)

// Apply the same animation to the bottom view, but using an ease in curve.
childAnimation.curve = CubicBezierAnimationCurve.easeIn
raceAnimation.addChild(childAnimation, for: \.bottomView, startingAt: 0, relativeDuration: 1)

let raceCarView = RaceCarView(frame: .init(x: 0, y: 0, width: 300, height: 200))
PlaygroundPage.current.liveView = raceCarView

raceAnimation.perform(on: raceCarView, delay: 1)

/*:

 ## Creating Custom Animation Curves

 Stagehand comes with a variety of animation curves built in, including the commonly used Cubic Bézier curve (with
 support for two control points). If you need a specific animation curve for your use case, you can define a new curve
 by conforming to the `AnimationCurve` protocol.

 */

//: [Next](@next)
