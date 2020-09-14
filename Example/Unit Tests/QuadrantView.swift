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

final class QuadrantView: UIView {

    // MARK: - Life Cycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        topLeftLayer.backgroundColor = UIColor.red.cgColor
        layer.addSublayer(topLeftLayer)

        topRightLayer.backgroundColor = UIColor.green.cgColor
        layer.addSublayer(topRightLayer)

        bottomLeftLayer.backgroundColor = UIColor.blue.cgColor
        layer.addSublayer(bottomLeftLayer)

        bottomRightLayer.backgroundColor = UIColor.yellow.cgColor
        layer.addSublayer(bottomRightLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Methods

    private let topLeftLayer: CALayer = .init()
    private let topRightLayer: CALayer = .init()
    private let bottomLeftLayer: CALayer = .init()
    private let bottomRightLayer: CALayer = .init()

    // MARK: - UIView

    override func layoutSubviews() {
        [topLeftLayer, topRightLayer, bottomLeftLayer, bottomRightLayer].forEach {
            $0.bounds.size = .init(width: bounds.width / 2, height: bounds.height / 2)
        }

        topLeftLayer.position = .init(x: bounds.width * 0.25, y: bounds.height * 0.25)
        topRightLayer.position = .init(x: bounds.width * 0.75, y: bounds.height * 0.25)
        bottomLeftLayer.position = .init(x: bounds.width * 0.25, y: bounds.height * 0.75)
        bottomRightLayer.position = .init(x: bounds.width * 0.75, y: bounds.height * 0.75)
    }

}
