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

final class AnimationQueueViewController: DemoViewController {

    // MARK: - Life Cycle

    override init() {
        self.animationQueue = AnimationQueue(element: mainView)

        super.init()

        contentView = mainView
        contentHeight = 300

        animationRows = [
            ("Cancel Pending Animations", { [unowned self] in
                self.animationQueue.cancelPendingAnimations()
            }),
            ("Enqueue Move to Center", { [unowned self] in
                let animation = self.makeTranslationAnimation(x: 0, y: 0)
                self.animationQueue.enqueue(animation: animation)
            }),
            ("Enqueue Move to Top Left", { [unowned self] in
                let animation = self.makeTranslationAnimation(x: -100, y: -100)
                self.animationQueue.enqueue(animation: animation)
            }),
            ("Enqueue Move to Top Right", { [unowned self] in
                let animation = self.makeTranslationAnimation(x: 100, y: -100)
                self.animationQueue.enqueue(animation: animation)
            }),
            ("Enqueue Move to Bottom Left", { [unowned self] in
                let animation = self.makeTranslationAnimation(x: -100, y: 100)
                self.animationQueue.enqueue(animation: animation)
            }),
            ("Enqueue Move to Bottom Right", { [unowned self] in
                let animation = self.makeTranslationAnimation(x: 100, y: 100)
                self.animationQueue.enqueue(animation: animation)
            }),
            ("Pause Queue Before Next Animation", { [unowned self] in
                self.animationQueue.pauseBeforeNextAnimation()
            }),
            ("Resume Queue", { [unowned self] in
                self.animationQueue.resume()
            }),
            ("Halt In Progress Animation", { [unowned self] in
                self.animationQueue.cancelInProgressAnimation(behavior: .halt)
            }),
        ]
    }

    // MARK: - Private Properties

    private let mainView: View = .init()

    private let animationQueue: AnimationQueue<View>

    // MARK: - Private Methods

    private func makeTranslationAnimation(x: CGFloat, y: CGFloat) -> Animation<View> {
        var animation = Animation<View>()
        animation.implicitDuration = 2

        animation.addKeyframe(for: \.animatableView.transform, at: 0, relativeValue: { $0 })
        animation.addKeyframe(for: \.animatableView.transform, at: 1, value: .init(translationX: x, y: y))

        return animation
    }

}

// MARK: -

extension AnimationQueueViewController {

    final class View: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            animatableView.bounds.size = .init(width: 40, height: 40)
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
            animatableView.center = .init(
                x: (bounds.maxX - bounds.minX) / 2,
                y: (bounds.maxY - bounds.minY) / 2
            )
        }

    }

}
