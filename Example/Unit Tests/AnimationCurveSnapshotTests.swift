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

final class AnimationCurveSnapshotTests: SnapshotTestCase {

    // MARK: - Tests

    func testLinear() {
        verifyGraphView(for: LinearAnimationCurve())
    }

    func testParabolicEaseIn() {
        verifyGraphView(for: ParabolicEaseInAnimationCurve())
    }

    func testParabolicEaseOut() {
        verifyGraphView(for: ParabolicEaseOutAnimationCurve())
    }

    func testSinusoidalEaseInEaseOut() {
        verifyGraphView(for: SinusoidalEaseInEaseOutAnimationCurve())
    }

    func testCubicBezierEaseIn() {
        verifyGraphView(for: CubicBezierAnimationCurve.easeIn)
    }

    func testCubicBezierEaseOut() {
        verifyGraphView(for: CubicBezierAnimationCurve.easeOut)
    }

    func testCubicBezierEaseInEaseOut() {
        verifyGraphView(for: CubicBezierAnimationCurve.easeInEaseOut)
    }

    func testCubicBezierOvershoot() {
        verifyGraphView(for: CubicBezierAnimationCurve(controlPoints: (0.5, 0.0), (0.5, 1.3)))
    }

    // MARK: - Private Methods

    private func verifyGraphView(for curve: AnimationCurve, file: StaticString = #file, line: UInt = #line) {
        let graphSize: CGFloat = 200
        let margin: CGFloat = 20
        let containerSize = graphSize + margin * 2
        let containerView: UIView = .init(frame: .init(x: 0, y: 0, width: containerSize, height: containerSize))
        containerView.backgroundColor = .white

        let graphView: UIView = .init(frame: .init(x: margin, y: margin, width: graphSize, height: graphSize))
        let gridLayer = makeGridLayer(frame: graphView.bounds)
        graphView.layer.addSublayer(gridLayer)
        let curveLayer = makeCurveLayer(frame: graphView.bounds, curve: curve)
        graphView.layer.addSublayer(curveLayer)
        containerView.addSubview(graphView)

        FBSnapshotVerifyView(containerView, file: file, line: line)
    }

    private func makeGridLayer(frame: CGRect) -> CAShapeLayer {
        let gridLayer: CAShapeLayer = .init()
        gridLayer.strokeColor = UIColor(white: 0.9, alpha: 1).cgColor
        gridLayer.lineWidth = 1
        gridLayer.frame = frame
        ShapeLayerUtils.addGridPath(to: gridLayer, rows: 8, columns: 8)
        return gridLayer
    }

    private func makeCurveLayer(frame: CGRect, curve: AnimationCurve) -> CAShapeLayer {
        let curveLayer: CAShapeLayer = .init()
        curveLayer.strokeColor = UIColor.black.cgColor
        curveLayer.lineWidth = 2
        curveLayer.fillColor = nil
        curveLayer.frame = frame

        let path: CGMutablePath = .init()
        let height = frame.size.height
        path.move(to: CGPoint(x: 0, y: height))
        for uncurvedProgress in stride(from: 0, through: 1, by: 0.01) {
            let curvedProgress = curve.adjustedProgress(for: uncurvedProgress)
            path.addLine(
                to: CGPoint(
                    x: uncurvedProgress * Double(frame.size.width),
                    y: Double(height) - curvedProgress * Double(height)
                )
            )
        }
        curveLayer.path = path
        return curveLayer
    }

}
