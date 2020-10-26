//: [Previous](@previous)

import Stagehand

/*:

 # Animation Groups

 Animation groups allow multiple elements to be animated together, even if they can't be accessed via key paths from a
 single parent element. Constructing an animation group is similar to composing an animation hierarchy, except using
 references to instances of elements rather than key paths.

 */

var firstAnimation = Animation<UIView>()
var firstElement = UIView()

var secondAnimation = Animation<CALayer>()
var secondElement = CALayer()

var animationGroup = AnimationGroup()
animationGroup.addAnimation(firstAnimation, for: firstElement, startingAt: 0, relativeDuration: 1)
animationGroup.addAnimation(secondAnimation, for: secondElement, startingAt: 0, relativeDuration: 1)

/*:

 Like normal `Animation`s, we can change the `implicitDuration`, `curve`, and `implicitRepeatStyle` of our animation
 group as a whole.

 When we're ready to perform the animation, we call the `perform(delay:completion:)` method.

 */

animationGroup.perform()

/*:

 Since animation groups need to know about the instance during construction, they break the concept of separating the
 construction and execution of animations.

 Animation groups also hold a strong reference to each of the elements they animate. It is up to consumers to cancel
 the returned animation instance if the elements need to be deallocated before the animation completes naturally, as
 this will not happen automatically.

 For these reasons, it is generally preferrable to use an `Animation` when each of the subelements can be accessed via
 key paths.

 */

//: [Next](@next)
