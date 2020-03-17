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

final class ChildAnimationProgressViewController: DemoViewController {

    // MARK: - Life Cycle

    override init() {
        super.init()

        contentView = mainView
        contentHeight = 260

        animationRows = [
            ("Per-Frame in Linear / Linear", { [unowned self] in
                self.reset()

                let animation = self.makeAnimation(
                    parentCurve: LinearAnimationCurve(),
                    childCurve: LinearAnimationCurve(),
                    trackKeyframes: false
                )

                self.animationInstance = animation.perform(on: self.element)
            }),
            ("Per-Frame in Linear / Ease In Out", { [unowned self] in
                self.reset()

                let animation = self.makeAnimation(
                    parentCurve: LinearAnimationCurve(),
                    childCurve: SinusoidalEaseInEaseOutAnimationCurve(),
                    trackKeyframes: false
                )

                self.animationInstance = animation.perform(on: self.element)
            }),
            ("Per-Frame in Ease In Out / Ease In Out", { [unowned self] in
                self.reset()

                let animation = self.makeAnimation(
                    parentCurve: SinusoidalEaseInEaseOutAnimationCurve(),
                    childCurve: SinusoidalEaseInEaseOutAnimationCurve(),
                    trackKeyframes: false
                )

                self.animationInstance = animation.perform(on: self.element)
            }),
            ("Per-Frame in Ease In / Linear", { [unowned self] in
                self.reset()

                let animation = self.makeAnimation(
                    parentCurve: ParabolicEaseInAnimationCurve(),
                    childCurve: LinearAnimationCurve(),
                    trackKeyframes: false
                )

                self.animationInstance = animation.perform(on: self.element)
            }),
            ("Keyframes in Linear / Linear", { [unowned self] in
                self.reset()

                let animation = self.makeAnimation(
                    parentCurve: LinearAnimationCurve(),
                    childCurve: LinearAnimationCurve(),
                    trackKeyframes: true
                )

                self.animationInstance = animation.perform(on: self.element)
            }),
            ("Keyframes in Linear / Ease In Out", { [unowned self] in
                self.reset()

                let animation = self.makeAnimation(
                    parentCurve: LinearAnimationCurve(),
                    childCurve: SinusoidalEaseInEaseOutAnimationCurve(),
                    trackKeyframes: true
                )

                self.animationInstance = animation.perform(on: self.element)
            }),
            ("Keyframes in Ease In Out / Ease In Out", { [unowned self] in
                self.reset()

                let animation = self.makeAnimation(
                    parentCurve: SinusoidalEaseInEaseOutAnimationCurve(),
                    childCurve: SinusoidalEaseInEaseOutAnimationCurve(),
                    trackKeyframes: true
                )

                self.animationInstance = animation.perform(on: self.element)
            }),
            ("Keyframes in Ease In / Linear", { [unowned self] in
                self.reset()

                let animation = self.makeAnimation(
                    parentCurve: ParabolicEaseInAnimationCurve(),
                    childCurve: LinearAnimationCurve(),
                    trackKeyframes: true
                )

                self.animationInstance = animation.perform(on: self.element)
            }),
        ]
    }

    // MARK: - Private Properties

    private weak var animationInstance: AnimationInstance?

    private let mainView: View = .init()

    private let element: Element = .init()

    // MARK: - Private Methods

