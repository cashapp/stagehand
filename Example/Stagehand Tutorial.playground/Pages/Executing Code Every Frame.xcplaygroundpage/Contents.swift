//: [Previous](@previous)

/*:

 # Executing Code Every Frame

 Keyframes make it easy to interpolate properties over the course of our animation, execution blocks let us add actions
 at specific points in the animation, and property assignments make changing properties to discrete values easy. But
 sometimes we need something more manual, requiring us to run code every frame.

 */

/*:

 ## The Traditional Approach

 Traditionally, executing code during every render cycle can be done via a display link.

 */

import QuartzCore

final class DisplayLinkAnimator {

    // MARK: - Life Cycle

    init() {
        self.startTime = CFAbsoluteTime()
        self.displayLink = CADisplayLink(target: self, selector: #selector(renderFrame))
    }

    // MARK: - Private Properties

    private var displayLink: CADisplayLink!

    private let startTime: CFTimeInterval

    // MARK: - Public Methods

    func start() {
        displayLink.add(to: .current, forMode: .common)
    }

    @objc func renderFrame() {
        // Do some stuff here.
    }

}

/*:

 This comes with some standard boilerplate, but is managable. The bigger problem comes when we try to mix this with
 other animation code. Usually we end up having to get rid of other animations and render each frame manually, in order
 to make sure everything stays in sync.


 ## Adding Per-Frame Execution Blocks

 Stagehand makes mixing traditional animation techniques (like keyframes and execution blocks) and per-frame render code
 easy. The `Animation` struct has an `addPerFrameExecution(_:)` method to add a new block to be executed each frame.

 This block is called with a context that contains a variety of data, like the element being animated and the current
 progress into the animation.

 */

import Stagehand

var animation = Animation<UIView>()

animation.addPerFrameExecution { context in
    // The `context` contains the important things we need during our animation. Our view (the element we're animating)
    // is available via the `context.element`:
    _ = context.element
}

/*:

 Per-frame execution blocks will be executed _after_ all other parts of the animation have been applied (interpolating
 between keyframes, running any execution blocks, etc.). This means you can have logic in your per-frame execution block
 that calculates values using properties that are interpolated.

 */

//: [Next](@next)
