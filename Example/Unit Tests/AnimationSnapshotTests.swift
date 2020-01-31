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

import Stagehand
import StagehandTesting
import FBSnapshotTestCase

final class AnimationSnapshotTests: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()

        fileNameOptions = [.OS, .screenSize, .screenScale]

        recordMode = false
    }

    // MARK: - Tests - Frame Snapshots

    func testSimpleAnimationSnapshot() {
        let view = View(frame: .init(x: 0, y: 0, width: 200, height: 40))

        var animation = Animation<View>()
        animation.addKeyframe(for: \.animatableView.transform, at: 0, value: .identity)
        animation.addKeyframe(for: \.animatableView.transform, at: 1, value: .init(translationX: 160, y: 0))

        SnapshotVerify(animation: animation, on: view, at: 0, identifier: "start")
        SnapshotVerify(animation: animation, on: view, at: 0.5, identifier: "middle")
        SnapshotVerify(animation: animation, on: view, at: 1, identifier: "end")

        // This intentionally uses the same identifier as the animation at 0 to ensure that the view is restored to its
        // original state after snapshotting.
        FBSnapshotVerifyView(view, identifier: "start")
    }

    func testAnimationWithNonViewElementSnapshot() {
        let view = View(frame: .init(x: 0, y: 0, width: 200, height: 40))

        let element = Proxy(view: view)

        var animation = Animation<Proxy>()
        animation.addKeyframe(for: \.animatableViewTransform, at: 0, value: .identity)
        animation.addKeyframe(for: \.animatableViewTransform, at: 1, value: .init(translationX: 160, y: 0))

        SnapshotVerify(animation: animation, on: element, using: view, at: 0, identifier: "start")
        SnapshotVerify(animation: animation, on: element, using: view, at: 0.5, identifier: "middle")
        SnapshotVerify(animation: animation, on: element, using: view, at: 1, identifier: "end")

        // This intentionally uses the same identifier as the animation at 0 to ensure that the view is restored to its
        // original state after snapshotting.
        FBSnapshotVerifyView(view, identifier: "start")
    }

    func testAnimationWithExecutionBlocksSnapshot() {
        let view = View(frame: .init(x: 0, y: 0, width: 200, height: 40))

        var animation = Animation<View>()
        animation.addKeyframe(for: \.animatableView.transform, at: 0, value: .identity)
        animation.addKeyframe(for: \.animatableView.transform, at: 1, value: .init(translationX: 160, y: 0))
        animation.addExecution(
            onForward: { $0.animatableView.backgroundColor = .green },
            onReverse: { $0.animatableView.backgroundColor = .red },
            at: 0.5
        )

        SnapshotVerify(animation: animation, on: view, at: 0, identifier: "start")
        SnapshotVerify(animation: animation, on: view, at: 0.5, identifier: "middle")
        SnapshotVerify(animation: animation, on: view, at: 1, identifier: "end")

        // This intentionally uses the same identifier as the animation at 0 to ensure that the view is restored to its
        // original state after snapshotting.
        FBSnapshotVerifyView(view, identifier: "start")
    }

    // MARK: - Tests - Animated GIF

    func testSimpleAnimationSnapshotGIF() {
        let view = View(frame: .init(x: 0, y: 0, width: 200, height: 40))

        var animation = Animation<View>()
        animation.addKeyframe(for: \.animatableView.transform, at: 0, value: .identity)
        animation.addKeyframe(for: \.animatableView.transform, at: 1, value: .init(translationX: 160, y: 0))

        SnapshotVerify(animation: animation, on: view)
    }

    func testSimpleAnimationSnapshotGIFAtHighFPS() {
        let view = View(frame: .init(x: 0, y: 0, width: 200, height: 40))

        var animation = Animation<View>()
        animation.addKeyframe(for: \.animatableView.transform, at: 0, value: .identity)
        animation.addKeyframe(for: \.animatableView.transform, at: 1, value: .init(translationX: 160, y: 0))

        SnapshotVerify(animation: animation, on: view, fps: 30)
    }

    func testLongAnimationSnapshotGIF() {
        let view = View(frame: .init(x: 0, y: 0, width: 200, height: 40))

        var animation = Animation<View>()
        animation.addKeyframe(for: \.animatableView.transform, at: 0, value: .identity)
        animation.addKeyframe(for: \.animatableView.transform, at: 1, value: .init(translationX: 160, y: 0))
        animation.duration = 2

        SnapshotVerify(animation: animation, on: view)
    }

    func testAutoreversingAnimationSnapshotGIF() {
        let view = View(frame: .init(x: 0, y: 0, width: 200, height: 40))

        var animation = Animation<View>()
        animation.addKeyframe(for: \.animatableView.transform, at: 0, value: .identity)
        animation.addKeyframe(for: \.animatableView.transform, at: 1, value: .init(translationX: 160, y: 0))
        animation.repeatStyle = .infinitelyRepeating(autoreversing: true)

        SnapshotVerify(animation: animation, on: view, bookendFrameDuration: .matchIntermediateFrames)
    }

    func testAnimationWithExecutionBlocksSnapshotGIF() {
        let view = View(frame: .init(x: 0, y: 0, width: 200, height: 40))

        var animation = Animation<View>()
        animation.addKeyframe(for: \.animatableView.transform, at: 0, value: .identity)
        animation.addKeyframe(for: \.animatableView.transform, at: 1, value: .init(translationX: 160, y: 0))
        animation.addExecution(
            onForward: { $0.animatableView.backgroundColor = .green },
            onReverse: { $0.animatableView.backgroundColor = .red },
            at: 0.5
        )

        SnapshotVerify(animation: animation, on: view)
    }

    func testAutoreversingAnimationWithExecutionBlocksSnapshotGIF() {
        let view = View(frame: .init(x: 0, y: 0, width: 200, height: 40))

        var animation = Animation<View>()
        animation.addKeyframe(for: \.animatableView.transform, at: 0, value: .identity)
        animation.addKeyframe(for: \.animatableView.transform, at: 1, value: .init(translationX: 160, y: 0))
        animation.addExecution(
            onForward: { $0.animatableView.backgroundColor = .green },
            onReverse: { $0.animatableView.backgroundColor = .red },
            at: 0.5
        )
        animation.repeatStyle = .infinitelyRepeating(autoreversing: true)

        SnapshotVerify(animation: animation, on: view)
    }

    func testAnimationWithNonViewElementSnapshotGIF() {
        let view = View(frame: .init(x: 0, y: 0, width: 200, height: 40))

        let element = Proxy(view: view)

        var animation = Animation<Proxy>()
        animation.addKeyframe(for: \.animatableViewTransform, at: 0, value: .identity)
        animation.addKeyframe(for: \.animatableViewTransform, at: 1, value: .init(translationX: 160, y: 0))

        SnapshotVerify(animation: animation, on: element, using: view)
    }

}

// MARK: -

extension AnimationSnapshotTests {

    final class View: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            animatableView.backgroundColor = .red
            addSubview(animatableView)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Public Properties

        let animatableView: UIView = .init()

        // MARK: - UIView

        override func layoutSubviews() {
            animatableView.bounds.size = .init(width: 20, height: 20)
            animatableView.center = .init(x: 20, y: bounds.midY)
        }

    }

}

// MARK: -

extension AnimationSnapshotTests {

    final class Proxy {

        // MARK: - Life Cycle

        init(view: View) {
            self.view = view
        }

        // MARK: - Public Properties

        public var animatableViewTransform: CGAffineTransform {
            get {
                return view.animatableView.transform
            }
            set {
                view.animatableView.transform = newValue
            }
        }

        // MARK: - Private Properties

        private let view: View

    }

}