    private func makeAnimation(
        parentCurve: AnimationCurve,
        childCurve: AnimationCurve,
        trackKeyframes: Bool
    ) -> Animation<Element> {
        func relativeTimestamp() -> Double {
            guard case let .some(.animating(progress)) = self.animationInstance?.status else {
                return 0
            }
            return progress
        }

        var parentAnimation = Animation<Element>()
        parentAnimation.curve = parentCurve
        if trackKeyframes {
            parentAnimation.addKeyframe(for: \.parentProgress, at: 0, value: 0)
            parentAnimation.addKeyframe(for: \.parentProgress, at: 1, value: 1)
            parentAnimation.addPerFrameExecution { context in
                self.mainView.parentChartView.addPoint(
                    relativeTimestamp: relativeTimestamp(),
                    uncurvedProgress: nil,
                    curvedProgress: context.element.parentProgress
                )
            }

        } else {
            parentAnimation.addPerFrameExecution { context in
                self.mainView.parentChartView.addPoint(
                    relativeTimestamp: relativeTimestamp(),
                    uncurvedProgress: context.uncurvedProgress,
                    curvedProgress: context.progress
                )
            }
        }
        parentAnimation.addExecution(
            onForward: { _ in self.mainView.parentChartView.addExecution(relativeTimestamp: relativeTimestamp()) },
            at: 0
        )
        parentAnimation.addExecution(
            onForward: { _ in self.mainView.parentChartView.addExecution(relativeTimestamp: relativeTimestamp()) },
            at: 0.5
        )
        parentAnimation.addExecution(
            onForward: { _ in self.mainView.parentChartView.addExecution(relativeTimestamp: relativeTimestamp()) },
            at: 1
        )

        var childAnimation = Animation<Element>()
        childAnimation.curve = childCurve
        if trackKeyframes {
            childAnimation.addKeyframe(for: \.childProgress, at: 0, value: 0)
            childAnimation.addKeyframe(for: \.childProgress, at: 1, value: 1)
            childAnimation.addPerFrameExecution { context in
                self.mainView.childChartView.addPoint(
                    relativeTimestamp: relativeTimestamp(),
                    uncurvedProgress: nil,
                    curvedProgress: context.element.childProgress
                )
            }

        } else {
            childAnimation.addPerFrameExecution { context in
                self.mainView.childChartView.addPoint(
                    relativeTimestamp: relativeTimestamp(),
                    uncurvedProgress: context.uncurvedProgress,
                    curvedProgress: context.progress
                )
            }
        }
        childAnimation.addExecution(
            onForward: { _ in self.mainView.childChartView.addExecution(relativeTimestamp: relativeTimestamp()) },
            at: 0
        )
        childAnimation.addExecution(
            onForward: { _ in self.mainView.childChartView.addExecution(relativeTimestamp: relativeTimestamp()) },
            at: 0.5
        )
        childAnimation.addExecution(
            onForward: { _ in self.mainView.childChartView.addExecution(relativeTimestamp: relativeTimestamp()) },
            at: 1
        )
        parentAnimation.addChild(childAnimation, for: \.self, startingAt: 0.25, relativeDuration: 0.5)

        parentAnimation.duration = 4
        return parentAnimation
    }

    private func reset() {
        animationInstance?.cancel()

        mainView.parentChartView.reset()
        mainView.childChartView.reset()
    }

}

// MARK: -

private extension ChildAnimationProgressViewController {

    final class View: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            addSubview(parentChartView)

            addSubview(childChartView)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Public Properties

        let parentChartView: ChartView = .init()

        let childChartView: ChartView = .init()

        // MARK: - UIView

        override func layoutSubviews() {
            let chartSize = CGSize(
                width: bounds.width - 40,
                height: 100
            )

            parentChartView.bounds.size = chartSize
            parentChartView.frame.origin = .init(x: 20, y: 20)

            childChartView.bounds.size = chartSize
            childChartView.frame.origin = .init(x: 20, y: parentChartView.frame.maxY + 20)
        }

    }

}

// MARK: -

private extension ChildAnimationProgressViewController {

    final class ChartView: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            gridLayer.fillColor = nil
            gridLayer.lineWidth = 1
            gridLayer.strokeColor = UIColor(white: 0.9, alpha: 1).cgColor
            layer.addSublayer(gridLayer)

            uncurvedProgressLayer.fillColor = nil
            uncurvedProgressLayer.lineWidth = 1.5
            uncurvedProgressLayer.strokeColor = UIColor(white: 0.7, alpha: 1).cgColor
            layer.addSublayer(uncurvedProgressLayer)

            curvedProgressLayer.fillColor = nil
            curvedProgressLayer.lineWidth = 1.5
            curvedProgressLayer.strokeColor = UIColor(white: 0.3, alpha: 1).cgColor
            layer.addSublayer(curvedProgressLayer)

