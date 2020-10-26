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

final class PerformanceBenchmarkViewController: DemoViewController {

    // MARK: - Life Cycle

    override init() {
        super.init()

        contentView = mainView
        contentHeight = 360

        animationRows = [
            ("Reset", { [unowned self] in
                self.animationInstances.forEach { $0.cancel(behavior: .revert) }
                self.animationInstances = []
            }),
            ("Add Rotating Center View Animation", { [unowned self] in
                var animation = Animation<View>()

                animation.addKeyframe(for: \.centerView.transform, at: 0.00, value: .identity)
                animation.addKeyframe(for: \.centerView.transform, at: 0.25, value: .init(rotationAngle: .pi / 2))
                animation.addKeyframe(for: \.centerView.transform, at: 0.50, value: .init(rotationAngle: .pi))
                animation.addKeyframe(for: \.centerView.transform, at: 0.75, value: .init(rotationAngle: .pi * 3 / 2))
                animation.addKeyframe(for: \.centerView.transform, at: 1.00, value: .identity)

                animation.implicitDuration = 4
                animation.implicitRepeatStyle = .infinitelyRepeating(autoreversing: true)

                self.animationInstances.append(animation.perform(on: self.mainView))
            }),
            ("Add Center View Color with Haptics", { [unowned self] in
                var animation = Animation<View>()

                let colors: [UIColor] = [.red, .green, .yellow, .purple, .blue, .brown, .orange]

                let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

                for (index, color) in colors.enumerated() {
                    let progress = (Double(index) / Double(colors.count))

                    animation.addAssignment(
                        for: \View.centerView.backgroundColor,
                        at: progress,
                        value: color
                    )

                    animation.addExecution(
                        onForward: { _ in feedbackGenerator.impactOccurred() },
                        at: progress
                    )
                }

                animation.implicitDuration = 3.5
                animation.implicitRepeatStyle = .infinitelyRepeating(autoreversing: false)

                self.animationInstances.append(animation.perform(on: self.mainView))
            }),
        ]

        mainView.childViewCountSlider.minimumValue = 0
        mainView.childViewCountSlider.maximumValue = 20
        mainView.childViewCountSlider.addTarget(self, action: #selector(updateChildCount), for: .valueChanged)
    }

    // MARK: - Private Properties

    private let mainView: View = .init()

    private var fpsDisplayLink: CADisplayLink?

    private var animationInstances: [AnimationInstance] = [] {
        didSet {
            mainView.childViewCountSlider.isEnabled = animationInstances.isEmpty
        }
    }

    @objc private func updateChildCount() {
        mainView.rotatingChildViewCount = Int(mainView.childViewCountSlider.value)
        mainView.resetRotatingChildViewTransforms()
    }

    // MARK: - UIViewController

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        fpsDisplayLink = CADisplayLink(target: self, selector: #selector(updateFPS))
        fpsDisplayLink?.add(to: .current, forMode: .common)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        fpsDisplayLink?.invalidate()
        fpsDisplayLink = nil
    }

    // MARK: - Private Methods

    @objc private func updateFPS() {
        guard let displayLink = fpsDisplayLink else {
            return
        }

        mainView.fpsLabel.text = "\((1 / (displayLink.targetTimestamp - displayLink.timestamp)).rounded()) FPS"
    }

}

// MARK: -

extension PerformanceBenchmarkViewController {

    final class View: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            addSubview(animatedSubviewsContainer)

            centerView.backgroundColor = .red
            animatedSubviewsContainer.addSubview(centerView)

            addSubview(childViewCountSlider)

            fpsLabel.textAlignment = .right
            fpsLabel.text = "-- FPS"
            addSubview(fpsLabel)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Public Static Properties

        static let radius: CGFloat = 100

        // MARK: - Public Properties

        var rotatingChildViewCount: Int {
            get {
                return rotatingChildViews.count
            }
            set {
                rotatingChildViews = (0..<newValue).map { _ in
                    let view = UIView()
                    view.bounds.size = .init(width: 20, height: 20)
                    view.backgroundColor = .red
                    return view
                }
            }
        }

        let centerView: UIView = .init()

        let childViewCountSlider: UISlider = .init()

        let fpsLabel: UILabel = .init()

        private(set) var rotatingChildViews: [UIView] = [] {
            didSet {
                oldValue.forEach { $0.removeFromSuperview() }
                rotatingChildViews.forEach(animatedSubviewsContainer.addSubview)
                setNeedsLayout()
            }
        }

        // MARK: - Private Properties

        /// When the `transform` of a view is modified, UIKit invalidates the layout of the view's superview. Since
        /// we're animating the transforms of our subviews, this triggers a lot of expensive layout passes. As an
        /// optimization, we can place the subviews we're going to animate inside a full-size container view that has a
        /// cheap `layoutSubviews` implementation.
        private let animatedSubviewsContainer: UIView = .init()

        // MARK: - UIView

        override func layoutSubviews() {
            animatedSubviewsContainer.frame = bounds

            centerView.bounds.size = .init(width: 40, height: 40)
            centerView.center = .init(
                x: bounds.midX,
                y: bounds.midY - 20
            )

            // All of the rotating children are placed on top of the center view and transformed to rotate around it.
            rotatingChildViews.forEach { $0.center = centerView.center }

            fpsLabel.sizeToFit()
            fpsLabel.bounds.size.width = (bounds.width / 2)
            fpsLabel.frame.origin = .init(
                x: bounds.width / 2 - 24,
                y: bounds.maxY - 60
            )

            childViewCountSlider.bounds.size = childViewCountSlider.sizeThatFits(bounds.insetBy(dx: 24, dy: 0).size)
            childViewCountSlider.frame.origin = .init(
                x: 24,
                y: bounds.maxY - 40
            )
        }

        // MARK: - Public Methods

        func resetRotatingChildViewTransforms() {
            for (index, view) in rotatingChildViews.enumerated() {
                let degree = CGFloat(index) / CGFloat(rotatingChildViewCount) * 360
                view.transform = CGAffineTransform.identity
                    .translatedBy(
                        x: View.radius * cos(CGFloat(degree) * .pi / 180),
                        y: View.radius * sin(CGFloat(degree) * .pi / 180)
                    )
                    .rotated(by: CGFloat(degree) * .pi / 180)
            }
        }

    }

}
