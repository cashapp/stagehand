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

        assertSnapshot(matching: animation, as: .animatedImage(on: view), named: nameForDevice())
    }

    func testAnimationWithNonViewElementSnapshot() {
        let view = AnimatableContainerView(frame: .init(x: 0, y: 0, width: 200, height: 40))

        let element = AnimatableContainerView.Proxy(view: view)

        var animation = Animation<AnimatableContainerView.Proxy>()
        animation.addKeyframe(for: \.animatableViewTransform, at: 0, value: .identity)
        animation.addKeyframe(for: \.animatableViewTransform, at: 1, value: .init(translationX: 160, y: 0))

        assertSnapshot(matching: animation, as: .animatedImage(on: element, using: view), named: nameForDevice())
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
