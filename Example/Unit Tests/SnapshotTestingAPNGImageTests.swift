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
import Stagehand
import StagehandTesting
import XCTest

final class SnapshotTestingAPNGImageTests: SnapshotTestCase {

    // MARK: - Tests

    func testSimpleAnimationSnapshot() {
        let view = AnimatableContainerView(frame: .init(x: 0, y: 0, width: 200, height: 40))

        var animation = Animation<AnimatableContainerView>()
        animation.addKeyframe(for: \.animatableView.transform, at: 0, value: .identity)
        animation.addKeyframe(for: \.animatableView.transform, at: 1, value: .init(translationX: 160, y: 0))

        assertSnapshot(matching: view, as: .image, named: nameForDevice(baseName: "start"))

        assertSnapshot(matching: animation, as: .animatedImage(on: view), named: nameForDevice())

        // This intentionally uses the same identifier as the snapshot from before the animation to ensure that the view
        // is restored to its original state after snapshotting.
        assertSnapshot(matching: view, as: .image, named: nameForDevice(baseName: "start"))
    }

    func testAnimationSnapshotWithRepeatingAnimation() {
        let view = AnimatableContainerView(frame: .init(x: 0, y: 0, width: 200, height: 40))

        var animation = Animation<AnimatableContainerView>()
        animation.addKeyframe(for: \.animatableView.transform, at: 0, value: .identity)
        animation.addKeyframe(for: \.animatableView.transform, at: 1, value: .init(translationX: 160, y: 0))
        animation.addExecution(
            onForward: { $0.animatableView.backgroundColor = .green },
            onReverse: { $0.animatableView.backgroundColor = .blue },
            at: 0.5
        )
        animation.implicitRepeatStyle = .infinitelyRepeating(autoreversing: true)

        assertSnapshot(matching: animation, as: .animatedImage(on: view), named: nameForDevice())
    }

    func testAnimationWithNonViewElementSnapshot() {
        let view = AnimatableContainerView(frame: .init(x: 0, y: 0, width: 200, height: 40))

        let element = AnimatableContainerView.Proxy(view: view)

        var animation = Animation<AnimatableContainerView.Proxy>()
        animation.addKeyframe(for: \.animatableViewTransform, at: 0, value: .identity)
        animation.addKeyframe(for: \.animatableViewTransform, at: 1, value: .init(translationX: 160, y: 0))

        assertSnapshot(matching: view, as: .image, named: nameForDevice(baseName: "start"))

        assertSnapshot(matching: animation, as: .animatedImage(on: element, using: view), named: nameForDevice())

        // This intentionally uses the same identifier as the snapshot from before the animation to ensure that the view
        // is restored to its original state after snapshotting.
        assertSnapshot(matching: view, as: .image, named: nameForDevice(baseName: "start"))
    }

    func testAnimationGroupSnapshot() {
        let view = AnimatableContainerView(frame: .init(x: 0, y: 0, width: 200, height: 40))

        var animation = Animation<AnimatableContainerView>()
        animation.addKeyframe(for: \.animatableView.transform, at: 0, value: .identity)
        animation.addKeyframe(for: \.animatableView.transform, at: 1, value: .init(translationX: 160, y: 0))

        var animationGroup = AnimationGroup()
        animationGroup.addAnimation(animation, for: view, startingAt: 0, relativeDuration: 1)

        assertSnapshot(matching: view, as: .image, named: nameForDevice(baseName: "start"))

        assertSnapshot(matching: animationGroup, as: .animatedImage(using: view), named: nameForDevice())

        // This intentionally uses the same identifier as the snapshot from before the animation to ensure that the view
        // is restored to its original state after snapshotting.
        assertSnapshot(matching: view, as: .image, named: nameForDevice(baseName: "start"))
    }
    
    func testNestedAnimationGroupSnapshot() {
        let view = AnimatableContainerView(frame: .init(x: 0, y: 0, width: 200, height: 100))
        
        var animation1 = Animation<AnimatableContainerView>()
        animation1.addKeyframe(for: \.animatableView.transform, at: 0, value: .identity)
        animation1.addKeyframe(for: \.animatableView.transform, at: 1, value: .init(translationX: 50, y: 0))
        
        var animation2 = Animation<AnimatableContainerView>()
        animation2.addKeyframe(for: \.animatableView.transform, at: 0, value: .init(translationX: 50, y: 0))
        animation2.addKeyframe(for: \.animatableView.transform, at: 1, value: .init(translationX: 100, y: 0))
        
        var nestedGroup = AnimationGroup()
        nestedGroup.addAnimation(animation1, for: view, startingAt: 0, relativeDuration: 0.5)
        nestedGroup.addAnimation(animation2, for: view, startingAt: 0.5, relativeDuration: 0.5)
        
        var parentGroup = AnimationGroup()
        parentGroup.addAnimationGroup(nestedGroup, startingAt: 0, relativeDuration: 1)
        
        assertSnapshot(matching: view, as: .image, named: nameForDevice(baseName: "start"))
        assertSnapshot(matching: parentGroup, as: .animatedImage(using: view), named: nameForDevice())
        
        // This intentionally uses the same identifier as the snapshot from before the animation to ensure that the view
        // is restored to its original state after snapshotting.
        assertSnapshot(matching: view, as: .image, named: nameForDevice(baseName: "start"))
    }

    // MARK: - Private Methods

    private func nameForDevice(baseName: String? = nil) -> String {
        let size = UIScreen.main.bounds.size
        let scale = UIScreen.main.scale
        let version = UIDevice.current.systemVersion
        let deviceName = "\(Int(size.width))x\(Int(size.height))-\(version)-\(Int(scale))x"

        return [baseName, deviceName]
            .compactMap { $0 }
            .joined(separator: "-")
    }

}
