import PlaygroundSupport

/*:

 # Executing Code During Animations

 Sometimes our animations include more than just iterpolating properties between different values. The reasons for doing
 this are widely varied - from setting properties immediately, to adding in sounds and haptics - but the mechanism is
 the same: we need to execute a block of code at a specific point in the animation.

 */

/*:

 ## Applying Models

 A common pattern in iOS development involves the use of view models - a representation of the data shown in a view that
 is generated and subsequently applied to a view. We've defined a `ModelDrivenView` class in the playground sources as a
 simple view to demonstrate how this works. The important part is that it defines a nested `Model` struct containing the
 relevant properties and an `apply(model:)` method to apply that model.

 For an example, let's say our design calls for animating a model change by fading out the view, applying the new model,
 then fading the view back in; with a total duration of 2 seconds.

 In traditional iOS animations, we might use a chain of UIView animation blocks, with the model application in the
 completion of the first animation block. We'll end up with something like this:

 */

let view = ModelDrivenView(frame: .init(x: 0, y: 0, width: 100, height: 100))
PlaygroundPage.current.liveView = view

let model = ModelDrivenView.Model(backgroundColor: .green)

UIView.animate(
    withDuration: 1,
    animations: {
        // Start by fading out the view.
        view.alpha = 0
    },
    completion: { finished in
        guard finished else {
            // We didn't finish the animation, so don't apply the model.
            return
        }

        // Once the view has faded out, apply the model.
        view.apply(model: model)

        // Then begin the second half of the animation, to fade the view back in.
        UIView.animate(
            withDuration: 1,
            animations: {
                view.alpha = 1
            }
        )
    }
)

/*:

 Run the playground up to this point to see our animation in action.

 */

/*:

 Beyond the usual problems with UIKit animations, chaining animations like this opens up potential for a lot of weird
 edge cases (like the animation being cancelled in the first half, handled by the guard in the first completion).

 Stagehand makes it easy to execute code during an animation, which allows us to build up the entire animation as a
 single unit, rather than chaining animations. Our animation may be composed of smaller children, but the entire unit
 itself will be executed together.

 */

import Stagehand

func makeAnimation(model: ModelDrivenView.Model) -> Animation<ModelDrivenView> {
    var animation = Animation<ModelDrivenView>()

    // Fade the view out over the first half of the animation.
    animation.addKeyframe(for: \.alpha, at: 0, value: 1)
    animation.addKeyframe(for: \.alpha, at: 0.5, value: 0)

    // At the halfway point, apply the new model.
    animation.addExecution(
        onForward: { view in
            view.apply(model: model)
        },
        at: 0.5
    )

    // Fade the view back in over the second half of the animation.
    animation.addKeyframe(for: \.alpha, at: 1, value: 1)

    // Make the total duration of the animation 2 seconds.
    animation.implicitDuration = 2

    return animation
}

let view2 = ModelDrivenView(frame: .init(x: 0, y: 0, width: 100, height: 100))
PlaygroundPage.current.liveView = view2

let animation = makeAnimation(model: model)
animation.perform(on: view2)

/*:

 Run the playground up to this point to see our animation in action.

 */

/*:

 ## Handling Reversing Animations

 Our animation works great for simple animations, but what if our animation needs to reverse? Say we want to apply the
 model only temporarily, then return it to the previous state.

 By default, execution blocks only require a block to execute when running in the forward direction (notice the
 `onForward` label on the closure parameter). When run in reverse, an execution block with no explicitly defined reverse
 block will no-op. In order to specify the reverse behavior, we need to specify an `onReverse` closure.

 For our example, we want the original model of the view so we can re-apply it. Our `ModelDrivenView` is simple enough
 that we have defined a computed `currentModel` property, but this could also be a stored property that's updated when a
 new model is applied. Since our `currentModel` will be the __new__ model when the execution block is run in reverse,
 we'll pull the current model when we create the animation.

 */

func makeAnimation(modelToFlash: ModelDrivenView.Model, modelToRestore: ModelDrivenView.Model) -> Animation<ModelDrivenView> {
    var animation = Animation<ModelDrivenView>()

    animation.addKeyframe(for: \.alpha, at: 0, value: 1)
    animation.addKeyframe(for: \.alpha, at: 0.5, value: 0)
    animation.addKeyframe(for: \.alpha, at: 1, value: 1)

    // At the halfway point, apply the new model.
    animation.addExecution(
        onForward: { view in
            view.apply(model: modelToFlash)
        },
        onReverse: { view in
            view.apply(model: modelToRestore)
        },
        at: 0.5
    )

    animation.implicitDuration = 2
    animation.implicitRepeatStyle = .repeating(count: 2, autoreversing: true)

    return animation
}

let view3 = ModelDrivenView(frame: .init(x: 0, y: 0, width: 100, height: 100))
PlaygroundPage.current.liveView = view3

let reversingAnimation = makeAnimation(modelToFlash: model, modelToRestore: view3.currentModel)
reversingAnimation.perform(on: view3)

/*:

 Run the playground up to this point to see our animation in action.

 */

//: [Next](@next)
