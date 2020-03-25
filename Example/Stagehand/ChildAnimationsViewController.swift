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
import UIKit

final class ChildAnimationsViewController: DemoViewController {

    // MARK: - Life Cycle

    override init() {
        super.init()

        contentView = mainView

        animationRows = [
            ("Left to Right", { [unowned self] in
                var animation = Animation<View>()
                animation.addChild(
                    AnimationFactory.makeFadeOutAnimation(),
                    for: \View.leftView,
                    startingAt: 0,
                    relativeDuration: 0.5
                )
                animation.addChild(
                    AnimationFactory.makeFadeInAnimation(),
                    for: \View.rightView,
                    startingAt: 0.5,
                    relativeDuration: 0.5
                )
                animation.perform(on: self.mainView)
            }),
            ("Right to Left", { [unowned self] in
                var animation = Animation<View>()
                animation.addChild(
                    AnimationFactory.makeFadeOutAnimation(),
                    for: \View.rightView,
                    startingAt: 0,
                    relativeDuration: 0.5
                )
                animation.addChild(
                    AnimationFactory.makeFadeInAnimation(),
                    for: \View.leftView,
                    startingAt: 0.5,
                    relativeDuration: 0.5
                )
                animation.perform(on: self.mainView)
            }),
            ("Swap", { [unowned self] in
                var animation = Animation<View>()

                var invertAlphaAnimation = Animation<UIView>()
                invertAlphaAnimation.addKeyframe(for: \.alpha, at: 0, relativeValue: { $0 })
                invertAlphaAnimation.addKeyframe(for: \.alpha, at: 1, relativeValue: { 1 - $0 })

                let startWithLeftView = self.mainView.leftView.alpha > self.mainView.rightView.alpha

                animation.addChild(
                    invertAlphaAnimation,
                    for: startWithLeftView ? \View.leftView : \View.rightView,
                    startingAt: 0,
                    relativeDuration: 0.75
                )
                animation.addChild(
                    invertAlphaAnimation,
                    for: startWithLeftView ? \View.rightView : \View.leftView,
                    startingAt: 0.25,
                    relativeDuration: 0.75
                )
                animation.perform(on: self.mainView)
            }),
            ("Rotate and Fade", { [unowned self] in
                var childAnimation = Animation<UIView>()

                var rotateAnimation = Animation<UIView>()
                rotateAnimation.addKeyframe(for: \.transform, at: 0.00, value: .identity)
                rotateAnimation.addKeyframe(for: \.transform, at: 0.25, value: .init(rotationAngle: .pi / 2))
                rotateAnimation.addKeyframe(for: \.transform, at: 0.50, value: .init(rotationAngle: .pi))
                rotateAnimation.addKeyframe(for: \.transform, at: 0.75, value: .init(rotationAngle: 3 * .pi / 2))
                rotateAnimation.addKeyframe(for: \.transform, at: 1.00, value: .init(rotationAngle: 2 * .pi))

                var alphaAnimation = Animation<UIView>()
                alphaAnimation.addKeyframe(for: \.alpha, at: 0, relativeValue: { $0 })
                alphaAnimation.addKeyframe(for: \.alpha, at: 0.5, value: 1.0)
                alphaAnimation.addKeyframe(for: \.alpha, at: 1, relativeValue: { $0 })

                childAnimation.addChild(rotateAnimation, for: \.self, startingAt: 0, relativeDuration: 1)
                childAnimation.addChild(alphaAnimation, for: \.self, startingAt: 0, relativeDuration: 1)

                var animation = Animation<View>()
                animation.addChild(childAnimation, for: \.leftView, startingAt: 0, relativeDuration: 1)
                animation.addChild(childAnimation, for: \.rightView, startingAt: 0, relativeDuration: 1)

                animation.perform(on: self.mainView)
            }),
            ("Fade Out, then Fade In", { [unowned self] in
                var fadeOutAnimation = Animation<UIView>()
                fadeOutAnimation.addKeyframe(for: \.alpha, at: 0, value: 1)
                fadeOutAnimation.addKeyframe(for: \.alpha, at: 1, value: 0.25)

                var fadeInAnimation = Animation<UIView>()
                fadeInAnimation.addKeyframe(for: \.alpha, at: 0, value: 0.25)
                fadeInAnimation.addKeyframe(for: \.alpha, at: 1, value: 1)

                var animation = Animation<UIView>()
                animation.addChild(fadeOutAnimation, for: \.self, startingAt: 0, relativeDuration: 0.5)
                animation.addChild(fadeInAnimation, for: \.self, startingAt: 0.5, relativeDuration: 0.5)

                animation.duration = 2

                animation.perform(on: self.mainView)
            }),
        ]
    }

    // MARK: - Private Properties

    private let mainView: View = .init()

}

// MARK: -

extension ChildAnimationsViewController {

    final class View: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            leftView.backgroundColor = .red
            addSubview(leftView)

            rightView.backgroundColor = .blue
            rightView.alpha = 0
            addSubview(rightView)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Public Properties

        let leftView: UIView = .init()

        let rightView: UIView = .init()

        // MARK: - UIView

        override func layoutSubviews() {
            leftView.bounds.size = .init(width: 50, height: 50)
            leftView.center = .init(
                x: bounds.width / 3,
                y: bounds.height / 2
            )

            rightView.bounds.size = .init(width: 50, height: 50)
            rightView.center = .init(
                x: bounds.width * 2 / 3,
                y: bounds.height / 2
            )
        }

    }

}
