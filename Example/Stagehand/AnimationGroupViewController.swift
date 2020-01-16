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

final class AnimationGroupViewController: DemoViewController {

    // MARK: - Life Cycle

    override init() {
        super.init()

        contentView = View(topView: topView, bottomView: bottomView)

        animationRows = [
            ("Move Both Views", { [unowned self] in
                var animationGroup = AnimationGroup()
                animationGroup.duration = 2

                let topAnimation = self.makeAnimation()
                animationGroup.addAnimation(topAnimation, for: self.topView, startingAt: 0, relativeDuration: 0.75)

                let bottomAnimation = self.makeAnimation()
                animationGroup.addAnimation(bottomAnimation, for: self.bottomView, startingAt: 0.25, relativeDuration: 0.75)

                animationGroup.perform()
            }),
        ]
    }

    // MARK: - Private Properties

    private let topView: UIView = .init()

    private let bottomView: UIView = .init()

    // MARK: - Private Methods

    private func makeAnimation() -> Animation<UIView> {
        var animation = Animation<UIView>()
        animation.addKeyframe(for: \.transform, at: 0, value: .identity)
        animation.addKeyframe(for: \.transform, at: 1, value: .init(translationX: contentView.bounds.width - 100, y: 0))
        animation.duration = 2
        return animation
    }

}

// MARK: -

extension AnimationGroupViewController {

    final class View: UIView {

        // MARK: - Life Cycle

        init(topView: UIView, bottomView: UIView) {
            self.topView = topView
            self.bottomView = bottomView

            super.init(frame: .zero)

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

        let topView: UIView

        let bottomView: UIView

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
