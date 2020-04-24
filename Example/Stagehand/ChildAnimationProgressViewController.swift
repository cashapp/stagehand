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
        contentHeight = 360

        animationRows = [
            ("Linear / Linear", { [unowned self] in
                self.reset()

                let animation = self.makeAnimation(
                    parentCurve: LinearAnimationCurve(),
                    childCurve: LinearAnimationCurve()
                )

                self.animationInstance = animation.perform(on: self.element)
            }),
            ("Linear / Ease In Out", { [unowned self] in
                self.reset()

                let animation = self.makeAnimation(
                    parentCurve: LinearAnimationCurve(),
                    childCurve: SinusoidalEaseInEaseOutAnimationCurve()
                )

                self.animationInstance = animation.perform(on: self.element)
            }),
            ("Linear / Ease In", { [unowned self] in
                self.reset()

                let animation = self.makeAnimation(
                    parentCurve: LinearAnimationCurve(),
                    childCurve: CubicBezierAnimationCurve(controlPoints: (0.7, 0), (1, 1))
                )

                self.animationInstance = animation.perform(on: self.element)
            }),
            ("Ease In Out / Ease In Out", { [unowned self] in
                self.reset()

                let animation = self.makeAnimation(
                    parentCurve: SinusoidalEaseInEaseOutAnimationCurve(),
                    childCurve: SinusoidalEaseInEaseOutAnimationCurve()
                )

                self.animationInstance = animation.perform(on: self.element)
            }),
            ("Ease In / Linear", { [unowned self] in
                self.reset()

                let animation = self.makeAnimation(
                    parentCurve: ParabolicEaseInAnimationCurve(),
                    childCurve: LinearAnimationCurve()
                )

                self.animationInstance = animation.perform(on: self.element)
            }),

            // The behavior of execution blocks and property assignments is undefined when used with an animation curve
            // that overshoots. This test case is useful for debugging, and may eventually become defined behavior, but
            // is not an official part of the API specification for now.
            //
            // ("Linear / Overshoot", { [unowned self] in
            //     self.reset()
            //
            //     let animation = self.makeAnimation(
            //         parentCurve: LinearAnimationCurve(),
            //         childCurve: CubicBezierAnimationCurve(controlPoints: (0.1, -0.5), (0.9, 1.5))
            //     )
            //
            //     self.animationInstance = animation.perform(on: self.element)
            // }),
        ]

        mainView.graphModeControl.insertSegment(withTitle: "Per-Frame Blocks", at: 0, animated: false)
        mainView.graphModeControl.insertSegment(withTitle: "Keyframes", at: 1, animated: false)
        mainView.graphModeControl.selectedSegmentIndex = 0
        mainView.graphModeControl.addTarget(self, action: #selector(controlValuesUpdated), for: .valueChanged)

        mainView.eventsModeControl.insertSegment(withTitle: "Execution Blocks", at: 0, animated: false)
        mainView.eventsModeControl.insertSegment(withTitle: "Property Assignments", at: 1, animated: false)
        mainView.eventsModeControl.selectedSegmentIndex = 0
        mainView.eventsModeControl.addTarget(self, action: #selector(controlValuesUpdated), for: .valueChanged)
    }

    // MARK: - Private Properties

    private weak var animationInstance: AnimationInstance?

    private let mainView: View = .init()

    private let element: Element = .init()

    private var graphMode: GraphMode = .perFrameExecutionBlocks

    private var eventsMode: EventsMode = .executionBlocks

    // MARK: - Private Methods

    private func makeAnimation(
        parentCurve: AnimationCurve,
        childCurve: AnimationCurve
    ) -> Animation<Element> {
        func relativeTimestamp() -> Double {
            guard case let .some(.animating(progress)) = self.animationInstance?.status else {
                return 0
            }
            return progress
        }

        var parentAnimation = Animation<Element>()
        parentAnimation.curve = parentCurve

        var childAnimation = Animation<Element>()
        childAnimation.curve = childCurve

        switch graphMode {
        case .keyframes:
            parentAnimation.addKeyframe(for: \.parentProgress, at: 0, value: 0)
            parentAnimation.addKeyframe(for: \.parentProgress, at: 1, value: 1)
            parentAnimation.addPerFrameExecution { context in
                self.mainView.parentChartView.addPoint(
                    relativeTimestamp: relativeTimestamp(),
                    uncurvedProgress: nil,
                    curvedProgress: context.element.parentProgress
                )
            }

            childAnimation.addKeyframe(for: \.childProgress, at: 0, value: 0)
            childAnimation.addKeyframe(for: \.childProgress, at: 1, value: 1)
            childAnimation.addPerFrameExecution { context in
                self.mainView.childChartView.addPoint(
                    relativeTimestamp: relativeTimestamp(),
                    uncurvedProgress: nil,
                    curvedProgress: context.element.childProgress
                )
            }

        case .perFrameExecutionBlocks:
            parentAnimation.addPerFrameExecution { context in
                self.mainView.parentChartView.addPoint(
                    relativeTimestamp: relativeTimestamp(),
                    uncurvedProgress: context.uncurvedProgress,
                    curvedProgress: context.progress
                )
            }

            childAnimation.addPerFrameExecution { context in
                self.mainView.childChartView.addPoint(
                    relativeTimestamp: relativeTimestamp(),
                    uncurvedProgress: context.uncurvedProgress,
                    curvedProgress: context.progress
                )
            }
        }

        switch eventsMode {
        case .executionBlocks:
            parentAnimation.addExecution(
                onForward: { _ in self.mainView.parentChartView.addForwardExecution(relativeTimestamp: relativeTimestamp()) },
                onReverse: { _ in self.mainView.parentChartView.addReverseExecution(relativeTimestamp: relativeTimestamp()) },
                at: 0
            )
            parentAnimation.addExecution(
                onForward: { _ in self.mainView.parentChartView.addForwardExecution(relativeTimestamp: relativeTimestamp()) },
                onReverse: { _ in self.mainView.parentChartView.addReverseExecution(relativeTimestamp: relativeTimestamp()) },
                at: 0.5
            )
            parentAnimation.addExecution(
                onForward: { _ in self.mainView.parentChartView.addForwardExecution(relativeTimestamp: relativeTimestamp()) },
                onReverse: { _ in self.mainView.parentChartView.addReverseExecution(relativeTimestamp: relativeTimestamp()) },
                at: 1
            )

            childAnimation.addExecution(
                onForward: { _ in self.mainView.childChartView.addForwardExecution(relativeTimestamp: relativeTimestamp()) },
                onReverse: { _ in self.mainView.childChartView.addReverseExecution(relativeTimestamp: relativeTimestamp()) },
                at: 0
            )
            childAnimation.addExecution(
                onForward: { _ in self.mainView.childChartView.addForwardExecution(relativeTimestamp: relativeTimestamp()) },
                onReverse: { _ in self.mainView.childChartView.addReverseExecution(relativeTimestamp: relativeTimestamp()) },
                at: 0.5
            )
            childAnimation.addExecution(
                onForward: { _ in self.mainView.childChartView.addForwardExecution(relativeTimestamp: relativeTimestamp()) },
                onReverse: { _ in self.mainView.childChartView.addReverseExecution(relativeTimestamp: relativeTimestamp()) },
                at: 1
            )

        case .propertyAssignments:
            parentAnimation.addAssignment(for: \.parentPropertyAssignmentProxy, at: 0, value: true)
            parentAnimation.addAssignment(for: \.parentPropertyAssignmentProxy, at: 0.5, value: true)
            parentAnimation.addAssignment(for: \.parentPropertyAssignmentProxy, at: 1, value: true)

            childAnimation.addAssignment(for: \.childPropertyAssignmentProxy, at: 0, value: true)
            childAnimation.addAssignment(for: \.childPropertyAssignmentProxy, at: 0.5, value: true)
            childAnimation.addAssignment(for: \.childPropertyAssignmentProxy, at: 1, value: true)

            parentAnimation.addPerFrameExecution { context in
                if let parentPropertyAssignmentDirection = context.element.didSetParentProperty {
                    switch parentPropertyAssignmentDirection {
                    case .forward:
                        self.mainView.parentChartView.addForwardExecution(relativeTimestamp: relativeTimestamp())
                    case .reverse:
                        self.mainView.parentChartView.addReverseExecution(relativeTimestamp: relativeTimestamp())
                    }
                }

                if let childPropertyAssignmentDirection = context.element.didSetChildProperty {
                    switch childPropertyAssignmentDirection {
                    case .forward:
                        self.mainView.childChartView.addForwardExecution(relativeTimestamp: relativeTimestamp())
                    case .reverse:
                        self.mainView.childChartView.addReverseExecution(relativeTimestamp: relativeTimestamp())
                    }
                }

                context.element.didSetParentProperty = nil
                context.element.didSetChildProperty = nil
            }
        }

        parentAnimation.addChild(childAnimation, for: \.self, startingAt: 0.25, relativeDuration: 0.5)

        parentAnimation.duration = 4
        return parentAnimation
    }

    private func reset() {
        animationInstance?.cancel()

        mainView.parentChartView.reset()
        mainView.childChartView.reset()
    }

    @objc
    private func controlValuesUpdated() {
        switch mainView.graphModeControl.selectedSegmentIndex {
        case 0:
            graphMode = .perFrameExecutionBlocks
        case 1:
            graphMode = .keyframes
        default:
            fatalError("Unexpected selected segment index")
        }

        switch mainView.eventsModeControl.selectedSegmentIndex {
        case 0:
            eventsMode = .executionBlocks
        case 1:
            eventsMode = .propertyAssignments
        default:
            fatalError("Unexpected selected segment index")
        }
    }

    // MARK: - Private Types

    private enum GraphMode {
        case perFrameExecutionBlocks
        case keyframes
    }

    private enum EventsMode {
        case executionBlocks
        case propertyAssignments
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
            addSubview(graphModeControl)
            addSubview(eventsModeControl)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Public Properties

        let parentChartView: ChartView = .init()

        let childChartView: ChartView = .init()

        let graphModeControl: UISegmentedControl = .init()

        let eventsModeControl: UISegmentedControl = .init()

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

            let controlSizeToFit = CGSize(width: bounds.width / 3, height: .greatestFiniteMagnitude)
            graphModeControl.bounds.size = graphModeControl.sizeThatFits(controlSizeToFit)
            eventsModeControl.bounds.size = eventsModeControl.sizeThatFits(controlSizeToFit)

            let controlsMargin: CGFloat = 20
            let controlsWidth = (bounds.width - (controlsMargin * 2))

            graphModeControl.sizeToFit()
            graphModeControl.bounds.size.width = controlsWidth
            graphModeControl.frame.origin = .init(x: controlsMargin, y: childChartView.frame.maxY + controlsMargin)

            eventsModeControl.sizeToFit()
            eventsModeControl.bounds.size.width = controlsWidth
            eventsModeControl.frame.origin = .init(x: controlsMargin, y: graphModeControl.frame.maxY + controlsMargin)
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

            forwardExecutionBlocksLayer.fillColor = nil
            forwardExecutionBlocksLayer.lineWidth = 1.5
            forwardExecutionBlocksLayer.strokeColor = UIColor.blue.cgColor
            layer.addSublayer(forwardExecutionBlocksLayer)

            reverseExecutionBlocksLayer.fillColor = nil
            reverseExecutionBlocksLayer.lineWidth = 1.5
            reverseExecutionBlocksLayer.strokeColor = UIColor.red.cgColor
            layer.addSublayer(reverseExecutionBlocksLayer)
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

        private let forwardExecutionBlocksLayer: CAShapeLayer = .init()
        private var forwardExecutionBlocksPath: UIBezierPath = .init()

        private let reverseExecutionBlocksLayer: CAShapeLayer = .init()
        private var reverseExecutionBlocksPath: UIBezierPath = .init()

        // MARK: - UIView

        override func layoutSubviews() {
            gridLayer.frame = bounds
            updateGrid()

            uncurvedProgressLayer.frame = bounds
            curvedProgressLayer.frame = bounds
            forwardExecutionBlocksLayer.frame = bounds
            reverseExecutionBlocksLayer.frame = bounds
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

        func addForwardExecution(relativeTimestamp: Double) {
            let positionX = CGFloat(relativeTimestamp) * forwardExecutionBlocksLayer.bounds.width
            forwardExecutionBlocksPath.move(to: .init(x: positionX, y: 0))
            forwardExecutionBlocksPath.addLine(to: .init(x: positionX, y: forwardExecutionBlocksLayer.bounds.height))
            forwardExecutionBlocksLayer.path = forwardExecutionBlocksPath.cgPath
        }

        func addReverseExecution(relativeTimestamp: Double) {
            let positionX = CGFloat(relativeTimestamp) * reverseExecutionBlocksLayer.bounds.width
            reverseExecutionBlocksPath.move(to: .init(x: positionX, y: 0))
            reverseExecutionBlocksPath.addLine(to: .init(x: positionX, y: reverseExecutionBlocksLayer.bounds.height))
            reverseExecutionBlocksLayer.path = reverseExecutionBlocksPath.cgPath
        }

        func reset() {
            uncurvedProgressPath = .init()
            uncurvedProgressLayer.path = uncurvedProgressPath.cgPath

            curvedProgressPath = .init()
            curvedProgressLayer.path = curvedProgressPath.cgPath

            forwardExecutionBlocksPath = .init()
            forwardExecutionBlocksLayer.path = forwardExecutionBlocksPath.cgPath

            reverseExecutionBlocksPath = .init()
            reverseExecutionBlocksLayer.path = reverseExecutionBlocksPath.cgPath
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

        var parentPropertyAssignmentProxy: Bool {
            get {
                return false
            }
            set {
                // This property always return `false` and the property assignments above always provide a value of
                // `true`. Therefore, if `newValue` is `true`, we're in a forward execution; and if `newValue` is
                // `false`, we're in a reverse execution (restoring the original value that was read).
                if newValue {
                    didSetParentProperty = .forward
                } else {
                    didSetParentProperty = .reverse
                }
            }
        }

        var didSetParentProperty: AssignmentDirection?

        var childPropertyAssignmentProxy: Bool {
            get {
                return false
            }
            set {
                // This property always return `false` and the property assignments above always provide a value of
                // `true`. Therefore, if `newValue` is `true`, we're in a forward execution; and if `newValue` is
                // `false`, we're in a reverse execution (restoring the original value that was read).
                if newValue {
                    didSetChildProperty = .forward
                } else {
                    didSetChildProperty = .reverse
                }
            }
        }

        var didSetChildProperty: AssignmentDirection?

    }

    enum AssignmentDirection {
        case forward
        case reverse
    }

}
