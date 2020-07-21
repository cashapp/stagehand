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

import CoreGraphics

extension CGFloat: AnimatableProperty {

    public static func value(between initialValue: CGFloat, and finalValue: CGFloat, at progress: Double) -> CGFloat {
        return initialValue + CGFloat(progress) * (finalValue - initialValue)
    }

}

extension CGPoint: AnimatableProperty {

    public static func value(between initialValue: CGPoint, and finalValue: CGPoint, at progress: Double) -> CGPoint {
        return CGPoint(
            x: CGFloat.value(between: initialValue.x, and: finalValue.x, at: progress),
            y: CGFloat.value(between: initialValue.y, and: finalValue.y, at: progress)
        )
    }

}

extension CGSize: AnimatableProperty {

    public static func value(between initialValue: CGSize, and finalValue: CGSize, at progress: Double) -> CGSize {
        return CGSize(
            width: CGFloat.value(between: initialValue.width, and: finalValue.width, at: progress),
            height: CGFloat.value(between: initialValue.height, and: finalValue.height, at: progress)
        )
    }

}

extension CGRect: AnimatableProperty {

    public static func value(between initialValue: CGRect, and finalValue: CGRect, at progress: Double) -> CGRect {
        return CGRect(
            origin: CGPoint.value(between: initialValue.origin, and: finalValue.origin, at: progress),
            size: CGSize.value(between: initialValue.size, and: finalValue.size, at: progress)
        )
    }

}
