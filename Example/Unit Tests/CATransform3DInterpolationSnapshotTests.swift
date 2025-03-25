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
import StagehandTesting

@MainActor
final class CATransform3DInterpolationSnapshotTests: SnapshotTestCase {

    // MARK: - Tests

    func testScale() {
        snapshotVerifyAnimation(
            transforms: [
                CATransform3DMakeScale(3, 1, 1),
                CATransform3DMakeScale(1, 3, 1),
            ]
        )
    }

    func testRotation() {
        snapshotVerifyAnimation(
            transforms: [
                CATransform3DMakeRotation(.pi / 4, 0, 0, 1),
                CATransform3DMakeRotation(.pi / 4, 0, 1, 0),
                CATransform3DMakeRotation(.pi / 4, 0, 1, 1),
            ]
        )
    }

    func testRotationAcrossBoundary() {
        snapshotVerifyAnimation(
            transforms: [
                CATransform3DMakeRotation(.pi - 0.5, 0, 0, 1),
                CATransform3DMakeRotation(-.pi + 0.5, 0, 0, 1),
            ]
        )
    }

    func testScaleAndRotation() {
        snapshotVerifyAnimation(
            transforms: [
                CATransform3DIdentity
                    .scaledBy(x: 2, y: 2)
                    .rotatedBy(angle: .pi / 4, x: 0, y: 0, z: 1),
                CATransform3DIdentity
                    .scaledBy(x: 0.5, y: 0.5)
                    .rotatedBy(angle: -.pi / 4, x: 0, y: 0, z: 1),
                CATransform3DIdentity
                    .rotatedBy(angle: .pi / 3, x: 0, y: 1, z: 0),
            ]
        )
    }

    func testScaleAndRotationWithPerspective() {
        let perspectiveTransform = CATransform3DIdentity.withPerspective(eyePosition: 20)

        snapshotVerifyAnimation(
            transforms: [
                perspectiveTransform
                    .scaledBy(x: 2, y: 2)
                    .rotatedBy(angle: .pi / 4, x: 0, y: 0, z: 1),
                perspectiveTransform
                    .scaledBy(x: 0.5, y: 0.5)
                    .rotatedBy(angle: -.pi / 4, x: 0, y: 0, z: 1),
                perspectiveTransform
                    .rotatedBy(angle: .pi / 3, x: 0, y: 1, z: 0),
                perspectiveTransform
                    .scaledBy(x: 2, y: 3)
                    .rotatedBy(angle: -.pi / 3, x: 0, y: 1, z: 1),
            ]
        )
    }

    func testPerspective() {
        snapshotVerifyAnimation(
            transforms: [
                CATransform3DIdentity
                    .scaledBy(x: 2, y: 2)
                    .rotatedBy(angle: .pi / 3, x: 0, y: 1, z: 0),
                CATransform3DIdentity
                    .withPerspective(eyePosition: 20)
                    .scaledBy(x: 2, y: 2)
                    .rotatedBy(angle: .pi / 3, x: 0, y: 1, z: 0),
                CATransform3DIdentity
                    .withPerspective(eyePosition: -20)
                    .scaledBy(x: 2, y: 2)
                    .rotatedBy(angle: .pi / 3, x: 0, y: 1, z: 0),
            ]
        )
    }

    func testShear() {
        snapshotVerifyAnimation(
            transforms: [
                CATransform3DIdentity.shearedBy(xy: 2),
                CATransform3DIdentity.shearedBy(xy: -2),
                CATransform3DIdentity,
                CATransform3DIdentity.shearedBy(yx: 2),
                CATransform3DIdentity,
                CATransform3DIdentity.shearedBy(xy: 0.5, yx: 0.5),
                CATransform3DIdentity.shearedBy(xy: -0.5),
            ]
        )
    }

    func testZeroScale() {
        snapshotVerifyAnimation(
            transforms: [
                CATransform3DIdentity
                    .scaledBy(x: 0),
                CATransform3DIdentity
                    .scaledBy(x: 2, y: 2)
                    .rotatedBy(angle: .pi / 4, x: 1, y: 1, z: 1),
                CATransform3DIdentity
                    .scaledBy(y: 0)
                    .rotatedBy(angle: .pi / 4, x: 1, y: 1, z: 1),
            ]
        )
    }

    // MARK: - Private Methods

    private func snapshotVerifyAnimation(
        transforms: [CATransform3D],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let containerView = ContainerView(frame: .init(x: 0, y: 0, width: 150, height: 150))
        containerView.transforms = transforms

        var animation = Animation<UIView>()
        animation.addKeyframe(for: \.layer.transform, at: 0, value: CATransform3DIdentity)

        let segmentDuration = 1 / Double(transforms.count)
        for (index, transform) in transforms.enumerated() {
            animation.addKeyframe(for: \.layer.transform, at: Double(index + 1) * segmentDuration, value: transform)
        }

        animation.implicitDuration = TimeInterval(transforms.count)

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

    var transforms: [CATransform3D] {
        get {
            return transformViews.map { $0.layer.transform }
        }
        set {
            transformViews = newValue.map { transform in
                let view = UIView(frame: .init(x: 0, y: 0, width: 20, height: 20))
                view.backgroundColor = .lightGray
                view.alpha = 0.5
                view.layer.transform = transform
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
