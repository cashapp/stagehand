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

import Foundation

struct Quaternion: Equatable {

    // MARK: - Internal Properties

    var x: CGFloat = 0

    var y: CGFloat = 0

    var z: CGFloat = 0

    var w: CGFloat = 1

    // MARK: - Internal Static Methods

    /// Interpolate between two quaternions using spherical linear interpolation.
    static func value(
        between initialValue: Quaternion,
        and finalValue: Quaternion,
        at progress: Double
    ) -> Quaternion {
        var initialValue = initialValue
        var finalValue = finalValue
        let progress = CGFloat(progress)

        var angle = initialValue.x * finalValue.x
                    + initialValue.y * finalValue.y
                    + initialValue.z * finalValue.z
                    + initialValue.w * finalValue.w

        if angle < 0 {
            initialValue.x *= -1
            initialValue.y *= -1
            initialValue.z *= -1
            initialValue.w *= -1
            angle *= -1
        }

        let scale: CGFloat
        let invscale: CGFloat
        if angle + 1 > 0.05 && 1 - angle >= 0.05 {
            let th = acos(angle)
            let invth = 1 / sin(th)
            scale = sin(th * (1 - progress)) * invth
            invscale = sin(th * progress) * invth

        } else if angle + 1 > 0.05 {
            scale = 1 - progress
            invscale = progress

        } else {
            finalValue.x = -initialValue.y
            finalValue.y = initialValue.x
            finalValue.z = -initialValue.w
            finalValue.w = initialValue.z

            scale = sin(.pi * (0.5 - progress))
            invscale = sin(.pi * progress)
        }

        return Quaternion(
            x: initialValue.x * scale + finalValue.x * invscale,
            y: initialValue.y * scale + finalValue.y * invscale,
            z: initialValue.z * scale + finalValue.z * invscale,
            w: initialValue.w * scale + finalValue.w * invscale
        )
    }

}
