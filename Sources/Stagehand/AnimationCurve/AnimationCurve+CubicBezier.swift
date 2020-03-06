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

/// An animation curve that follows a cubic Bézier curve that starts at `(0,0)` and goes to `(1,1)`, with two control
/// points.
///
/// The control points must be positioned such that X(t₂) > X(t₁) when t₂ > t₁.
public struct CubicBezierAnimationCurve: AnimationCurve {

    // MARK: - Life Cycle

    public init(controlPoints controlPoint1: (Double, Double), _ controlPoint2: (Double, Double)) {
        self.controlPoint1 = controlPoint1
        self.controlPoint2 = controlPoint2
    }

    // MARK: - Private Properties

    private let controlPoint1: (x: Double, y: Double)

    private let controlPoint2: (x: Double, y: Double)

    // MARK: - Animation Curve

    public func adjustedProgress(for progress: Double) -> Double {
        // The animation curve is defined as a cubic bezier curve where the x-axis is the raw progress and the y-axis is
        // the adjusted progress.

        // First, we need to calculate the `t` of the curve given the `x` value.
        //
        // X(t) = (1-t)^3 * X₀ + 3*(1-t)^2 * t * X₁ + 3*(1-t) * t^2 * X₂ + t^3 * X₃
        //      = (-X₀ + 3 * X₁ - 3 * X₂ + X₃) * t^3 + (3 * X₀ - 6 * X₁ + 3 * X₂) * t^2 + (-3 * X₀ + 3 * X₁) * t + X₀
        //
        // The first point is always (0,0), so X₀ = 0.
        // X₁ and X₂ are out control points, so `controlPoint1.x` and `controlPoint2.x`, respectively.
        // The last point is always (1,1), so X₃ = 1.
        //
        // (3 * X₁ - 3 * X₂ + 1) * t^3 + (-6 * X₁ + 3 * X₂) * t^2 + (3 * X₁) * t - X(t) = 0

        let ts = cubicRoots(
            a: (3 * controlPoint1.x - 3 * controlPoint2.x + 1),
            b: (-6 * controlPoint1.x + 3 * controlPoint2.x),
            c: (3 * controlPoint1.x),
            d: -progress
        )

        guard let t = ts.first else {
            // We can't determine the roots of the curve, so fall back to a linear curve.
            return progress
        }

        // Now that we have the value of `t`, we can calculate our adjusted progress by solving Y(t).
        //
        // Y(t) = (1-t)^3 * Y₀ + 3*(1-t)^2 * t * Y₁ + 3*(1-t) * t^2 * Y₂ + t^3 * Y₃
        //      = 3 * (1-t)^2 * t * Y₁ + 3 * (1-t) * t^2 * Y₂ + t^3

        let y1 = 3 * (1 - t) * (1 - t) * t * controlPoint1.y
        let y2 = 3 * (1 - t) * t * t * controlPoint2.y
        let y3 = t * t * t
        return y1 + y2 + y3
    }

    // MARK: - Private Methods

    /// Returns the cubic roots of the function `ax^3 + bx^2 + cx + d = 0`.
    ///
    /// This uses Cardano's Algorithm to determine the cubic roots.
    ///
    /// References:
    /// * <https://pomax.github.io/bezierinfo/>
    /// * <https://trans4mind.com/personal_development/mathematics/polynomials/cubicAlgebra.htm>
    private func cubicRoots(a: Double, b: Double, c: Double, d: Double) -> [Double] {
        let ε = 0.000000001

        guard abs(a) >= ε || abs(b) >= ε || abs(c) >= ε else {
            // There is no solution for this curve.
            return []
        }

        guard abs(a) >= ε || abs(b) >= ε else {
            // This is actually a linear curve.
            return [
                (-c / b),
            ].filter { 0 <= $0 && $0 <= 1}
        }

        guard abs(a) >= ε else {
            // This is actually a quadratic curve.
            let q = sqrt(b * b - 4 * a * c)

            return [
                (q - b)/(2 * a),
                (-q - b)/(2 * a),
            ].filter { 0 <= $0 && $0 <= 1 }
        }

        // Normalize the equation into `x^3 + ax^2 + bx + c = 0`
        let na = b / a
        let nb = c / a
        let nc = d / a

        let p = (3 * nb - na * na) / 3
        let q = ((2 * na * na * na) - (9 * na * nb) + (27 * nc)) / 27
        let discriminant = (q * q) / 4 + (p * p * p) / 27

        let roots: [Double]
        switch discriminant {
        case 0:
            /// The discriminant is zero, so all of the roots are real, but two of them are equal.
            let u1 = cbrt(-q / 2)

            roots = [
                (2 * u1 - na / 3),
                (-u1 - na / 3),
            ]

        case 0...:
            // The discriminant is positive, so only one of the roots is a real number.
            let sd = sqrt(discriminant)
            let u1 = cbrt(sd - (q / 2))
            let v1 = cbrt(sd + (q / 2))

            roots = [
                (u1 - v1 - (na / 3)),
            ]

        default:
            // The discriminant is negative, so all of the roots are (unique) real numbers.
            let r = sqrt(p * p * p / -27)
            let cosphi = (-q / (2 * r)).clamped(in: -1...1)
            let phi = acos(cosphi)
            let w = 2 * cbrt(r)

            roots = [
                (w * cos(phi / 3) - na / 3),
                (w * cos((phi + 2 * .pi) / 3) - na / 3),
                (w * cos((phi + 4 * .pi) / 3) - na / 3),
            ]
        }

        return roots.filter { 0 <= $0 && $0 <= 1 }
    }

}

// MARK: -

extension CubicBezierAnimationCurve {

    public static let easeInEaseOut: CubicBezierAnimationCurve = .init(controlPoints: (0.42, 0.0), (0.58, 1.0))

    public static let easeIn: CubicBezierAnimationCurve = .init(controlPoints: (0.42, 0.0), (1.0, 1.0))

    public static let easeOut: CubicBezierAnimationCurve = .init(controlPoints: (0.0, 0.0), (0.58, 1.0))

}

// MARK: -

extension CubicBezierAnimationCurve: Equatable {

    public static func == (lhs: CubicBezierAnimationCurve, rhs: CubicBezierAnimationCurve) -> Bool {
        return lhs.controlPoint1 == rhs.controlPoint1 && lhs.controlPoint2 == rhs.controlPoint2
    }

}
