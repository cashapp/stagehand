//
//  Copyright 2019 Square Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

/// Defines the interface for an animation driver, the mechanism by which the progress an `AnimationInstance` is
/// controlled. This can be either a self-contained driver, like the `DisplayLinkDriver`, which controls the animation
/// on its own; or a conversion driver, like the `SnapshotTestDriver`, that controls the animation based on the inputs
/// to the driver.
///
/// This will also allow for drivers to control interactive animations in the future, where the driver converts its
/// input (for example, a gesture recognizer) into the corresponding progress of an animation.
protocol Driver: AnyObject {

    var animationInstance: DrivenAnimationInstance! { get set }

    func animationInstanceDidInitialize()

    func animationInstanceDidCancel(behavior: AnimationInstance.CancelationBehavior)

}

// MARK: -

protocol DrivenAnimationInstance: AnyObject {

    func executeBlocks(
        from startingRelativeTimestamp: Double,
        _ fromInclusivity: AnimationInstance.Inclusivity,
        to endingRelativeTimestamp: Double
    )

    func renderFrame(at relativeTimestamp: Double)

    func markAnimationAsComplete()

}

extension AnimationInstance: DrivenAnimationInstance { }
