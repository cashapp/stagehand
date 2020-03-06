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
import UIKit

extension CGColor: AnimatableProperty {

    /// Interpolates between two `CGColor`s.
    ///
    /// If one or both of the colors cannot be represented in an RGBA color space, we will fall back to step-wise
    /// interpolation where the initial value is used in the range `[0,0.5)` and the final value is used in the range
    /// `[0.5,1]`.
    public static func value(between initialValue: CGColor, and finalValue: CGColor, at progress: Double) -> Self {
        guard
            let initialComponents = RGBAComponents(cgColor: initialValue),
            let finalComponents = RGBAComponents(cgColor: finalValue),
            initialComponents.colorSpace == finalComponents.colorSpace
        else {
            // We failed to get the RGBA components from at least one of the colors, or at least failed to get the
            // components converted into the same color space. Fall back to a non-animated behavior where the color
            // changes half way through the animation. This is less than ideal, but will still end the animation in the
            // correct place.
            let stepWiseValue = ((progress < 0.5) ? initialValue : finalValue)
            return valueOfSelf(from: stepWiseValue)
        }

        return self.init(
            colorSpace: initialComponents.colorSpace,
            components: [
                CGFloat.value(between: initialComponents.red, and: finalComponents.red, at: progress),
                CGFloat.value(between: initialComponents.green, and: finalComponents.green, at: progress),
                CGFloat.value(between: initialComponents.blue, and: finalComponents.blue, at: progress),
                CGFloat.value(between: initialComponents.alpha, and: finalComponents.alpha, at: progress),
            ]
        )!
    }

}

extension CGColor: AnimatableOptionalProperty {

    /// Interpolates between two optional `CGColor`s.
    ///
    /// A boundary value of `nil` is interpreted as a zero-alpha version of the opposite boundary value. If both
    /// boundary values are `nil`, all values between are `nil` as well.
    public static func optionalValue(between initialValue: CGColor?, and finalValue: CGColor?, at progress: Double) -> Self? {
        switch (initialValue, finalValue) {
        case (.none, .none):
            return nil

        case let (.some(initialColor), .some(finalColor)):
            return self.value(between: initialColor, and: finalColor, at: progress)

        case let (.none, .some(finalColor)):
            if let finalComponents = CGColor.RGBAComponents(cgColor: finalColor) {
                let initialColor = CGColor(
                    colorSpace: finalComponents.colorSpace,
                    components: [finalComponents.red, finalComponents.green, finalComponents.blue, 0]
                )!

                return self.value(between: initialColor, and: finalColor, at: progress)

            } else {
                return (progress < 0.5) ? nil : valueOfSelf(from: finalColor)
            }

        case let (.some(initialColor), .none):
            if let initialComponents = CGColor.RGBAComponents(cgColor: initialColor) {
                let finalColor = CGColor(
                    colorSpace: initialComponents.colorSpace,
                    components: [initialComponents.red, initialComponents.green, initialComponents.blue, 0]
                )!

                return self.value(between: initialColor, and: finalColor, at: progress)

            } else {
                return (progress < 0.5) ? valueOfSelf(from: initialColor) : nil
            }
        }
    }

}

extension UIColor: AnimatableProperty {

    public static func value(between initialValue: UIColor, and finalValue: UIColor, at progress: Double) -> Self {
        return self.init(cgColor: CGColor.value(between: initialValue.cgColor, and: finalValue.cgColor, at: progress))
    }

}

extension UIColor: AnimatableOptionalProperty {

    public static func optionalValue(
        between initialValue: UIColor?,
        and finalValue: UIColor?,
        at progress: Double
    ) -> Self? {
        return CGColor
            .optionalValue(between: initialValue?.cgColor, and: finalValue?.cgColor, at: progress)
            .map(self.init(cgColor:))
    }

}

extension CGColor {

    // MARK: - Private Static Methods

    private static func valueOfSelf(from cgColor: CGColor) -> Self {
        if let pattern = cgColor.pattern {
            return self.init(
                patternSpace: cgColor.colorSpace!,
                pattern: pattern,
                components: cgColor.components!
            )!
        } else {
            return self.init(
                colorSpace: cgColor.colorSpace!,
                components: cgColor.components!
            )!
        }
    }

    // MARK: - Private Types

    fileprivate struct RGBAComponents {

        // MARK: - Public Properties

        var red: CGFloat

        var green: CGFloat

        var blue: CGFloat

        var alpha: CGFloat

        var colorSpace: CGColorSpace

        // MARK: - Life Cycle

        init?(cgColor: CGColor) {
            // Try to use the P3 color space, since this is the widest display color space supported by current devices,
            // and fall back to device RGB if P3 is unavailable.
            self.colorSpace = CGColorSpace(name: CGColorSpace.displayP3) ?? CGColorSpaceCreateDeviceRGB()

            guard let rgbColor = cgColor.converted(to: colorSpace, intent: .defaultIntent, options: nil) else {
                return nil
            }

            guard let components = rgbColor.components, components.count == 4 else {
                return nil
            }

            self.red = components[0]
            self.green = components[1]
            self.blue = components[2]
            self.alpha = components[3]
        }

    }

}
