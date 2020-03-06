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

// Unfortunately, Swift doesn't support multiple conditional conformances for the same type, so we can't declare
// separate conformances of `Optional` to `AnimatableProperty` for each optional type that can be animated. To work
// around this, we can define the `AnimatableOptionalProperty` protocol and have `Optional` conform to
// `AnimatableProperty` whenever its `Wrapped` type conforms to this protocol.

/// Defines the interface of a type for which optional values of the type can be animated. More specifically,
/// interpolates between two optional values (the `initialValue` and `finalValue`) at a given `progress`.
public protocol AnimatableOptionalProperty {

    /// Returns an interpolation between the `initialValue` and `finalValue` at the given `progress` in the range.
    ///
    /// - parameter initialValue: The initial value of the interpolation, i.e. the value when the `progress` is 0.
    /// - parameter finalValue: The final value of the interpolation, i.e. the value when the `progress` is 1.
    /// - parameter progress: The progress along the interpolation, in the range `[0,1]`.
    static func optionalValue(between initialValue: Self?, and finalValue: Self?, at progress: Double) -> Self?

}

extension Optional: AnimatableProperty where Wrapped: AnimatableOptionalProperty {

    public static func value(between initialValue: Optional<Wrapped>, and finalValue: Optional<Wrapped>, at progress: Double) -> Optional<Wrapped> {
        return Wrapped.optionalValue(between: initialValue, and: finalValue, at: progress)
    }

}
