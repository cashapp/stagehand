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

import UIKit

// This file is testing the collection keyframes feature of Stagehand, which is not yet ready for release. Use a
// testable import here so we can call the internal methods.
@testable import Stagehand

final class CollectionKeyframesViewController: DemoViewController {

    // MARK: - Life Cycle

    override init() {
        super.init()

        contentView = mainView

        animationRows = [
            ("Bounce All", { [unowned self] in
                self.reset()

                var animation = Animation<View>()
                animation.addKeyframe(
                    for: \.transform,
                    ofElementsIn: \.animatableViews,
                    at: 0,
                    value: .identity
                )
                animation.addKeyframe(
                    for: \.transform,
                    ofElementsIn: \.animatableViews,
                    at: 0.5,
                    value: .init(translationX: 0, y: -self.mainView.bounds.height / 2)
                )
                animation.addKeyframe(
                    for: \.transform,
                    ofElementsIn: \.animatableViews,
                    at: 1,
                    value: .identity
                )

                self.animationInstance = animation.perform(on: self.mainView)
            }),
            ("Bounce Odd Views", { [unowned self] in
                self.reset()

                var animation = Animation<View>()
                animation.addKeyframe(
                    for: \.transform,
                    ofElementsIn: \.oddViews,
                    at: 0,
                    value: .identity
                )
                animation.addKeyframe(
                    for: \.transform,
                    ofElementsIn: \.oddViews,
                    at: 0.5,
                    value: .init(translationX: 0, y: -self.mainView.bounds.height / 2)
                )
                animation.addKeyframe(
                    for: \.transform,
                    ofElementsIn: \.oddViews,
                    at: 1,
                    value: .identity
                )

                self.animationInstance = animation.perform(on: self.mainView)
            }),
            ("Bounce In Order", { [unowned self] in
                self.reset()

                var animation = Animation<View>()
                animation.addKeyframe(
                    for: \.transform,
                    ofElementsIn: \.animatableViews,
                    at: { index, count in 0.33 * Double(index) / Double(count - 1) },
                    value: .identity
                )
                animation.addKeyframe(
                    for: \.transform,
                    ofElementsIn: \.animatableViews,
                    at: { index, count in 0.33 + 0.33 * Double(index) / Double(count - 1) },
                    value: .init(translationX: 0, y: -self.mainView.bounds.height / 2)
                )
                animation.addKeyframe(
                    for: \.transform,
                    ofElementsIn: \.animatableViews,
                    at: { index, count in 0.67 + 0.33 * Double(index) / Double(count - 1) },
                    value: .identity
                )

                self.animationInstance = animation.perform(on: self.mainView)
            }),
            ("Bounce All (in Child Animation)", { [unowned self] in
                self.reset()

                var animation = Animation<View>()
                animation.addKeyframe(
                    for: \.transform,
                    ofElementsIn: \.animatableViews,
                    at: 0,
                    value: .identity
                )
                animation.addKeyframe(
                    for: \.transform,
                    ofElementsIn: \.animatableViews,
                    at: 0.5,
                    value: .init(translationX: 0, y: -self.mainView.bounds.height / 2)
                )
                animation.addKeyframe(
                    for: \.transform,
                    ofElementsIn: \.animatableViews,
                    at: 1,
                    value: .identity
                )

                var parentAnimation = Animation<View>()
                parentAnimation.addChild(animation, for: \.self, startingAt: 0, relativeDuration: 1)

                self.animationInstance = parentAnimation.perform(on: self.mainView)
            }),
        ]
    }

    // MARK: - Private Properties

    private let mainView: View = .init()

    private var animationInstance: AnimationInstance?

    // MARK: - Private Methods

    private func reset() {
        animationInstance?.cancel()
        animationInstance = nil

        mainView.animatableViews.forEach { $0.transform = .identity }
    }

}

// MARK: -

extension CollectionKeyframesViewController {

    final class View: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            animatableViews.forEach { view in
                view.bounds.size = .init(width: 40, height: 40)
                view.backgroundColor = .red
                addSubview(view)
            }
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Public Properties

        let animatableViews: [UIView] = (0..<5).map { _ in UIView() }

        var oddViews: [UIView] {
            return animatableViews
                .enumerated()
                .filter { $0.0 % 2 != 0 }
                .map { $0.1 }
        }

        // MARK: - UIView

        override func layoutSubviews() {
            for (index, view) in animatableViews.enumerated() {
                view.center = .init(
                    x: bounds.minX + 50 + (CGFloat(index) * (bounds.width - 100) / CGFloat(animatableViews.count - 1)),
                    y: bounds.height * 3 / 4
                )
            }
        }

    }

}
