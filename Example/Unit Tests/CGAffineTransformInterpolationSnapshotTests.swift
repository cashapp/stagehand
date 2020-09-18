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
import StagehandTesting

final class CGAffineTransformInterpolationSnapshotTests: SnapshotTestCase {

    // MARK: - Tests

    func testTranslation() {
        snapshotVerifyAnimation(
            transforms: [
                .init(translationX: 40, y: 0),
                .init(translationX: 40, y: 40),
                .init(translationX: 0, y: -40),
            ]
        )
    }

    func testScale() {
        snapshotVerifyAnimation(
            transforms: [
                .init(scaleX: 3, y: 1),
                .init(scaleX: 1, y: 3),
                .init(scaleX: 1, y: -2),
                .init(scaleX: 0, y: -2),
            ]
        )
    }

    func testFlippedScaleResultsInRotation() {
        snapshotVerifyAnimation(
            transforms: [
                .init(scaleX: -2, y: 3),
                .init(scaleX: 3, y: -2),
                .init(scaleX: -3, y: 2),

                CGAffineTransform(scaleX: -3, y: 2).rotated(by: -.pi / 2),
                CGAffineTransform(scaleX: 3, y: -2).rotated(by: .pi / 2),
            ]
        )
    }

    func testRotation() {
        snapshotVerifyAnimation(
            transforms: [
                .init(rotationAngle: CGFloat.pi / 4),
                .init(rotationAngle: -CGFloat.pi / 4),

                // Test that rotation across π/-π behave as expected.
                .init(rotationAngle: CGFloat.pi - 0.5),
                .init(rotationAngle: -CGFloat.pi + 0.5),
            ]
        )
    }

    func testMultipleFactorTransforms() {
        snapshotVerifyAnimation(
            transforms: [
                CGAffineTransform.identity
                    .translatedBy(x: 20, y: 40),
                CGAffineTransform.identity
                    .translatedBy(x: 20, y: 40)
                    .scaledBy(x: 3, y: 2),
                CGAffineTransform.identity
                    .translatedBy(x: 20, y: 40)
                    .rotated(by: .pi / 4)
                    .scaledBy(x: 3, y: 2),
                CGAffineTransform.identity
                    .translatedBy(x: -20, y: -40)
                    .rotated(by: .pi / 4)
                    .scaledBy(x: 3, y: 2),
            ]
        )
    }

    func testSkewedTransforms() {
        var positiveSkewTransform = CGAffineTransform.identity
        positiveSkewTransform.c = 4

        var negativeSkewTransform = CGAffineTransform.identity
        negativeSkewTransform.c = -4

        snapshotVerifyAnimation(
            transforms: [
                positiveSkewTransform,
                negativeSkewTransform,
                negativeSkewTransform.scaledBy(x: 2, y: 2),
            ]
        )
    }

    func testTranslatingSkewedTransforms() {
        var skewTransform = CGAffineTransform.identity
        skewTransform.c = 2

        snapshotVerifyAnimation(
            transforms: [
                skewTransform.translatedBy(x: -5, y: -20),
                skewTransform.translatedBy(x: 20, y: 10),
            ]
        )
    }

    // MARK: - Private Methods

    private func snapshotVerifyAnimation(
        transforms: [CGAffineTransform],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let containerView = ContainerView(frame: .init(x: 0, y: 0, width: 150, height: 150))
        containerView.transforms = transforms

        var animation = Animation<UIView>()
        animation.addKeyframe(for: \.transform, at: 0, value: .identity)

        let segmentDuration = 1 / Double(transforms.count)
        for (index, transform) in transforms.enumerated() {
            animation.addKeyframe(for: \.transform, at: Double(index + 1) * segmentDuration, value: transform)
        }

        animation.duration = TimeInterval(transforms.count)

        SnapshotVerify(
            animation: animation,
            on: containerView.animatableView,
            using: containerView,
            fps: 10,
            file: file,
            line: line
        )
    }

}

// MARK: -

private final class ContainerView: UIView {

    // MARK: - Life Cycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        gridLayer.fillColor = nil
        gridLayer.lineWidth = 0.5
        gridLayer.strokeColor = UIColor.lightGray.cgColor
        layer.addSublayer(gridLayer)

        animatableView.backgroundColor = .red
        animatableView.bounds.size = .init(width: 20, height: 20)
        addSubview(animatableView)

        backgroundColor = .white
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Properties

    let animatableView: QuadrantView = .init()

    var transforms: [CGAffineTransform] {
        get {
            return transformViews.map { $0.transform }
        }
        set {
            transformViews = newValue.map { transform in
                let view = UIView(frame: .init(x: 0, y: 0, width: 20, height: 20))
                view.backgroundColor = .lightGray
                view.alpha = 0.5
                view.transform = transform
                return view
            }
        }
    }

    // MARK: - Private Properties

    private var transformViews: [UIView] = [] {
        didSet {
            oldValue.forEach { $0.removeFromSuperview() }
            transformViews.forEach { insertSubview($0, belowSubview: animatableView) }
        }
    }

    private let gridLayer: CAShapeLayer = .init()

    // MARK: - UIView

    override func layoutSubviews() {
        let centerPoint = CGPoint(x: bounds.midX, y: bounds.midY)
        animatableView.center = centerPoint
        transformViews.forEach { $0.center = centerPoint }

        gridLayer.frame = bounds
        updateGrid()
    }

    // MARK: - Private Methods

    private func updateGrid() {
        let gridPath = UIBezierPath()
        let gridSize: CGFloat = 10

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
