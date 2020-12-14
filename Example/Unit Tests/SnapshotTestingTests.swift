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

final class SnapshotTestingTests: SnapshotTestCase {

    func testSimpleAnimationSnapshot() {
        let view = View(frame: .init(x: 0, y: 0, width: 200, height: 40))

        var animation = Animation<View>()
        animation.addKeyframe(for: \.animatableView.transform, at: 0, value: .identity)
        animation.addKeyframe(for: \.animatableView.transform, at: 1, value: .init(translationX: 160, y: 0))

        assertSnapshot(matching: animation, as: .frameImage(on: view, at: 0.0), named: "start")
        assertSnapshot(matching: animation, as: .frameImage(on: view, at: 0.5), named: "middle")
        assertSnapshot(matching: animation, as: .frameImage(on: view, at: 1.0), named: "end")

        // This intentionally uses the same identifier as the animation at 0 to ensure that the view is restored to its
        // original state after snapshotting.
        assertSnapshot(matching: view, as: .image, named: "start")
    }

    func testAnimationWithNonViewElementSnapshot() {
        let view = View(frame: .init(x: 0, y: 0, width: 200, height: 40))

        let element = Proxy(view: view)

        var animation = Animation<Proxy>()
        animation.addKeyframe(for: \.animatableViewTransform, at: 0, value: .identity)
        animation.addKeyframe(for: \.animatableViewTransform, at: 1, value: .init(translationX: 160, y: 0))

        assertSnapshot(matching: animation, as: .frameImage(on: element, using: view, at: 0.0), named: "start")
        assertSnapshot(matching: animation, as: .frameImage(on: element, using: view, at: 0.5), named: "middle")
        assertSnapshot(matching: animation, as: .frameImage(on: element, using: view, at: 1.0), named: "end")

        // This intentionally uses the same identifier as the animation at 0 to ensure that the view is restored to its
        // original state after snapshotting.
        assertSnapshot(matching: view, as: .image, named: "start")
    }

    func testAnimationGroupSnapshot() {
        let view = View(frame: .init(x: 0, y: 0, width: 200, height: 40))

        var animation = Animation<View>()
        animation.addKeyframe(for: \.animatableView.transform, at: 0, value: .identity)
        animation.addKeyframe(for: \.animatableView.transform, at: 1, value: .init(translationX: 160, y: 0))

        var animationGroup = AnimationGroup()
        animationGroup.addAnimation(animation, for: view, startingAt: 0, relativeDuration: 1)

        assertSnapshot(matching: animationGroup, as: .frameImage(using: view, at: 0.0), named: "start")
        assertSnapshot(matching: animationGroup, as: .frameImage(using: view, at: 0.5), named: "middle")
        assertSnapshot(matching: animationGroup, as: .frameImage(using: view, at: 1.0), named: "end")

        // This intentionally uses the same identifier as the animation at 0 to ensure that the view is restored to its
        // original state after snapshotting.
        assertSnapshot(matching: view, as: .image, named: "start")
    }

}

// MARK: -

extension SnapshotTestingTests {

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

extension SnapshotTestingTests {

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
