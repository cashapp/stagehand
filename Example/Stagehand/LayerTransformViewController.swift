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

import Stagehand
import UIKit

final class LayerTransformViewController: DemoViewController {

    // MARK: - Life Cycle

    override init() {
        super.init()

        contentView = mainView

        animationRows = [
            ("Reset", {
                self.animationInstance?.cancel()
                self.mainView.animatableLayer.transform = CATransform3DIdentity
            }),
            ("Identity", {
                self.animationInstance?.cancel()

                let animation = self.makeTransformAnimation(to: CATransform3DIdentity)
                self.animationInstance = animation.perform(on: self.mainView.animatableLayer)
            }),
            ("Scaled 2x2x2", {
                self.animationInstance?.cancel()

                let animation = self.makeTransformAnimation(to: CATransform3DMakeScale(2, 2, 2))
                self.animationInstance = animation.perform(on: self.mainView.animatableLayer)
            }),
            ("Scaled 3x2x2", {
                self.animationInstance?.cancel()

                let animation = self.makeTransformAnimation(to: CATransform3DMakeScale(3, 2, 2))
                self.animationInstance = animation.perform(on: self.mainView.animatableLayer)
            }),
            ("Translated 30 Right", {
                self.animationInstance?.cancel()

                let animation = self.makeTransformAnimation(to: CATransform3DMakeTranslation(30, 0, 0))
                self.animationInstance = animation.perform(on: self.mainView.animatableLayer)
            }),
            ("Translated 30 Up", {
                self.animationInstance?.cancel()

                let animation = self.makeTransformAnimation(to: CATransform3DMakeTranslation(0, -30, 0))
                self.animationInstance = animation.perform(on: self.mainView.animatableLayer)
            }),
            ("Rotated 30° Around Z-Axis", {
                self.animationInstance?.cancel()

                let animation = self.makeTransformAnimation(to: CATransform3DMakeRotation(.pi / 6, 0, 0, 1))
                self.animationInstance = animation.perform(on: self.mainView.animatableLayer)
            }),
            ("Scaled and Rotated", {
                self.animationInstance?.cancel()

                var transform = CATransform3DIdentity
                transform = CATransform3DScale(transform, 2, 2, 2)
                transform = CATransform3DRotate(transform, .pi / 6, 0, 0, 1)

                let animation = self.makeTransformAnimation(to: transform)
                self.animationInstance = animation.perform(on: self.mainView.animatableLayer)
            }),
        ]
    }

    // MARK: - Private Properties

    private let mainView: View = .init()

    private weak var animationInstance: AnimationInstance?

    // MARK: - Private Methods

    private func makeTransformAnimation(to transform: CATransform3D) -> Animation<CALayer> {
        var animation = Animation<CALayer>()
        animation.duration = 1.5

        animation.addKeyframe(for: \.transform, at: 0, relativeValue: { $0 })
        animation.addKeyframe(for: \.transform, at: 1, value: transform)

        return animation
    }

}

// MARK: -

extension LayerTransformViewController {

    fileprivate final class View: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            animatableLayer.bounds.size = .init(width: 40, height: 40)
            animatableLayer.backgroundColor = UIColor.red.cgColor
            layer.addSublayer(animatableLayer)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Public Properties

        let animatableLayer: CALayer = .init()

        // MARK: - UIView

        override func layoutSubviews() {
            animatableLayer.position = .init(x: bounds.midX, y: bounds.midY)
        }

    }

}
