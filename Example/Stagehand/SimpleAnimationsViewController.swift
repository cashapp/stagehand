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

final class SimpleAnimationsViewController: DemoViewController {

    // MARK: - Life Cycle

    override init() {
        super.init()

        contentView = mainView

        animationRows = [
            ("Fade Out", { [unowned self] in
                let animation = AnimationFactory.makeFadeOutAnimation()
                animation.perform(on: self.mainView.animatableView)
            }),
            ("Fade In", { [unowned self] in
                let animation = AnimationFactory.makeFadeInAnimation()
                animation.perform(on: self.mainView.animatableView)
            }),
        ]
    }

    // MARK: - Private Properties

    private let mainView: View = .init()

}

// MARK: -

extension SimpleAnimationsViewController {

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
