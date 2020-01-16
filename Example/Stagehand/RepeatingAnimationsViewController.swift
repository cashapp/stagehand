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

final class RepeatingAnimationsViewController: DemoViewController {

    // MARK: - Life Cycle

    override init() {
        super.init()

        contentView = mainView

        animationRows = [
            ("Non-Repeating", { [unowned self] in
                // Cancel any existing animation
                self.animationInstance?.cancel(behavior: .revert)

                var animation = self.makeAnimation()
                animation.repeatStyle = .none
                self.animationInstance = animation.perform(on: self.mainView.animatableView)
            }),
            ("Repeat Once", { [unowned self] in
                // Cancel any existing animation
                self.animationInstance?.cancel(behavior: .revert)

                var animation = self.makeAnimation()
                animation.repeatStyle = .repeating(count: 2, autoreversing: false)
                self.animationInstance = animation.perform(on: self.mainView.animatableView)
            }),
            ("Repeat Once, Autoreversing", { [unowned self] in
                // Cancel any existing animation
                self.animationInstance?.cancel(behavior: .revert)

                var animation = self.makeAnimation()
                animation.repeatStyle = .repeating(count: 2, autoreversing: true)
                self.animationInstance = animation.perform(on: self.mainView.animatableView)
            }),
            ("Repeat Twice", { [unowned self] in
                // Cancel any existing animation
                self.animationInstance?.cancel(behavior: .revert)

                var animation = self.makeAnimation()
                animation.repeatStyle = .repeating(count: 3, autoreversing: false)
                self.animationInstance = animation.perform(on: self.mainView.animatableView)
            }),
            ("Repeat Twice, Autoreversing", { [unowned self] in
                // Cancel any existing animation
                self.animationInstance?.cancel(behavior: .revert)

                var animation = self.makeAnimation()
                animation.repeatStyle = .repeating(count: 3, autoreversing: true)
                self.animationInstance = animation.perform(on: self.mainView.animatableView)
            }),
            ("Repeat Infinitely", { [unowned self] in
                // Cancel any existing animation
                self.animationInstance?.cancel(behavior: .revert)

                var animation = self.makeAnimation()
                animation.repeatStyle = .infinitelyRepeating(autoreversing: false)
                self.animationInstance = animation.perform(on: self.mainView.animatableView)
            }),
            ("Repeat Infinitely, Autoreversing", { [unowned self] in
                // Cancel any existing animation
                self.animationInstance?.cancel(behavior: .revert)

                var animation = self.makeAnimation()
                animation.repeatStyle = .infinitelyRepeating(autoreversing: true)
                self.animationInstance = animation.perform(on: self.mainView.animatableView)
            }),
            ("Cancel (Revert)", { [unowned self] in
                self.animationInstance?.cancel(behavior: .revert)
                self.animationInstance = nil
            }),
            ("Cancel (Complete)", { [unowned self] in
                self.animationInstance?.cancel(behavior: .complete)
                self.animationInstance = nil
            }),
        ]
    }

    // MARK: - Private Properties

    private let mainView: View = .init()

    private var animationInstance: AnimationInstance?

    // MARK: - Private Methods

    private func makeAnimation() -> Animation<UIView> {
        var animation = Animation<UIView>()
        animation.addKeyframe(for: \.transform, at: 0, value: .identity)
        animation.addKeyframe(for: \.transform, at: 1, value: .init(translationX: mainView.bounds.width - 100, y: 0))
        animation.duration = 1
        return animation
    }

}

// MARK: -

extension RepeatingAnimationsViewController {

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
            animatableView.bounds.size = .init(width: 50, height: 50)
            animatableView.center = .init(
                x: bounds.minX + 50,
                y: bounds.height / 2
            )
        }

    }

}
