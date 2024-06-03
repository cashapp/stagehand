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

#if BAZEL_PACKAGE
@testable import StagehandTestingCore
import iOSSnapshotTestCase
#else
import FBSnapshotTestCase
#endif

@testable import Stagehand

extension FBSnapshotTestCase {

    /// Snapshots the `element` with the `animation` performed on it and run forward up to the `relativeTimestamp`.
    ///
    /// When `recordMode` is true, records a snapshot of the view. When `recordMode` is false, performs a comparison
    /// with the existing snapshot.
    ///
    /// - parameter animation: The animation to perform on the element.
    /// - parameter element: The view to be animated, and which will be snapshotted to verify the animation.
    /// - parameter relativeTimestamp: The relative progress into the animation at which the snapshot should be
    /// generated. Must be in the range `[0,1]`, where 0 is the beginning and 1 is the end of the animation.
    /// - parameter identifier: An optional identifier included in the snapshot name, for use when there are multiple
    /// snapshot tests in a given test method. Defaults to no identifier.
    /// - parameter file: The file in which the test result should be attributed.
    /// - parameter line: The line in which the test result should be attributed.
    @MainActor
    public func SnapshotVerify<ElementType: UIView>(
        animation: Animation<ElementType>,
        on element: ElementType,
        at relativeTimestamp: Double,
        identifier: String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let driver = SnapshotTestDriver(relativeTimestamp: relativeTimestamp)

        let animationInstance = AnimationInstance(
            animation: animation,
            element: element,
            driver: driver
        )

        FBSnapshotVerifyView(element, identifier: identifier, file: file, line: line)

        animationInstance.cancel(behavior: .revert)
    }

    /// Performs the `animation` on the `element` and runs it up to the given `relativeTimestamp`, then snapshots the
    /// `view`.
    ///
    /// When `recordMode` is true, records a snapshot of the view. When `recordMode` is false, performs a comparison
    /// with the existing snapshot.
    ///
    /// - parameter animation: The animation to perform on the element.
    /// - parameter element: The element to be animated.
    /// - parameter view: The view that should be snapshotted to verify the animation.
    /// - parameter relativeTimestamp: The relative progress into the animation at which the snapshot should be
    /// generated. Must be in the range `[0,1]`, where 0 is the beginning and 1 is the end of the animation.
    /// - parameter identifier: An optional identifier included in the snapshot name, for use when there are multiple
    /// snapshot tests in a given test method. Defaults to no identifier.
    /// - parameter file: The file in which the test result should be attributed.
    /// - parameter line: The line in which the test result should be attributed.
    @MainActor
    public func SnapshotVerify<ElementType>(
        animation: Animation<ElementType>,
        on element: ElementType,
        using view: UIView,
        at relativeTimestamp: Double,
        identifier: String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let driver = SnapshotTestDriver(relativeTimestamp: relativeTimestamp)

        let animationInstance = AnimationInstance(
            animation: animation,
            element: element,
            driver: driver
        )

        FBSnapshotVerifyView(view, identifier: identifier, file: file, line: line)

        animationInstance.cancel(behavior: .revert)
    }

    /// Executes the `animationGroup` up to the given `relativeTimestamp`, then snapshots the `view`.
    ///
    /// When `recordMode` is true, records a snapshot of the view. When `recordMode` is false, performs a comparison
    /// with the existing snapshot.
    ///
    /// - parameter animationGroup: The animation group to execute.
    /// - parameter view: The view that should be snapshotted to verify the animation group. In practice, this will
    /// usually be a view that is either in the animation group, or is a parent that contains the views in the animation
    /// group.
    /// - parameter relativeTimestamp: The relative progress into the animation at which the snapshot should be
    /// generated. Must be in the range `[0,1]`, where 0 is the beginning and 1 is the end of the animation.
    /// - parameter identifier: An optional identifier included in the snapshot name, for use when there are multiple
    /// snapshot tests in a given test method. Defaults to no identifier.
    /// - parameter file: The file in which the test result should be attributed.
    /// - parameter line: The line in which the test result should be attributed.
    @MainActor
    public func SnapshotVerify(
        animationGroup: AnimationGroup,
        using view: UIView,
        at relativeTimestamp: Double,
        identifier: String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let driver = SnapshotTestDriver(relativeTimestamp: relativeTimestamp)

        let animationInstance = AnimationInstance(
            animation: animationGroup.animation,
            element: animationGroup.elementContainer,
            driver: driver
        )

        FBSnapshotVerifyView(view, identifier: identifier, file: file, line: line)

        animationInstance.cancel(behavior: .revert)
    }

}
