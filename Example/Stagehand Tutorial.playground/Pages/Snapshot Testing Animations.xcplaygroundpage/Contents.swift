//: [Previous](@previous)

import Stagehand
import StagehandTesting
import UIKit

/*:

 # Snapshot Testing Animations

 Once we've written our animation, it's important to ensure it doesn't regress as other changes are made. To accomplish
 this, Stagehand ships with a second framework, StagehandTesting, to enable writing snapshot tests for animations.

 Animation snapshot tests are built on top of the iOSSnapshotTestCase framework, so all of the same setup and behaviors
 will apply. To write an animation snapshot test, simply set up your animation and view, and call one of the snapshot
 verification methods.

 */

/*:

 To snapshot an animation at a single frame, use `SnapshotVerify(animation:on:at:)`:

 */

var animation = Animation<UIView>()

var view = UIView()

// Snapshot the animation at the midpoint.
SnapshotVerify(
    animation: animation,
    view: view,
    at: 0.5
)

/*:

 A similar method exists for snapshotting animation groups. In this case, you must also provide a view with which the
 animation can be verified, since the group doesn't know what the parent view of its elements is.

 */

var animationGroup = AnimationGroup()

SnapshotVerify(
    animationGroup: animationGroup,
    using: view,
    at: 0.5
)

/*:

 Beyond static snapshots of a specific frame, StagehandTesting can output animated GIFs of the entire animation.

 */

SnapshotVerify(
    animation: animation,
    on: view
)

/*:

 This methods has a few other parameters, such as `fps` and `bookendFrameDuration`, that can be used to tailor the
 output to your needs. Check out the header docs for that method for more details.

 */

//: [Next](@next)
