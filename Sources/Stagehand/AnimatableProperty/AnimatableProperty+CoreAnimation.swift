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

import QuartzCore

extension CATransform3D: AnimatableProperty {

    public static func value(
        between initialValue: CATransform3D,
        and finalValue: CATransform3D,
        at progress: Double
    ) -> CATransform3D {
        return .init(
            m11: CGFloat.value(between: initialValue.m11, and: finalValue.m11, at: progress),
            m12: CGFloat.value(between: initialValue.m12, and: finalValue.m12, at: progress),
            m13: CGFloat.value(between: initialValue.m13, and: finalValue.m13, at: progress),
            m14: CGFloat.value(between: initialValue.m14, and: finalValue.m14, at: progress),
            m21: CGFloat.value(between: initialValue.m21, and: finalValue.m21, at: progress),
            m22: CGFloat.value(between: initialValue.m22, and: finalValue.m22, at: progress),
            m23: CGFloat.value(between: initialValue.m23, and: finalValue.m23, at: progress),
            m24: CGFloat.value(between: initialValue.m24, and: finalValue.m24, at: progress),
            m31: CGFloat.value(between: initialValue.m31, and: finalValue.m31, at: progress),
            m32: CGFloat.value(between: initialValue.m32, and: finalValue.m32, at: progress),
            m33: CGFloat.value(between: initialValue.m33, and: finalValue.m33, at: progress),
            m34: CGFloat.value(between: initialValue.m34, and: finalValue.m34, at: progress),
            m41: CGFloat.value(between: initialValue.m41, and: finalValue.m41, at: progress),
            m42: CGFloat.value(between: initialValue.m42, and: finalValue.m42, at: progress),
            m43: CGFloat.value(between: initialValue.m43, and: finalValue.m43, at: progress),
            m44: CGFloat.value(between: initialValue.m44, and: finalValue.m44, at: progress)
        )
    }

}
