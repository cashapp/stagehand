//: [Previous](@previous)

import PlaygroundSupport
import Stagehand

/*:

 # Composing Animations

 One of the most powerful concepts that Stagehand introduces is the ability to compose animations. Small animations
 (such as those that affect only a few properties of a single view) are easy to reason about as a whole, but complex
 multi-part animations can be much more difficult.

 Stagehand allows for building a hierarchy of smaller animations that can be easily reasoned about, and composing them
 into a large animation that is executed as a single unit. This hierarchy is built up by adding child animations.

 For example, say we have a view with two subviews, each of which has a series of animations going on.

 */

func makeFlatAnimation() -> Animation<RaceCarView> {
    var animation = Animation<RaceCarView>()

    animation.addKeyframe(for: \.topView.transform, at: 0, value: .identity)
    animation.addKeyframe(for: \.topView.transform, at: 1, value: .init(translationX: 200, y: 0))

    animation.addKeyframe(for: \.topView.backgroundColor, at: 0, value: .red)
    animation.addKeyframe(for: \.topView.backgroundColor, at: 0.25, value: UIColor.red.withAlphaComponent(0.8))
    animation.addKeyframe(for: \.topView.backgroundColor, at: 0.5, value: .red)
    animation.addKeyframe(for: \.topView.backgroundColor, at: 0.75, value: UIColor.red.withAlphaComponent(0.8))
    animation.addKeyframe(for: \.topView.backgroundColor, at: 1, value: .red)

    animation.addKeyframe(for: \.bottomView.transform, at: 0, value: .identity)
    animation.addKeyframe(for: \.bottomView.transform, at: 1, value: .init(translationX: 200, y: 0))

    animation.addKeyframe(for: \.bottomView.backgroundColor, at: 0, value: .yellow)
    animation.addKeyframe(for: \.bottomView.backgroundColor, at: 0.25, value: UIColor.yellow.withAlphaComponent(0.8))
    animation.addKeyframe(for: \.bottomView.backgroundColor, at: 0.5, value: .yellow)
    animation.addKeyframe(for: \.bottomView.backgroundColor, at: 0.75, value: UIColor.yellow.withAlphaComponent(0.8))
    animation.addKeyframe(for: \.bottomView.backgroundColor, at: 1, value: .yellow)

    animation.duration = 3

    return animation
}

let raceCarView = RaceCarView(frame: .init(x: 0, y: 0, width: 300, height: 200))
PlaygroundPage.current.liveView = raceCarView

let flatInstance = makeFlatAnimation().perform(on: raceCarView)

/*:

 Run the playground up to this point to see our animation in action.

 */

flatInstance.cancel()

/*:

 Now let's write the same animation, except using the `addChild(_:)` method to compose our animation for separate
 animations for each subview.

 First, we'll make the animation for a single subview. In order to accomodate the differences in background color, we'll
 use relative keyframes. Using concepts like relative keyframes helps to make our animations more reusable in general.

 */

func makeCarAnimation() -> Animation<UIView> {
    var animation = Animation<UIView>()

    animation.addKeyframe(for: \.transform, at: 0, value: .identity)
    animation.addKeyframe(for: \.transform, at: 1, value: .init(translationX: 200, y: 0))

    animation.addKeyframe(for: \.backgroundColor, at: 0, relativeValue: { $0 })
    animation.addKeyframe(for: \.backgroundColor, at: 0.25, relativeValue: { $0?.withAlphaComponent(0.8) })
    animation.addKeyframe(for: \.backgroundColor, at: 0.5, relativeValue: { $0 })
    animation.addKeyframe(for: \.backgroundColor, at: 0.75, relativeValue: { $0?.withAlphaComponent(0.8) })
    animation.addKeyframe(for: \.backgroundColor, at: 1, relativeValue: { $0 })

    return animation
}

/*:

 Now that we have the animation for each subview, we can compose them into the final animation.

 */

func makeHierarchicalAnimation() -> Animation<RaceCarView> {
    var animation = Animation<RaceCarView>()

    animation.addChild(makeCarAnimation(), for: \.topView, startingAt: 0, relativeDuration: 1)
    animation.addChild(makeCarAnimation(), for: \.bottomView, startingAt: 0, relativeDuration: 1)

    animation.duration = 3

    return animation
}

let hierarchicalInstance = makeHierarchicalAnimation().perform(on: raceCarView)

/*:

 Run the playground up to this point to see our new animation in action. It should look exactly the same as the previous
 (non-hierarchical) one.

 What if we want to have the top view win the race to the right? We can simply modify the `relativeDuration` of the
 first child animation to be shorter than 1, and all of the keyframes in that animation will be adjusted. No need to
 manual change each keyframe.

 We can also mix child animations with other content (like keyframes and execution blocks) in the parent animation.
 Any values defined in the parent will override values defined in child animations.

 By composing animation together, we can build complex, multi-part animations that are made of small reusable components
 that are easy to reason about.

 */

//: [Next](@next)
