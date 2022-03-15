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

public struct LinearAnimationCurve: AnimationCurve {

    public init() {}

    public func adjustedProgress(for progress: Double) -> Double {
        return progress
    }

    public func rawProgress(for adjustedProgress: Double) -> [Double] {
        return [adjustedProgress]
    }

}

// MARK: -

/// A simple ease in curve.
///
/// In general, cubic Bézier curves are preferred over parabolic curves as the smoother easing function; however, a
/// parabolic curve is significantly simpler to calculate. It is therefore recommended to start by using a cubic Bézier
/// curve (`CubicBezierAnimationCurve.easeIn`) and switch to a parabolic curve if performance becomes an issue.
public struct ParabolicEaseInAnimationCurve: AnimationCurve {

    public init() {}

    public func adjustedProgress(for progress: Double) -> Double {
        return pow(progress, 2.0)
    }

    public func rawProgress(for adjustedProgress: Double) -> [Double] {
        return [sqrt(adjustedProgress)]
    }

}

// MARK: -

/// A simple ease out curve.
///
/// In general, cubic Bézier curves are preferred over parabolic curves as the smoother easing function; however, a
/// parabolic curve is significantly simpler to calculate. It is therefore recommended to start by using a cubic Bézier
/// curve (`CubicBezierAnimationCurve.easeOut`) and switch to a parabolic curve if performance becomes an issue.
public struct ParabolicEaseOutAnimationCurve: AnimationCurve {

    public init() {}

    public func adjustedProgress(for progress: Double) -> Double {
        return 1 - pow(1 - progress, 2.0)
    }

    public func rawProgress(for adjustedProgress: Double) -> [Double] {
        return [1 - sqrt(1 - adjustedProgress)]
    }

}

// MARK: -

/// A simple ease in ease out curve.
///
/// In general, cubic Bézier curves are preferred over sinusoidal curves as the smoother easing function; however, a
/// sinusoidal curve is significantly simpler to calculate. It is therefore recommended to start by using a cubic Bézier
/// curve (`CubicBezierAnimationCurve.easeInEaseOut`) and switch to a sinusoidal curve if performance becomes an issue.
public struct SinusoidalEaseInEaseOutAnimationCurve: AnimationCurve {

    public init() {}

    public func adjustedProgress(for progress: Double) -> Double {
        return 0.5 - cos(progress * .pi) * 0.5
    }

    public func rawProgress(for adjustedProgress: Double) -> [Double] {
        return [acos(1 - 2 * adjustedProgress) / .pi]
    }

}
