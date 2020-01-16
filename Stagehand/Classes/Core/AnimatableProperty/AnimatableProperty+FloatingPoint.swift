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

extension Float: AnimatableProperty {

    public static func value(between initialValue: Float, and finalValue: Float, at progress: Double) -> Float {
        return initialValue + Float(progress) * (finalValue - initialValue)
    }

}

extension Double: AnimatableProperty {

    public static func value(between initialValue: Double, and finalValue: Double, at progress: Double) -> Double {
        return initialValue + progress * (finalValue - initialValue)
    }

}
