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

import UIKit

final class RelativeAnimationsViewController: DemoViewController {

    // MARK: - Life Cycle

    override init() {
        self.gestureRecognizerDelegate = .init(transformableView: mainView.animatableView)
        self.gestureRecognizer = .init(
            target: self.gestureRecognizerDelegate,
            action: #selector(TransformGestureRecognizerDelegate.handlePan(_:))
        )

        super.init()

        contentView = mainView
        contentHeight = 300

        animationRows = [
            ("Reset", { [unowned self] in
                self.gestureRecognizer.isEnabled = false

                let animation = AnimationFactory.makeResetTransformAnimation()
                animation.perform(on: self.mainView.animatableView) { [weak self] _ in
                    self?.gestureRecognizer.isEnabled = true
                }
            }),
            ("Rotate 45°", { [unowned self] in
                self.gestureRecognizer.isEnabled = false

                let animation = AnimationFactory.makeRotateAnimation()
                animation.perform(on: self.mainView.animatableView) { [weak self] _ in
                    self?.gestureRecognizer.isEnabled = true
                }
            }),
            ("Pop", { [unowned self] in
                self.gestureRecognizer.isEnabled = false

                let animation = AnimationFactory.makePopAnimation()
                animation.perform(on: self.mainView.animatableView) { [weak self] _ in
                    self?.gestureRecognizer.isEnabled = true
                }
            }),
        ]

        mainView.animatableView.addGestureRecognizer(gestureRecognizer)
    }

    // MARK: - Private Properties

    private let mainView: View = .init()

    private let gestureRecognizer: UIPanGestureRecognizer

    private let gestureRecognizerDelegate: TransformGestureRecognizerDelegate

}

// MARK: -

extension RelativeAnimationsViewController {

    final class View: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            animatableView.frame.size = .init(width: 50, height: 50)
            animatableView.backgroundColor = .red
            addSubview(animatableView)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Public Properties

        let animatableView: UIView = .init()

        // MARK: - UIView

        override func layoutSubviews() {
            animatableView.center = .init(
                x: (bounds.maxX - bounds.minX) / 2,
                y: (bounds.maxY - bounds.minY) / 2
            )
        }

    }

}

// MARK: -

extension RelativeAnimationsViewController {

    final class TransformGestureRecognizerDelegate: NSObject, UIGestureRecognizerDelegate {

        // MARK: - Life Cycle

        init(transformableView: UIView) {
            self.transformableView = transformableView
        }

        // MARK: - Private Properties

        private let transformableView: UIView

        private var initialTransform: CGAffineTransform?

        // MARK: - Public Methods

        @objc func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
            switch gestureRecognizer.state {
            case .possible, .failed:
                break // No-op.

            case .began:
                initialTransform = transformableView.transform

            case .changed:
                guard let initialTransform = initialTransform else {
                    return
                }

                let translation = gestureRecognizer.translation(in: transformableView.superview)
                let translationTransform = CGAffineTransform(
                    translationX: translation.x,
                    y: translation.y
                )
                transformableView.transform = initialTransform.concatenating(translationTransform)

            case .cancelled:
                transformableView.transform = initialTransform ?? .identity
                initialTransform = nil

            case .ended:
                initialTransform = nil

            @unknown default:
                break
            }
        }

    }

}
