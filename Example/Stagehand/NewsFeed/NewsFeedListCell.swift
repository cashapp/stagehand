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

final class NewsFeedListCell: UITableViewCell {

    // MARK: - Life Cycle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        imageHeadlineView.headlineInsets = Metrics.headlineInsets
        imageHeadlineView.layer.cornerRadius = Metrics.cornerRadius
        addSubview(imageHeadlineView)

        selectionStyle = .none
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Properties

    private let imageHeadlineView: NewsFeedImageHeadlineView = .init()

    // MARK: - UIView

    override func layoutSubviews() {
        imageHeadlineView.frame = bounds.inset(by: Metrics.contentInsets)
    }

    // MARK: - Public Methods

    func configure(with item: NewsFeedItem) {
        imageHeadlineView.imageView.image = item.image
        imageHeadlineView.imageRegion = item.imageHighlightRegion
        imageHeadlineView.headlineLabel.text = item.headline
    }

    func makeTransitionContext() -> NewsFeedTransitionListContext {
        return .init(imageHeadlineView: imageHeadlineView)
    }

    static func height(for item: NewsFeedItem, in tableView: UITableView) -> CGFloat {
        let imageSizeToFit = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: .greatestFiniteMagnitude)
            .inset(by: Metrics.contentInsets)
            .size
        let imageHighlightSize = CGSize(
            width: item.image.size.width * item.imageHighlightRegion.width,
            height: item.image.size.height * item.imageHighlightRegion.height
        )
        let imageSize = imageHighlightSize.aspectRatio.size(toFit: imageSizeToFit, in: tableView)
        return CGRect(origin: .zero, size: imageSize).outset(by: Metrics.contentInsets).height
    }

    // MARK: - Private Types

    enum Metrics {

        static let contentInsets: UIEdgeInsets = .init(vertical: 12, horizontal: 24)

        static let headlineInsets: UIEdgeInsets = .init(vertical: 16, horizontal: 16)

        static let cornerRadius: CGFloat = 16

    }

}
