//
//  Copyright 2025 Block Inc.
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

public struct SpringAnimationCurve: AnimationCurve {

    /// - parameter damping: The damping ratio applied to the spring. Values should be in the range `[0,1]` where `1` means no oscillation (just smooth deceleration).
    /// - parameter initialVelocity: The velocity at the start of the animation.
    /// - parameter naturalFrequency: The natural frequency of the spring, which controls how "stiff" it feels. Higher values will cause the spring to bounce more times.
    public init(damping: CGFloat, initialVelocity: CGFloat, naturalFrequency: CGFloat = 10) {
        self.damping = damping
        self.initialVelocity = initialVelocity
        self.naturalFrequency = naturalFrequency
    }

    private let damping: CGFloat
    private let initialVelocity: CGFloat
    private let naturalFrequency: CGFloat

    public func adjustedProgress(for progress: Double) -> Double {
        // Since the curve always starts at `(0,0)` and ends at `(1,1)`, these values should always be the same. Early
        // return with the appropriate values here to avoid extra work and potential for rounding error.
        if progress <= 0 {
            return 0
        } else if progress >= 1 {
            return 1
        }

        let dampingRatio = min(max(Double(damping), 0.0), 1.0)
        let dampedFrequency = naturalFrequency * sqrt(1.0 - dampingRatio * dampingRatio)
        let expTerm = exp(-dampingRatio * naturalFrequency * progress)

        // Note we reverse the sign of initial velocity here to make the input velocity be _towards_ the final destination.
        let velocity = -Double(initialVelocity) * naturalFrequency

        let springValue: Double
        if dampingRatio >= 1.0 {
            // Critically damped or overdamped spring
            springValue = 1.0 - expTerm * (1.0 + (dampingRatio * naturalFrequency + velocity) * progress)
        } else {
            // Underdamped spring (with oscillation)
            let sinCoeff = velocity / dampedFrequency + (dampingRatio * naturalFrequency) / dampedFrequency
            springValue = 1.0 - expTerm * (cos(dampedFrequency * progress) + sinCoeff * sin(dampedFrequency * progress))
        }

        // Apply a progressive damping effect to force convergence as we approach the end of curve.
        let endDampingStart = 0.7

        if progress > endDampingStart {
            // Calculate how far into the damping region we are (0 to 1).
            let dampingFactor = (progress - endDampingStart) / (1.0 - endDampingStart)

            // Blend between spring value and 1.0 to smoothly transition into the end.
            let smoothDampingFactor = dampingFactor * dampingFactor * (3.0 - 2.0 * dampingFactor)
            return springValue * (1.0 - smoothDampingFactor) + 1.0 * smoothDampingFactor
        } else {
            return springValue
        }
    }

    public func rawProgress(for adjustedProgress: Double) -> [Double] {
        // This logic doesn't always work correctly for adjustedProgress above 1, so just return empty results for now. In practice this should never be called for values outside [0,1].
        if adjustedProgress < 0 || adjustedProgress > 1 {
            return []
        }

        let sampleCount = 100
        var crossingPoints: [Double] = []
        var prevValue = -adjustedProgress

        for i in 1...sampleCount {
            let t = Double(i) / Double(sampleCount)
            let currentValue = self.adjustedProgress(for: t) - adjustedProgress

            // If we crossed zero, we found a crossing point.
            if prevValue * currentValue <= 0.0 {
                // Use linear interpolation to approximate where between the two values the crossing occured.
                let ratio = abs(prevValue) / (abs(prevValue) + abs(currentValue))
                let refinedT = t - Double(1) / Double(sampleCount) + ratio * Double(1) / Double(sampleCount)

                if refinedT >= 0.0 && refinedT <= 1.0 {
                    let isUnique = crossingPoints.allSatisfy { abs($0 - refinedT) > 0.01 }
                    if isUnique {
                        crossingPoints.append(refinedT)
                    }
                }
            }

            prevValue = currentValue
        }

        // When no crossing points are found, approximate the nearest value.
        if crossingPoints.isEmpty {
            var bestT = 0.0
            var minDiff = Double.infinity

            for i in 0...sampleCount {
                let t = Double(i) / Double(sampleCount)
                let diff = abs(self.adjustedProgress(for: t) - adjustedProgress)
                if diff < minDiff {
                    minDiff = diff
                    bestT = t
                }
            }

            return [bestT]
        }

        return crossingPoints
    }
}
