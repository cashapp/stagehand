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

import UIKit

final class CGAffineTransformDebuggingViewController: DemoViewController {

    // MARK: - Life Cycle

    override init() {
        super.init()

        contentView = mainView
        contentHeight = 500

        animationRows = [
            ("Identity", {
                self.mainView.containerView.animatableView.transform = .identity
                self.updateSliders()
            }),
            ("Rotate 45º", {
                self.mainView.containerView.animatableView.transform = CGAffineTransform.identity
                    .rotated(by: .pi / 4)
                self.updateSliders()
            }),
            ("Scale 3x2", {
                self.mainView.containerView.animatableView.transform = CGAffineTransform.identity
                    .scaledBy(x: 3, y: 2)
                self.updateSliders()
            }),
            ("Scale -3x2", {
                self.mainView.containerView.animatableView.transform = CGAffineTransform.identity
                    .scaledBy(x: -3, y: 2)
                self.updateSliders()
            }),
            ("Scale -3x-2", {
                self.mainView.containerView.animatableView.transform = CGAffineTransform.identity
                    .scaledBy(x: -3, y: -2)
                self.updateSliders()
            }),
            ("Scale 3x2, Rotate 180º", {
                self.mainView.containerView.animatableView.transform = CGAffineTransform.identity
                    .scaledBy(x: 3, y: 2)
                    .rotated(by: .pi)
                self.updateSliders()
            }),
            ("Translate by 10,20", {
                let transform = self.mainView.containerView.animatableView.transform
                self.mainView.containerView.animatableView.transform = transform.translatedBy(x: 10, y: 20)
                self.updateSliders()
            }),
            ("Scale by 3x2", {
                let transform = self.mainView.containerView.animatableView.transform
                self.mainView.containerView.animatableView.transform = transform.scaledBy(x: 3, y: 2)
                self.updateSliders()
            }),
        ]

        mainView.transformAControl.slider.addTarget(self, action: #selector(updateTransform), for: .valueChanged)
        mainView.transformBControl.slider.addTarget(self, action: #selector(updateTransform), for: .valueChanged)
        mainView.transformCControl.slider.addTarget(self, action: #selector(updateTransform), for: .valueChanged)
        mainView.transformDControl.slider.addTarget(self, action: #selector(updateTransform), for: .valueChanged)
        mainView.transformTXControl.slider.addTarget(self, action: #selector(updateTransform), for: .valueChanged)
        mainView.transformTYControl.slider.addTarget(self, action: #selector(updateTransform), for: .valueChanged)

        updateSliders()
    }

    // MARK: - Private Properties

    private let mainView: View = .init()

    // MARK: - Private Methods

    @objc private func updateTransform() {
        mainView.containerView.animatableView.transform = .init(
            a: CGFloat(mainView.transformAControl.slider.value),
            b: CGFloat(mainView.transformBControl.slider.value),
            c: CGFloat(mainView.transformCControl.slider.value),
            d: CGFloat(mainView.transformDControl.slider.value),
            tx: CGFloat(mainView.transformTXControl.slider.value),
            ty: CGFloat(mainView.transformTYControl.slider.value)
        )

        updateSliders()
    }

    private func updateSliders() {
        let transform = mainView.containerView.animatableView.transform

        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2

        mainView.transformAControl.slider.value = Float(transform.a)
        mainView.transformAControl.valueLabel.text = formatter.string(for: transform.a)

        mainView.transformBControl.slider.value = Float(transform.b)
        mainView.transformBControl.valueLabel.text = formatter.string(for: transform.b)

        mainView.transformCControl.slider.value = Float(transform.c)
        mainView.transformCControl.valueLabel.text = formatter.string(for: transform.c)

        mainView.transformDControl.slider.value = Float(transform.d)
        mainView.transformDControl.valueLabel.text = formatter.string(for: transform.d)

        mainView.transformTXControl.slider.value = Float(transform.tx)
        mainView.transformTXControl.valueLabel.text = formatter.string(for: transform.tx)

        mainView.transformTYControl.slider.value = Float(transform.ty)
        mainView.transformTYControl.valueLabel.text = formatter.string(for: transform.ty)
    }

}

// MARK: -

extension CGAffineTransformDebuggingViewController {

    fileprivate final class View: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            addSubview(containerView)

            transformAControl.label.text = "A"
            transformAControl.slider.minimumValue = -5
            transformAControl.slider.maximumValue = 5
            addSubview(transformAControl)

            transformBControl.label.text = "B"
            transformBControl.slider.minimumValue = -5
            transformBControl.slider.maximumValue = 5
            addSubview(transformBControl)

            transformCControl.label.text = "C"
            transformCControl.slider.minimumValue = -5
            transformCControl.slider.maximumValue = 5
            addSubview(transformCControl)

            transformDControl.label.text = "D"
            transformDControl.slider.minimumValue = -5
            transformDControl.slider.maximumValue = 5
            addSubview(transformDControl)

            transformTXControl.label.text = "Tx"
            transformTXControl.slider.minimumValue = -100
            transformTXControl.slider.maximumValue = 100
            addSubview(transformTXControl)

            transformTYControl.label.text = "Ty"
            transformTYControl.slider.minimumValue = -100
            transformTYControl.slider.maximumValue = 100
            addSubview(transformTYControl)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Public Properties

        let containerView: ContainerView = .init()

        let transformAControl: ControlView = .init()
        let transformBControl: ControlView = .init()
        let transformCControl: ControlView = .init()
        let transformDControl: ControlView = .init()
        let transformTXControl: ControlView = .init()
        let transformTYControl: ControlView = .init()

        // MARK: - UIView

        override func layoutSubviews() {
            containerView.frame = .init(x: bounds.minX, y: bounds.minY, width: bounds.width, height: 250)

            let controls = [
                transformAControl,
                transformBControl,
                transformCControl,
                transformDControl,
                transformTXControl,
                transformTYControl,
            ]

            controls.forEach { $0.bounds.size = $0.sizeThatFits(bounds.insetBy(dx: 16, dy: 0).size) }

            let heightToFill = bounds.height - containerView.frame.maxY
            let yLayoutDelta = (heightToFill / CGFloat(controls.count + 1))

            for (index, control) in controls.enumerated() {
                control.center = .init(
                    x: bounds.midX,
                    y: containerView.frame.maxY + yLayoutDelta * CGFloat(index + 1)
                )
            }
        }

    }

    fileprivate final class ContainerView: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            gridLayer.fillColor = nil
            gridLayer.lineWidth = 0.5
            gridLayer.strokeColor = UIColor.lightGray.cgColor
            layer.addSublayer(gridLayer)

            // Set an arbitrary string that is both vertically and horizontally asymmetric.
            animatableView.text = "2"

            animatableView.backgroundColor = .red
            animatableView.textColor = .white
            animatableView.textAlignment = .center
            animatableView.font = .boldSystemFont(ofSize: 16)
            animatableView.bounds.size = .init(width: 40, height: 40)
            addSubview(animatableView)

            backgroundColor = .white
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Public Properties

        let animatableView: UILabel = .init()

        // MARK: - Private Properties

        private let gridLayer: CAShapeLayer = .init()

        // MARK: - UIView

        override func layoutSubviews() {
            animatableView.center = .init(x: bounds.midX, y: bounds.midY)

            gridLayer.frame = bounds
            updateGrid()
        }

        // MARK: - Private Methods

        private func updateGrid() {
            let gridPath = UIBezierPath()
            let gridSize: CGFloat = 20

            // Add verical grid lines.
            for x in stride(from: bounds.midX, to: bounds.maxX, by: gridSize) {
                gridPath.move(to: .init(x: x, y: bounds.minY))
                gridPath.addLine(to: .init(x: x, y: bounds.maxY))
            }
            for x in stride(from: bounds.midX, to: bounds.minX, by: -gridSize) {
                gridPath.move(to: .init(x: x, y: bounds.minY))
                gridPath.addLine(to: .init(x: x, y: bounds.maxY))
            }

            // Add horizontal grid lines.
            for y in stride(from: bounds.midY, to: bounds.maxY, by: gridSize) {
                gridPath.move(to: .init(x: bounds.minX, y: y))
                gridPath.addLine(to: .init(x: bounds.maxX, y: y))
            }
            for y in stride(from: bounds.midY, to: bounds.minY, by: -gridSize) {
                gridPath.move(to: .init(x: bounds.minX, y: y))
                gridPath.addLine(to: .init(x: bounds.maxX, y: y))
            }

            gridLayer.path = gridPath.cgPath
        }

    }

    fileprivate final class ControlView: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            addSubview(label)
            addSubview(slider)

            valueLabel.textAlignment = .right
            addSubview(valueLabel)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Public Properties

        let label: UILabel = .init()

        let valueLabel: UILabel = .init()

        let slider: UISlider = .init()

        // MARK: - UIView

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            return .init(width: size.width, height: slider.sizeThatFits(size).height)
        }

        override func layoutSubviews() {
            label.sizeToFit()
            label.center = .init(x: bounds.minX + (label.bounds.width / 2), y: bounds.midY)

            valueLabel.frame = bounds

            slider.frame = .init(
                x: 24,
                y: 1,
                width: bounds.width - 90,
                height: bounds.height
            )
        }

    }

}
