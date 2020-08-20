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

import CoreGraphics
import QuartzCore

internal struct Vector4 {

    // MARK: - Internal Properties

    var v1: CGFloat

    var v2: CGFloat

    var v3: CGFloat

    var v4: CGFloat

    // MARK: - Operators

    static func * (vector: Vector4, matrix: CATransform3D) -> Vector4 {
        return Vector4(
            v1: vector.v1 * matrix.m11 + vector.v2 * matrix.m21 + vector.v3 * matrix.m31 + vector.v4 * matrix.m41,
            v2: vector.v1 * matrix.m12 + vector.v2 * matrix.m22 + vector.v3 * matrix.m32 + vector.v4 * matrix.m42,
            v3: vector.v1 * matrix.m13 + vector.v2 * matrix.m23 + vector.v3 * matrix.m33 + vector.v4 * matrix.m43,
            v4: vector.v1 * matrix.m14 + vector.v2 * matrix.m24 + vector.v3 * matrix.m34 + vector.v4 * matrix.m44
        )
    }

}
