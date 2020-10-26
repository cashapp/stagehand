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

final class ChildAnimationsWithCurvesViewController: DemoViewController {

    // MARK: - Life Cycle

    override init() {
        super.init()

        contentView = mainView

        animationRows = [
            ("Reset", { [unowned self] in
                self.mainView.topView.transform = .identity
                self.mainView.bottomView.transform = .identity
            }),
            ("Linear / Ease In Ease Out", { [unowned self] in
                var animation = Animation<View>()

                var topAnimation = self.makeAnimation()
                topAnimation.curve = LinearAnimationCurve()
                animation.addChild(topAnimation, for: \View.topView, startingAt: 0, relativeDuration: 1)

                var bottomAnimation = self.makeAnimation()
                bottomAnimation.curve = SinusoidalEaseInEaseOutAnimationCurve()
                animation.addChild(bottomAnimation, for: \View.bottomView, startingAt: 0, relativeDuration: 1)

                animation.perform(on: self.mainView, duration: 2)
            }),
        ]
    }

    // MARK: - Private Properties

    private let mainView: View = .init()

    // MARK: - Private Methods

    private func makeAnimation() -> Animation<UIView> {
        var animation = Animation<UIView>()
        animation.addKeyframe(for: \.transform, at: 0, value: .identity)
        animation.addKeyframe(for: \.transform, at: 1, value: .init(translationX: mainView.bounds.width - 100, y: 0))
        return animation
    }

}

// MARK: -

extension ChildAnimationsWithCurvesViewController {

    final class View: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            topView.backgroundColor = .red
            addSubview(topView)

            bottomView.backgroundColor = .red
            addSubview(bottomView)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Public Properties

        var topView: UIView = .init()

        var bottomView: UIView = .init()

        // MARK: - UIView

        override func layoutSubviews() {
            topView.bounds.size = .init(width: 50, height: 50)
            topView.center = .init(
                x: bounds.minX + 50,
                y: bounds.height / 3
            )

            bottomView.bounds.size = .init(width: 50, height: 50)
            bottomView.center = .init(
                x: bounds.minX + 50,
                y: bounds.height * 2 / 3
            )
        }

    }

}
