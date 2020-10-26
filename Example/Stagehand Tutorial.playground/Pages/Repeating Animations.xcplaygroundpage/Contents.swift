//: [Previous](@previous)

import Stagehand

/*:

 # Repeating Animations

 By default, animations will run once before completing. Sometimes, though, we want our animation to loop through
 multiple times, sometimes even indefinitely.

 Using the `Animation.implicitRepeatStyle` property, we can control how our animation repeats.

 */

var animation = Animation<UIView>()

// The default style is to not repeat.
animation.implicitRepeatStyle = .noRepeat

/*:

 To have our animation repeat one more time after it completes, we can set the repeat style to `.repeating` with a count
 of 2 (for two total cycles of the animation).

 */

animation.implicitRepeatStyle = .repeating(count: 2, autoreversing: false)

/*:

 We can also set our animation to repeat indefinitely. With this set, our animation will only stop when it is cancelled
 (either by calling `cancel(behavior:)` on the instance, or if the element it is animating is deallocated).

 */

animation.implicitRepeatStyle = .infinitelyRepeating(autoreversing: false)

/*:

 The `autoreversing` parameter determines whether alternating cycles are run in opposite directions. Typically,
 animations that start and end in the same state (e.g. a spinner) will use `false`. Other animations may not reverse,
 but many will.

 */

/*:

 ## Handling Reverse Animations

 When we do use reversing animations, we need to make sure our animation is set up to handle a reverse cycle.

 Keyframes, property assignments, and per-frame execution blocks have support for reverse cycles built in. With standard
 execution blocks, the default behavior on a reverse cycle is to no-op. If this is not the expected behavior, we need to
 provide a closure to run on the reverse cycles.

 Read on to the [Executing Code During Animations](Executing%20Code%20During%20Animations) for more details.

 */

//: [Next](@next)
