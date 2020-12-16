//
//  Copyright 2020 Square Inc.
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

import SnapshotTesting
import UIKit

@testable import Stagehand

/// **Do not add conformances to this protocol outside of StagehandTesting**.
///
/// This protocol is an unfortunate workaround for a limitation in how Swift handles extensions. Hopefully this will be
/// resolved in the future with the introduction of parameterized extensions.
///
/// See <https://github.com/apple/swift/blob/main/docs/GenericsManifesto.md#parameterized-extensions>.
public protocol SnapshotableViewAnimation {

    associatedtype ElementType: UIView

}

extension Animation: SnapshotableViewAnimation where ElementType: UIView {}

// MARK: -

/// **Do not add conformances to this protocol outside of StagehandTesting**.
///
/// This protocol is an unfortunate workaround for a limitation in how Swift handles extensions. Hopefully this will be
/// resolved in the future with the introduction of parameterized extensions.
///
/// See <https://github.com/apple/swift/blob/main/docs/GenericsManifesto.md#parameterized-extensions>.
public protocol SnapshotableAnimation {

    associatedtype ElementType: AnyObject

}

extension Animation: SnapshotableAnimation {}

// MARK: -

extension Snapshotting where Value: SnapshotableViewAnimation, Format == UIImage {

    public static func frameImage(
        on element: Value.ElementType,
        at relativeTimestamp: Double,
        drawHierarchyInKeyWindow: Bool = false,
        precision: Float = 1
    ) -> Snapshotting {
        return Snapshotting<UIView, UIImage>
            .image(drawHierarchyInKeyWindow: drawHierarchyInKeyWindow, precision: precision)
            .asyncPullback { animation in
                let animation = animation as! Animation<Value.ElementType>
                return Async { (snapshot: (UIView) -> Void) in
                    let driver = SnapshotTestDriver(relativeTimestamp: relativeTimestamp)

                    let animationInstance = AnimationInstance(
                        animation: animation,
                        element: element,
                        driver: driver
                    )

                    snapshot(element)

                    animationInstance.cancel(behavior: .revert)
                }
            }
    }

}

// MARK: -

extension Snapshotting where Value: SnapshotableAnimation, Format == UIImage {

    public static func frameImage(
        on element: Value.ElementType,
        using view: UIView,
        at relativeTimestamp: Double,
        drawHierarchyInKeyWindow: Bool = false,
        precision: Float = 1
    ) -> Snapshotting {
        return Snapshotting<UIView, UIImage>
            .image(drawHierarchyInKeyWindow: drawHierarchyInKeyWindow, precision: precision)
            .asyncPullback { animation in
                let animation = animation as! Animation<Value.ElementType>
                return Async { (snapshot: (UIView) -> Void) in
                    let driver = SnapshotTestDriver(relativeTimestamp: relativeTimestamp)

                    let animationInstance = AnimationInstance(
                        animation: animation,
                        element: element,
                        driver: driver
                    )

                    snapshot(view)

                    animationInstance.cancel(behavior: .revert)
                }
            }
    }

}

// MARK: -

extension Snapshotting where Value == AnimationGroup, Format == UIImage {

    public static func frameImage(
        using view: UIView,
        at relativeTimestamp: Double,
        drawHierarchyInKeyWindow: Bool = false,
        precision: Float = 1
    ) -> Snapshotting {
        return Snapshotting<UIView, UIImage>
            .image(drawHierarchyInKeyWindow: drawHierarchyInKeyWindow, precision: precision)
            .asyncPullback { animationGroup in
                let animation = animationGroup.animation
                return Async { (snapshot: (UIView) -> Void) in
                    let driver = SnapshotTestDriver(relativeTimestamp: relativeTimestamp)

                    let animationInstance = AnimationInstance(
                        animation: animation,
                        element: animationGroup.elementContainer,
                        driver: driver
                    )

                    snapshot(view)

                    animationInstance.cancel(behavior: .revert)
                }
            }
    }

}
