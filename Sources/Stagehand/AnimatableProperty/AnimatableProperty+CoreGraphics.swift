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

extension CGAffineTransform: AnimatableProperty {

    /// Interpolates between the `initialValue` and `finalValue`.
    ///
    /// This supports transforms that are composed of translations, scales, and rotations; where `M' = R * S * T * M`.
    /// In order words, the matrix must be mutated in order of (1) translations, (2) scales, then (3) rotations. It does
    /// not support transforms that have had a skew/distort applied.
    public static func value(
        between initialValue: CGAffineTransform,
        and finalValue: CGAffineTransform,
        at progress: Double
    ) -> CGAffineTransform {
        let initialRotation = initialValue.rotation

        // Pick the shortest route to the between the transforms by adjusting the final angle by ±2π.
        let calculatedFinalRotation = finalValue.rotation
        let finalRotationCandidates = [
            calculatedFinalRotation - 2 * .pi,
            calculatedFinalRotation,
            calculatedFinalRotation + 2 * .pi
        ]
        let finalRotation = finalRotationCandidates.min(by: { abs($0 - initialRotation) < abs($1 - initialRotation) })!

        return CGAffineTransform.identity
            .translatedBy(
                x: CGFloat.value(between: initialValue.tx, and: finalValue.tx, at: progress),
                y: CGFloat.value(between: initialValue.ty, and: finalValue.ty, at: progress)
            )
            .scaledBy(
                x: CGFloat.value(between: initialValue.scaleX, and: finalValue.scaleX, at: progress),
                y: CGFloat.value(between: initialValue.scaleY, and: finalValue.scaleY, at: progress)
            )
            .rotated(
                by: CGFloat.value(between: initialRotation, and: finalRotation, at: progress)
            )
    }

    // MARK: - Private Computed Properties

    private var rotation: CGFloat {
        return atan2(b, d)
    }

    private var scaleX: CGFloat {
        let signProvider: CGFloat
        switch (a.sign, rotation) {
        case (.plus, (-.pi/2)...(.pi/2)):
            signProvider = 1
        case (.minus, (-.pi/2)...(.pi/2)), (.plus, _):
            signProvider = -1
        case (.minus, _):
            signProvider = 1
        }

        return CGFloat(signOf: signProvider, magnitudeOf: sqrt(a * a + c * c))
    }

    private var scaleY: CGFloat {
        let signProvider: CGFloat
        switch (d.sign, rotation) {
        case (.plus, (-.pi/2)...(.pi/2)):
            signProvider = 1
        case (.minus, (-.pi/2)...(.pi/2)), (.plus, _):
            signProvider = -1
        case (.minus, _):
            signProvider = 1
        }

        return CGFloat(signOf: signProvider, magnitudeOf: sqrt(b * b + d * d))
    }

}
