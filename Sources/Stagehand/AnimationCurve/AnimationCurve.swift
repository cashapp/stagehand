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

/// Defines the interface for a function that controls the apparent progress of an animation. More specifically, it
/// converts a "raw" progress amount (in the range `[0,1]`, where 0 is the start of the animation and 1 is the end of
/// the animation) to a curved progress amount.
///
/// The domain of the function is strictly bounded to `[0,1]`. The range of the function is technically unbounded, but
/// in most cases will also be `[0,1]`. In any case, the function should be defined such that `f(0) = 0` and `f(1) = 1`;
/// otherwise the animation will not end on the specified final keyframes.
public protocol AnimationCurve: Sendable {

    func adjustedProgress(for progress: Double) -> Double

    /// The raw (uncurved) progress values that correspond to the specified adjusted (curved) progress.
    ///
    /// Note that unlike the raw -> adjusted calculation that always results in one value, there may be multiple raw
    /// values corresponding to one adjusted value. In other words, X(t) is monotonic, but Y(t) is not.
    func rawProgress(for adjustedProgress: Double) -> [Double]

}