            executionBlocksLayer.fillColor = nil
            executionBlocksLayer.lineWidth = 1.5
            executionBlocksLayer.strokeColor = UIColor.blue.cgColor
            layer.addSublayer(executionBlocksLayer)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let gridLayer: CAShapeLayer = .init()

        private let uncurvedProgressLayer: CAShapeLayer = .init()
        private var uncurvedProgressPath: UIBezierPath = .init()

        private let curvedProgressLayer: CAShapeLayer = .init()
        private var curvedProgressPath: UIBezierPath = .init()

        private let executionBlocksLayer: CAShapeLayer = .init()
        private var executionBlocksPath: UIBezierPath = .init()

        // MARK: - UIView

        override func layoutSubviews() {
            gridLayer.frame = bounds
            updateGrid()

            uncurvedProgressLayer.frame = bounds
            curvedProgressLayer.frame = bounds
            executionBlocksLayer.frame = bounds
        }

        // MARK: - Public Methods

        func addPoint(relativeTimestamp: Double, uncurvedProgress: Double?, curvedProgress: Double) {
            if let uncurvedProgress = uncurvedProgress {
                let uncurvedProgressPoint = CGPoint(
                    x: CGFloat(relativeTimestamp) * uncurvedProgressLayer.bounds.width,
                    y: CGFloat(1 - uncurvedProgress) * uncurvedProgressLayer.bounds.height
                )
                if uncurvedProgressPath.isEmpty {
                    uncurvedProgressPath.move(to: uncurvedProgressPoint)
                } else {
                    uncurvedProgressPath.addLine(to: uncurvedProgressPoint)
                }
                uncurvedProgressLayer.path = uncurvedProgressPath.cgPath
            }

            let curvedProgressPoint = CGPoint(
                x: CGFloat(relativeTimestamp) * curvedProgressLayer.bounds.width,
                y: CGFloat(1 - curvedProgress) * curvedProgressLayer.bounds.height
            )
            if curvedProgressPath.isEmpty {
                curvedProgressPath.move(to: curvedProgressPoint)
            } else {
                curvedProgressPath.addLine(to: curvedProgressPoint)
            }
            curvedProgressLayer.path = curvedProgressPath.cgPath
        }

        func addExecution(relativeTimestamp: Double) {
            let positionX = CGFloat(relativeTimestamp) * executionBlocksLayer.bounds.width
            executionBlocksPath.move(to: .init(x: positionX, y: 0))
            executionBlocksPath.addLine(to: .init(x: positionX, y: executionBlocksLayer.bounds.height))
            executionBlocksLayer.path = executionBlocksPath.cgPath
        }

        func reset() {
            uncurvedProgressPath = .init()
            uncurvedProgressLayer.path = uncurvedProgressPath.cgPath

            curvedProgressPath = .init()
            curvedProgressLayer.path = curvedProgressPath.cgPath

            executionBlocksPath = .init()
            executionBlocksLayer.path = executionBlocksPath.cgPath
        }

        // MARK: - Private Methods

        private func updateGrid() {
            let gridPath = UIBezierPath()

            let horizontalDivisions = 12
            let verticalDivisions = 4
            let cellSize = CGSize(
                width: gridLayer.bounds.width / CGFloat(horizontalDivisions),
                height: gridLayer.bounds.height / CGFloat(verticalDivisions)
            )

            for row in 0...verticalDivisions {
                gridPath.move(to: CGPoint(x: 0, y: cellSize.height * CGFloat(row)))
                gridPath.addLine(to: CGPoint(x: gridLayer.bounds.width, y: cellSize.height * CGFloat(row)))
            }

            for column in 0...horizontalDivisions {
                gridPath.move(to: CGPoint(x: cellSize.width * CGFloat(column), y: 0))
                gridPath.addLine(to: CGPoint(x: cellSize.width * CGFloat(column), y: gridLayer.bounds.height))
            }

            gridLayer.path = gridPath.cgPath
        }

    }

}

// MARK: -

private extension ChildAnimationProgressViewController {

    final class Element {

        var parentProgress: Double = -1

        var childProgress: Double = -1

    }

}
