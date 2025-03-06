//
//  Copyright 2025 Block Inc.
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

final class SpringCurveViewController: DemoViewController {

    // MARK: - Life Cycle

    override init() {
        super.init()

        contentView = mainView

        contentHeight = 350

        animationRows = [
            ("Reset", { [unowned self] in
                self.reset(clearOldCurves: true)
            }),
            ("Spring (1.0 damping, 0.5 velocity)", { [unowned self] in
                self.reset()

                var animation = self.makeAnimation()
                animation.curve = SpringAnimationCurve(damping: 1, initialVelocity: 0.5)
                self.animationInstance = animation.perform(on: self.mainView.animatableView)
                self.lastCurve = animation.curve
            }),
            ("Spring (0.5 damping, 0.5 velocity)", { [unowned self] in
                self.reset()

                var animation = self.makeAnimation()
                animation.curve = SpringAnimationCurve(damping: 0.5, initialVelocity: 0.5)
                self.animationInstance = animation.perform(on: self.mainView.animatableView)
                self.lastCurve = animation.curve
            }),
            ("Spring (0.5 damping, 0 velocity)", { [unowned self] in
                self.reset()

                var animation = self.makeAnimation()
                animation.curve = SpringAnimationCurve(damping: 0.5, initialVelocity: 0)
                self.animationInstance = animation.perform(on: self.mainView.animatableView)
                self.lastCurve = animation.curve
            }),
            ("Spring (0.2 damping, 0.5 velocity)", { [unowned self] in
                self.reset()

                var animation = self.makeAnimation()
                animation.curve = SpringAnimationCurve(damping: 0.2, initialVelocity: 0.5)
                self.animationInstance = animation.perform(on: self.mainView.animatableView)
                self.lastCurve = animation.curve
            }),
            ("Spring (0.2 damping, 0.7 velocity)", { [unowned self] in
                self.reset()

                var animation = self.makeAnimation()
                animation.curve = SpringAnimationCurve(damping: 0.2, initialVelocity: 0.7)
                self.animationInstance = animation.perform(on: self.mainView.animatableView)
                self.lastCurve = animation.curve
            }),
            ("Spring (0.2 damping, 0.7 velocity, high natural freq)", { [unowned self] in
                self.reset()

                var animation = self.makeAnimation()
                animation.curve = SpringAnimationCurve(damping: 0.2, initialVelocity: 0.7, naturalFrequency: 20)
                self.animationInstance = animation.perform(on: self.mainView.animatableView)
                self.lastCurve = animation.curve
            }),
            ("Spring (0.9 damping, 1.2 velocity)", { [unowned self] in
                self.reset()

                var animation = self.makeAnimation()
                animation.curve = SpringAnimationCurve(damping: 0.9, initialVelocity: 1.2)
                self.animationInstance = animation.perform(on: self.mainView.animatableView)
                self.lastCurve = animation.curve
            }),
            ("Reverse Calculate", { [unowned self] in
                guard let curve = lastCurve else { return }
                let shapeLayerSize = Double(self.mainView.shapeLayer.bounds.width)
                let path = UIBezierPath()

                for adjustedProgress in stride(from: Double(0), through: 1, by: 0.02) {
                    for rawProgress in curve.rawProgress(for: adjustedProgress) {
                        path.addArc(
                            withCenter: .init(x: rawProgress * shapeLayerSize, y: (1 - adjustedProgress) * shapeLayerSize),
                            radius: 1,
                            startAngle: 0,
                            endAngle: 2 * .pi,
                            clockwise: true
                        )
                        path.close()
                    }
                }

                reverseCalculationPath = path
            }),
        ]
    }

    // MARK: - Private Properties

    private let mainView: View = .init()

    private var animationInstance: AnimationInstance?

    private var curvePath: UIBezierPath = .init()

    private var lastCurve: AnimationCurve?

    private var reverseCalculationPath: UIBezierPath = .init() {
        didSet {
            mainView.reverseCalculationShapeLayer.path = reverseCalculationPath.cgPath
        }
    }

