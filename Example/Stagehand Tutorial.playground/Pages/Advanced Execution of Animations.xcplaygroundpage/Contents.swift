//: [Previous](@previous)

import PlaygroundSupport
import Stagehand
import UIKit

/*:

 # Advanced Execution of Animations

 We've already seen the basics of executing an animation, using the `perform(on:delay:completion:)` method.

 */

let animation = AnimationFactory.makeBasicViewAnimation()

let view = UIView(frame: .init(x: 0, y: 0, width: 100, height: 100))
view.backgroundColor = .red
PlaygroundPage.current.liveView = WrapperView(wrappedView: view)

animation.perform(
    on: view,
    completion: { success in
        if success {
            print("Our animation has successfully completed.")
        } else {
            print("Our animation has stopped running, but didn't finish.")
        }
    }
)

/*:

 ## Cancelling Our Animation

 When an animation is being performed, it holds onto the element it is animating weakly and will cancel itself if that
 element is deallocated. What if we need to stop the animation before that point though?

 The `perform(on:delay:completion:)` method returns an `AnimationInstance` that can be used to track and control the
 animation. We can use this animation instance to cancel the animation.

 */

let animationInstance = animation.perform(on: view)

animationInstance.cancel()

/*:

 There are a few different behaviors you can use when cancelling an animation. The default is to halt the animation - to
 leave it in its current state when it was canceled. You can also revert the animation back to the starting point or
 jump to the final state. Check out the "Animation Cancellation" screen in the demo app to see how each of these work.

 Using the animation instance, we can also check the status of our animation at any point.

 */

switch animationInstance.status {
case .pending:
    print("Our animation hasn't started yet.")

case let .animating(progress: progress):
    print("Our animation is \(progress * 100)% complete.")

case .complete:
    print("Our animation completed successfully.")

case let .canceled(behavior: behavior):
    print("Our animation was canceled using the \(behavior) behavior.")
}

/*:

 ## Adding a Delay

 What if we aren't ready to start our animation immediately? The `perform(on:delay:completion:)` method makes it easy to
 add a delay before our animation starts executing.

 */

animation.perform(on: view, delay: 2)

/*:

 One of the superpowers Stagehand has over `UIView` animations is the separation of construction and execution. Since we
 can build up our `Animation` and execute it at a later time, we don't need to know when (or even if) it will be
 performed when we build it.


 ## Queueing Animations

 Sometimes we want to run animations in sequence. Stagehand provides the `AnimationQueue` as a way to do this. We create
 our animation queue targeting a specific element.

 When we enqueue the first animation, it will begin executing immediately. The next animation we enqueue will begin
 executing when the first one completes, or immediately if the first one hasn't already completed. `enqueue(animation:)`
 also returns an `AnimationInstance` so we can track and control each instance in the queue separately.

 */

let animationQueue = AnimationQueue(element: view)

animationQueue.enqueue(animation: animation)

//: [Next](@next)
