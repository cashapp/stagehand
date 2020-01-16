//: [Previous](@previous)

import PlaygroundSupport

/*:

 # Assigning Properties During Animations

 A special case of executing code during an animation involves assigning a value to a property. As an example, let's say
 we want to change the value of a view's `clipsToBounds` property at the half way point of our animation. Using
 execution blocks, our animation might look something like this:

 */

import Stagehand

var executionBlockAnimation = Animation<UIView>()

executionBlockAnimation.addExecution(
    onForward: {
        $0.clipsToBounds = true
    },
    at: 0.5
)

/*:

 This works fine if our animation only runs in the forward direction, but what if we need to handle the reverse case?
 Luckily, this is already handled by property assignments.

 */

var propertyAssignmentAnimation = Animation<UIView>()

propertyAssignmentAnimation.addAssignment(for: \.clipsToBounds, at: 0.5, value: true)

/*:

 Like the execution block above, this will set the value of `clipsToBounds` to be `true` half way through the animation.
 When run in reverse, the property assignment will restore `clipsToBounds` to its original value for when the property
 was assigned.

 */

propertyAssignmentAnimation.repeatStyle = .infinitlyRepeating(autoreversing: true)

let view = ExpandedBoundsView(frame: .init(x: 0, y: 0, width: 100, height: 100))
PlaygroundPage.current.liveView = WrapperView(wrappedView: view)
PlaygroundPage.current.needsIndefiniteExecution = true

propertyAssignmentAnimation.perform(on: view)

//: [Next](@next)
