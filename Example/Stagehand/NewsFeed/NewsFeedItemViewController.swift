//
//  Copyright 2021 Square Inc.
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

import Paralayout
import UIKit

final class NewsFeedItemViewController: UIViewController {

    // MARK: - Life Cycle

    init(item: NewsFeedItem) {
        self.item = item

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Properties

    private let item: NewsFeedItem

    private var mainView: View {
        return view as! View
    }

    // MARK: - UIViewController

    override func loadView() {
        view = View()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let view = view as! View
        view.imageHeadlineView.imageView.image = item.image
        view.imageHeadlineView.headlineLabel.text = item.headline
        view.bodyLabel.text = item.body

        view.closeButton.addTarget(self, action: #selector(handleCloseButton), for: .touchUpInside)
    }

    // MARK: - Private Methods

    @objc private func handleCloseButton() {
        dismiss(animated: true)
    }

}

// MARK: -

extension NewsFeedItemViewController: NewsFeedTransitionDetailViewController {

    var transitionContext: NewsFeedTransitionDetailContext {
        return .init(
            backgroundView: mainView,
            imageHeadlineView: mainView.imageHeadlineView,
            bodyLabel: mainView.bodyLabel,
            closeButton: mainView.closeButton
        )
    }

}

// MARK: -

extension NewsFeedItemViewController {

    final class View: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            imageHeadlineView.headlineInsets = Metrics.headlineInsets
            addSubview(imageHeadlineView)

            closeButton.setTitle("𝗫", for: .normal)
            closeButton.setTitleColor(.white, for: .normal)
            closeButton.backgroundColor = .darkGray
            addSubview(closeButton)

            bodyLabel.textColor = .black
            bodyLabel.font = .preferredFont(forTextStyle: .body)
            bodyLabel.numberOfLines = 0
            addSubview(bodyLabel)

            backgroundColor = .white
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Public Properties

        let closeButton: UIButton = .init()

        let imageHeadlineView: NewsFeedImageHeadlineView = .init()

        let bodyLabel: UILabel = .init()

        // MARK: - UIView

        override func layoutSubviews() {
            let imageSize = imageHeadlineView.sizeThatFits(bounds.size)
            imageHeadlineView.frame = bounds.slice(from: .minYEdge, amount: imageSize.height).slice

            closeButton.bounds.size = AspectRatio.square.size(toFit: closeButton.sizeThatFits(), in: self)
            closeButton.layer.cornerRadius = closeButton.bounds.height / 2
            closeButton.align(
                .topRight,
                withSuperviewPosition: .topRight,
                horizontalOffset: -24,
                verticalOffset: (window?.safeAreaInsets.top ?? 0) + 12
            )

            bodyLabel.sizeToFit(width: bounds.width - Metrics.bodyInsets.horizontalAmount)
            bodyLabel.align(
                .topLeft,
                with: imageHeadlineView,
                .bottomLeft,
                horizontalOffset: Metrics.bodyInsets.left,
                verticalOffset: Metrics.bodyInsets.top
            )
        }

        // MARK: - Private Types

        enum Metrics {

            static let headlineInsets: UIEdgeInsets = .init(vertical: 16, horizontal: 24)

            static let bodyInsets: UIEdgeInsets = .init(vertical: 24, horizontal: 24)

        }

    }

}
