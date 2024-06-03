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

final class AnimatableContainerView: UIView {

    // MARK: - Life Cycle

    override init(frame: CGRect) {
        super.init(frame: frame)

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
        animatableView.bounds.size = .init(width: 20, height: 20)
        animatableView.center = .init(x: 20, y: bounds.midY)
    }

}

// MARK: -

extension AnimatableContainerView {

    @MainActor
    final class Proxy {

        // MARK: - Life Cycle

        init(view: AnimatableContainerView) {
            self.view = view
        }

        // MARK: - Public Properties

        public var animatableViewTransform: CGAffineTransform {
            get {
                return view.animatableView.transform
            }
            set {
                view.animatableView.transform = newValue
            }
        }

        // MARK: - Private Properties

        private let view: AnimatableContainerView

    }

}
