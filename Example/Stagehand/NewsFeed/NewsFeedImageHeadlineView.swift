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

final class NewsFeedImageHeadlineView: UIView {

    // MARK: - Life Cycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(imageView)

        headlineLabel.textColor = .white
        headlineLabel.font = .boldSystemFont(ofSize: 36)
        headlineLabel.numberOfLines = 0
        headlineLabel.layer.shadowColor = UIColor.black.cgColor
        headlineLabel.layer.shadowOpacity = 0.5
        headlineLabel.layer.shadowRadius = 2
        headlineLabel.layer.shadowOffset = .init(width: 2, height: 2)
        addSubview(headlineLabel)

        clipsToBounds = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Internal Properties

    let headlineLabel: UILabel = .init()

    let imageView: UIImageView = .init()

    var imageRegion: CGRect = .init(x: 0, y: 0, width: 1, height: 1) {
        didSet {
            setNeedsLayout()
        }
    }

    var headlineInsets: UIEdgeInsets = .zero {
        didSet {
            setNeedsLayout()
        }
    }

    // MARK: - UIView

    override func layoutSubviews() {
        let expandedImageWidth = bounds.width / imageRegion.width
        let expandedImageHeight = bounds.height / imageRegion.height

        imageView.frame = .init(
            x: -imageRegion.minX * expandedImageWidth,
            y: -imageRegion.minY * expandedImageHeight,
            width: expandedImageWidth,
            height: expandedImageHeight
        )

        headlineLabel.sizeToFit(bounds.inset(by: headlineInsets).size, constraints: .maxSize)
        headlineLabel.align(
            .bottomLeft,
            withSuperviewPosition: .bottomLeft,
            horizontalOffset: headlineInsets.left,
            verticalOffset: -headlineInsets.bottom
        )
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        guard let image = imageView.image else {
            return .zero
        }

        return AspectRatio(
            width: image.size.width * imageRegion.width,
            height: image.size.height * imageRegion.height
        ).size(toFit: size, in: self)
    }

}
