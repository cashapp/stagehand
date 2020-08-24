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

final class PropertyAssignmentViewController: DemoViewController {

    // MARK: - Life Cycle

    override init() {
        super.init()

        contentView = mainView

        animationRows = [
            ("Reset", { [unowned self] in
                self.reset()
            }),
            ("Current -> Yellow -> Green", { [unowned self] in
                var animation = self.makeAnimation()
                animation.addAssignment(for: \.backgroundColor, at: 0.33, value: .yellow)
                animation.addAssignment(for: \.backgroundColor, at: 0.66, value: .green)

                self.mainView.initialColorSlider.isEnabled = false
                self.animationInstance = animation.perform(
                    on: self.mainView.animatableView,
                    completion: { [weak self] _ in
                        self?.mainView.initialColorSlider.isEnabled = true
                    }
                )
            }),
            ("Assignment in Child Animation", { [unowned self] in
                var childAnimation = self.makeAnimation()
                childAnimation.addAssignment(for: \.backgroundColor, at: 0.33, value: .yellow)
                childAnimation.addAssignment(for: \.backgroundColor, at: 0.66, value: .green)

                var animation = Animation<View>()
                animation.addChild(childAnimation, for: \.animatableView, startingAt: 0, relativeDuration: 1)

                self.animationInstance = animation.perform(on: self.mainView, duration: 2)
            }),
            ("Current -> Yellow -> Green, with reversal", { [unowned self] in
                var animation = self.makeAnimation()
                animation.addAssignment(for: \.backgroundColor, at: 0.33, value: .yellow)
                animation.addAssignment(for: \.backgroundColor, at: 0.66, value: .green)

                self.mainView.initialColorSlider.isEnabled = false
                self.animationInstance = animation.perform(
                    on: self.mainView.animatableView,
                    repeatStyle: .repeating(count: 2, autoreversing: true),
                    completion: { [weak self] _ in
                        self?.mainView.initialColorSlider.isEnabled = true
                }
                )
            }),
        ]

        mainView.initialColorSlider.addTarget(self, action: #selector(updateInitialColor), for: .valueChanged)
    }

    // MARK: - Private Properties

    private let mainView: View = .init()

    private var animationInstance: AnimationInstance?

    // MARK: - Private Methods

    private func makeAnimation() -> Animation<UIView> {
        var animation = Animation<UIView>()
        animation.addKeyframe(for: \.transform, at: 0, value: .identity)
        animation.addKeyframe(for: \.transform, at: 1, value: .init(translationX: mainView.bounds.width - 100, y: 0))
        animation.implicitDuration = 2
        return animation
    }

    private func reset() {
        animationInstance?.cancel()
        animationInstance = nil

        mainView.animatableView.transform = .identity
        updateInitialColor()
    }

    @objc func updateInitialColor() {
        mainView.animatableView.backgroundColor = UIColor(
            hue: CGFloat(mainView.initialColorSlider.value),
            saturation: 1,
            brightness: 1,
            alpha: 1
        )
    }

}

// MARK: -

extension PropertyAssignmentViewController {

    final class View: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            animatableView.backgroundColor = .red
            addSubview(animatableView)

            addSubview(initialColorSlider)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Public Properties

        var animatableView: UIView = .init()

        let initialColorSlider: UISlider = .init()

        // MARK: - UIView

        override func layoutSubviews() {
            animatableView.bounds.size = .init(width: 50, height: 50)
            animatableView.center = .init(
                x: bounds.minX + 50,
                y: bounds.minY + 60
            )

            initialColorSlider.bounds.size = initialColorSlider.sizeThatFits(bounds.insetBy(dx: 24, dy: 0).size)
            initialColorSlider.frame.origin = .init(
                x: 24,
                y: animatableView.bounds.maxY + 60
            )
        }

    }

}
