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

final class ExecutionBlockViewController: DemoViewController {

    // MARK: - Life Cycle

    override init() {
        super.init()

        contentView = mainView

        animationRows = [
            ("Color Change with Haptic Feedback", { [unowned self] in
                self.reset()

                let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

                var animation = self.makeAnimation()
                animation.addExecution(
                    onForward: { view in
                        view.backgroundColor = .yellow
                        feedbackGenerator.impactOccurred()
                    },
                    onReverse: { view in
                        view.backgroundColor = .red
                        feedbackGenerator.impactOccurred()
                    },
                    at: 0.33
                )
                animation.addExecution(
                    onForward: { view in
                        view.backgroundColor = .green
                        feedbackGenerator.impactOccurred()
                    },
                    onReverse: { view in
                        view.backgroundColor = .yellow
                        feedbackGenerator.impactOccurred()
                    },
                    at: 0.66
                )
                animation.addExecution(
                    onForward: { _ in
                        feedbackGenerator.impactOccurred()
                    },
                    onReverse: { _ in
                        // No-op. Only use haptics on the forward direction, otherwise it will execute twice at the end.
                        // (once when it hits the end going forward, then immediately after when it starts the reverse
                        // animation cycle).
                    },
                    at: 1
                )
                animation.repeatStyle = .repeating(count: 2, autoreversing: true)

                feedbackGenerator.prepare()
                self.animationInstance = animation.perform(on: self.mainView.animatableView)
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
        animation.duration = 2
        return animation
    }

    private func reset() {
        animationInstance?.cancel()
        animationInstance = nil

        mainView.animatableView.transform = .identity
    }

}

// MARK: -

extension ExecutionBlockViewController {

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
