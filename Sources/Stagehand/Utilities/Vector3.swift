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

import Foundation

internal struct Vector3 {

    // MARK: - Public Properties

    var v1: CGFloat

    var v2: CGFloat

    var v3: CGFloat

    // MARK: - Public Methods

    func length() -> CGFloat {
        return sqrt(v1 * v1 + v2 * v2 + v3 * v3)
    }

    func cross(_ other: Vector3) -> Vector3 {
        return .init(
            v1: (self.v2 * other.v3) - (self.v3 * other.v2),
            v2: (self.v3 * other.v1) - (self.v1 * other.v3),
            v3: (self.v1 * other.v2) - (self.v2 * other.v1)
        )
    }

    func dot(_ other: Vector3) -> CGFloat {
        return (self.v1 * other.v1) + (self.v2 * other.v2) + (self.v3 * other.v3)
    }

    mutating func normalize() {
        let length = self.length()
        guard length != 0 else {
            return
        }

        let multiplier = (1 / length)
        v1 *= multiplier
        v2 *= multiplier
        v3 *= multiplier
    }

    // MARK: - Operators

    static func * (left: CGFloat, right: Vector3) -> Vector3 {
        return Vector3(v1: left * right.v1, v2: left * right.v2, v3: left * right.v3)
    }

    static func + (left: Vector3, right: Vector3) -> Vector3 {
        return Vector3(v1: left.v1 + right.v1, v2: left.v2 + right.v2, v3: left.v3 + right.v3)
    }

}