    // MARK: - Private Methods

    private func makeAnimation() -> Animation<UIView> {
        var animation = Animation<UIView>()
        animation.implicitDuration = 3

        animation.addKeyframe(for: \.transform, at: 0, value: .identity)
        animation.addKeyframe(for: \.transform, at: 1, value: .init(translationX: mainView.bounds.width - 100, y: 0))

        // The animation will clamp to the values specified by the keyframes. To allow for the overshoot, we'll
        // add a keyframe past the end of the animation so that it can interpolate between the final value (at
        // a timestamp of 1) and a value past the end.
        animation.addKeyframe(
            for: \.transform,
            at: 2,
            value: .init(translationX: 2 * self.mainView.bounds.width - 200, y: 0)
        )

        animation.addPerFrameExecution { [weak self] context in
            guard let self = self else { return }

            let shapeLayerSize = Double(self.mainView.shapeLayer.bounds.width)

            self.curvePath.addLine(
                to: CGPoint(
                    x: context.uncurvedProgress * shapeLayerSize,
                    y: shapeLayerSize - context.progress * shapeLayerSize
                )
            )
            self.mainView.shapeLayer.path = self.curvePath.cgPath
        }

        return animation
    }

    private func reset(clearOldCurves: Bool = false) {
        animationInstance?.cancel()
        animationInstance = nil

        mainView.animatableView.transform = .identity

        if clearOldCurves {
            mainView.oldShapeLayer.path = nil

        } else {
            let oldPath = mainView.oldShapeLayer.path?.mutableCopy() ?? CGMutablePath()
            oldPath.addPath(curvePath.cgPath)
            mainView.oldShapeLayer.path = oldPath
        }

        curvePath = UIBezierPath()
        curvePath.move(to: CGPoint(x: 0, y: mainView.shapeLayer.bounds.height))
        mainView.shapeLayer.path = curvePath.cgPath

        reverseCalculationPath = .init()
    }

}

// MARK: -

extension SpringCurveViewController {

    final class View: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            animatableView.backgroundColor = .red
            addSubview(animatableView)

            gridLayer.fillColor = nil
            gridLayer.lineWidth = 1
            gridLayer.strokeColor = UIColor(white: 0.9, alpha: 1).cgColor
            layer.addSublayer(gridLayer)

            oldShapeLayer.fillColor = nil
            oldShapeLayer.lineWidth = 2
            oldShapeLayer.strokeColor = UIColor(white: 0.8, alpha: 1).cgColor
            layer.addSublayer(oldShapeLayer)

            shapeLayer.fillColor = nil
            shapeLayer.lineWidth = 2
            shapeLayer.strokeColor = UIColor.black.cgColor
            layer.addSublayer(shapeLayer)

            reverseCalculationShapeLayer.fillColor = UIColor.red.cgColor
            reverseCalculationShapeLayer.lineWidth = 0
            reverseCalculationShapeLayer.strokeColor = nil
            layer.addSublayer(reverseCalculationShapeLayer)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Public Properties

        let animatableView: UIView = .init()

        let gridLayer: CAShapeLayer = .init()

        let shapeLayer: CAShapeLayer = .init()

        let oldShapeLayer: CAShapeLayer = .init()

        let reverseCalculationShapeLayer: CAShapeLayer = .init()

        // MARK: - UIView

        override func layoutSubviews() {
            animatableView.bounds.size = .init(width: 50, height: 50)
            animatableView.center = .init(
                x: bounds.minX + 50,
                y: bounds.minY + 60
            )

            shapeLayer.frame = .init(
                x: bounds.midX - 100,
                y: animatableView.frame.maxY + 30,
                width: 200,
                height: 200
            )

            gridLayer.frame = shapeLayer.frame
            ShapeLayerUtils.addGridPath(to: gridLayer, rows: 10, columns: 10)

            oldShapeLayer.frame = shapeLayer.frame
            reverseCalculationShapeLayer.frame = shapeLayer.frame
        }

    }

}
