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

enum ShapeLayerUtils {

    /// Sets the layer's path to a stroked grid with the given number of rows and columns
    static func addGridPath(to layer: CAShapeLayer, rows: Int, columns: Int) {
        let gridPath: UIBezierPath = .init()
        let cellSize: CGSize = .init(
            width: layer.bounds.width / CGFloat(columns),
            height: layer.bounds.height / CGFloat(rows)
        )
        for row in 0...rows {
            gridPath.move(to: .init(x: 0, y: cellSize.height * CGFloat(row)))
            gridPath.addLine(to: .init(x: layer.bounds.width, y: cellSize.height * CGFloat(row)))
        }
        for column in 0...columns {
            gridPath.move(to: .init(x: cellSize.width * CGFloat(column), y: 0))
            gridPath.addLine(to: .init(x: cellSize.width * CGFloat(column), y: layer.bounds.height))
        }
        layer.path = gridPath.cgPath
    }

}
