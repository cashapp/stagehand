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
import XCTest

@testable import Stagehand

extension Snapshotting where Value: SnapshottableViewAnimation, Format == Data {

    public static func animatedImage(
        on element: Value.ElementType,
        fps: Double = AnimationSnapshotting.defaultAnimationSnapshotFPS,
        bookendFrameDuration: AnimationSnapshotting.BookendFrameDuration = .default
    ) -> Snapshotting {
        return SimplySnapshotting<Data>
            .apngData
            .asyncPullback { animation in
                let animation = animation as! Animation<Value.ElementType>
                return Async { (snapshot: (Data) -> Void) in
                    let driver = NoOpDriver()

                    let animationInstance = AnimationInstance(
                        animation: animation,
                        element: element,
                        driver: driver
                    )

                    defer {
                        animationInstance.cancel(behavior: .revert)
                    }

                    let includeReverseCycle: Bool
                    switch animation.implicitRepeatStyle {
                    case let .repeating(count: count, autoreversing: autoreversing):
                        includeReverseCycle = (count != 1 && autoreversing)
                    }

                    guard let imageURL = AnimationSnapshotting.generateAnimatedSnapshot(
                        of: animationInstance,
                        using: element,
                        animationDuration: animation.implicitDuration,
                        includeReverseCycle: includeReverseCycle,
                        fps: fps,
                        bookendFrameDuration: bookendFrameDuration
                    ) else {
                        snapshot(Data())
                        return
                    }

                    snapshot((try? Data(contentsOf: imageURL)) ?? Data())
                }
            }
    }

}

// MARK: -

extension Snapshotting where Value: SnapshottableAnimation, Format == Data {

    public static func animatedImage(
        on element: Value.ElementType,
        using view: UIView,
        fps: Double = AnimationSnapshotting.defaultAnimationSnapshotFPS,
        bookendFrameDuration: AnimationSnapshotting.BookendFrameDuration = .default
    ) -> Snapshotting {
        return SimplySnapshotting<Data>
            .apngData
            .asyncPullback { animation in
                let animation = animation as! Animation<Value.ElementType>
                return Async { (snapshot: (Data) -> Void) in
                    let driver = NoOpDriver()

                    let animationInstance = AnimationInstance(
                        animation: animation,
                        element: element,
                        driver: driver
                    )

                    defer {
                        animationInstance.cancel(behavior: .revert)
                    }

                    let includeReverseCycle: Bool
                    switch animation.implicitRepeatStyle {
                    case let .repeating(count: count, autoreversing: autoreversing):
                        includeReverseCycle = (count != 1 && autoreversing)
                    }

                    guard let imageURL = AnimationSnapshotting.generateAnimatedSnapshot(
                        of: animationInstance,
                        using: view,
                        animationDuration: animation.implicitDuration,
                        includeReverseCycle: includeReverseCycle,
                        fps: fps,
                        bookendFrameDuration: bookendFrameDuration
                    ) else {
                        snapshot(Data())
                        return
                    }

                    snapshot((try? Data(contentsOf: imageURL)) ?? Data())
                }
            }
    }

}

// MARK: -

extension Snapshotting where Value == AnimationGroup, Format == Data {

    public static func animatedImage(
        using view: UIView,
        fps: Double = AnimationSnapshotting.defaultAnimationSnapshotFPS,
        bookendFrameDuration: AnimationSnapshotting.BookendFrameDuration = .default
    ) -> Snapshotting {
        return SimplySnapshotting<Data>
            .apngData
            .asyncPullback { animationGroup in
                let animation = animationGroup.animation
                return Async { (snapshot: (Data) -> Void) in
                    let driver = NoOpDriver()

                    let animationInstance = AnimationInstance(
                        animation: animation,
                        element: animationGroup.elementContainer,
                        driver: driver
                    )

                    defer {
                        animationInstance.cancel(behavior: .revert)
                    }

                    let includeReverseCycle: Bool
                    switch animation.implicitRepeatStyle {
                    case let .repeating(count: count, autoreversing: autoreversing):
                        includeReverseCycle = (count != 1 && autoreversing)
                    }

                    guard let imageURL = AnimationSnapshotting.generateAnimatedSnapshot(
                        of: animationInstance,
                        using: view,
                        animationDuration: animation.implicitDuration,
                        includeReverseCycle: includeReverseCycle,
                        fps: fps,
                        bookendFrameDuration: bookendFrameDuration
                    ) else {
                        snapshot(Data())
                        return
                    }

                    snapshot((try? Data(contentsOf: imageURL)) ?? Data())
                }
            }
    }

}

// MARK: -

extension Snapshotting where Value == Data, Format == Data {

    fileprivate static var apngData: Snapshotting {
        return .init(
            pathExtension: "png",
            diffing: .init(toData: { $0 }, fromData: { $0 }) { referenceImageData, testImageData in
                guard !testImageData.isEmpty else {
                    return ("Failed to generate test image", [])
                }

                if testImageData == referenceImageData {
                    return nil

                } else {
                    let referenceAttachment = XCTAttachment(
                        data: referenceImageData,
                        uniformTypeIdentifier: "public.png"
                    )
                    referenceAttachment.name = "Reference Image"

                    let failedAttachment = XCTAttachment(
                        data: testImageData,
                        uniformTypeIdentifier: "public.png"
                    )
                    failedAttachment.name = "Failed Image"

                    return ("Test image doesn't match reference image.", [referenceAttachment, failedAttachment])
                }
            }
        )
    }

}
