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

final class InteractiveAnimationViewController: DemoViewController {

    // MARK: - Life Cycle

    override init() {
        super.init()

        contentView = mainView

        animationRows = [
            ("Animate to Beginning (Linear)", { [unowned self] in
                let animationInstance = self.createAnimationInstanceIfNeeded()
                animationInstance.animateToBeginning()
            }),
            ("Animate to End (Linear)", { [unowned self] in
                let animationInstance = self.createAnimationInstanceIfNeeded()
                animationInstance.animateToEnd()
            }),
            ("Cancel (Halt)", { [unowned self] in
                self.animationInstance?.cancel()
            }),
            ("Use Linear Curve", { [unowned self] in
                self.animationCurve = LinearAnimationCurve()
                self.animationInstance?.cancel()
                self.animationInstance = self.makeAnimation().performInteractive(on: self.mainView.animatableView)
            }),
            ("Use Easing Curve", { [unowned self] in
                self.animationCurve = CubicBezierAnimationCurve.easeInEaseOut
                self.animationInstance?.cancel()
                self.animationInstance = self.makeAnimation().performInteractive(on: self.mainView.animatableView)
            }),
        ]

        mainView.progressSlider.addTarget(self, action: #selector(progressUpdateDidBegin), for: .touchDown)
        mainView.progressSlider.addTarget(self, action: #selector(progressValueChanged), for: .valueChanged)
        mainView.progressSlider.addTarget(self, action: #selector(progressUpdateDidEnd), for: .touchUpInside)
        mainView.progressSlider.addTarget(self, action: #selector(progressUpdateDidEnd), for: .touchUpOutside)
        mainView.progressSlider.addTarget(self, action: #selector(progressUpdateDidEnd), for: .touchCancel)
    }

    // MARK: - Private Properties

    private var mainView: View = .init()

    private weak var animationInstance: InteractiveAnimationInstance?

    private var animationCurve: AnimationCurve = LinearAnimationCurve()

    // MARK: - Private Methods

    private func makeAnimation() -> Animation<UIView> {
        var animation = Animation<UIView>()
        animation.addKeyframe(
            for: \.transform,
            at: 0,
            value: .identity
        )
        animation.addKeyframe(
            for: \.transform,
            at: 0.5,
            value: CGAffineTransform.identity
                .translatedBy(x: (mainView.bounds.width - 100) / 2, y: 0)
                .rotated(by: .pi / 4)
        )
        animation.addKeyframe(
            for: \.transform,
            at: 1,
            value: CGAffineTransform.identity
                .translatedBy(x: mainView.bounds.width - 100, y: 0)
                .rotated(by: .pi / 2)
        )
        animation.implicitDuration = 2.5
        animation.curve = animationCurve

        animation.addPerFrameExecution { context in
            self.mainView.progressSlider.value = Float(context.uncurvedProgress)
        }

        return animation
    }

    @discardableResult
    private func createAnimationInstanceIfNeeded() -> InteractiveAnimationInstance {
        if let existingInstance = animationInstance {
            return existingInstance
        }

        let animationInstance = makeAnimation().performInteractive(on: mainView.animatableView)
        self.animationInstance = animationInstance
        return animationInstance
    }

    @objc private func progressUpdateDidBegin() {
        createAnimationInstanceIfNeeded()
    }

    @objc private func progressValueChanged() {
        let slider = mainView.progressSlider
        let progress = Double((slider.value - slider.minimumValue) / (slider.maximumValue - slider.minimumValue))
        animationInstance?.updateProgress(to: progress)
    }

    @objc private func progressUpdateDidEnd() {
        let slider = mainView.progressSlider
        let progress = Double((slider.value - slider.minimumValue) / (slider.maximumValue - slider.minimumValue))

        if progress < 0.5 {
            animationInstance?.animateToBeginning(using: CubicBezierAnimationCurve.easeInEaseOut)
        } else {
            animationInstance?.animateToEnd(using: CubicBezierAnimationCurve.easeInEaseOut)
        }
    }

}

// MARK: -

extension InteractiveAnimationViewController {

    final class View: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            animatableView.backgroundColor = .red
            addSubview(animatableView)

            addSubview(progressSlider)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Public Properties

        var animatableView: UIView = .init()

        let progressSlider: UISlider = .init()

        // MARK: - UIView

        override func layoutSubviews() {
            animatableView.bounds.size = .init(width: 50, height: 50)
            animatableView.center = .init(
                x: bounds.minX + 50,
                y: bounds.minY + 60
            )

            progressSlider.bounds.size = progressSlider.sizeThatFits(bounds.insetBy(dx: 24, dy: 0).size)
            progressSlider.frame.origin = .init(
                x: 24,
                y: animatableView.bounds.maxY + 60
            )
        }

    }

}
