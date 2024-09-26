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

import CoreGraphics

// This logic is based on functionality in WebKit, which has the following copyrights:
//   Copyright (C) 2005, 2006, 2013 Apple Inc.  All rights reserved.
//   Copyright (C) 2009 Torch Mobile, Inc.

extension CGAffineTransform: AnimatableProperty {

    /// Interpolates between the `initialValue` and `finalValue`.
    public static func value(
        between initialValue: CGAffineTransform,
        and finalValue: CGAffineTransform,
        at progress: Double
    ) -> CGAffineTransform {
        var initialDecomposition: DecomposedMatrix = initialValue.decomposed()
        var finalDecomposition: DecomposedMatrix = finalValue.decomposed()

        // Prefer rotating over scaling when possible.
        let flippedFromNegativeXToNegativeY = initialDecomposition.scaleX < 0 && finalDecomposition.scaleY < 0
        let flippedFromNegativeYToNegativeX = initialDecomposition.scaleY < 0 && finalDecomposition.scaleX < 0
        if flippedFromNegativeXToNegativeY || flippedFromNegativeYToNegativeX {
            initialDecomposition.scaleX *= -1
            initialDecomposition.scaleY *= -1
            initialDecomposition.rotation += initialDecomposition.rotation < 0 ? .pi : -.pi
        }

        // Decomposed rotations are in the range `[-π, π]`. First convert them to `(0, 2π]` to make it easier to whether
        // the rotation is going the long way, and if so which one to change.

        if initialDecomposition.rotation <= 0 {
            initialDecomposition.rotation += 2 * .pi
        }

        if finalDecomposition.rotation <= 0 {
            finalDecomposition.rotation += 2 * .pi
        }

        if abs(initialDecomposition.rotation - finalDecomposition.rotation) > .pi {
            if initialDecomposition.rotation > finalDecomposition.rotation {
                initialDecomposition.rotation -= 2 * .pi
            } else {
                finalDecomposition.rotation -= 2 * .pi
            }
        }

        return CGAffineTransform.DecomposedMatrix(
            scaleX: CGFloat.value(between: initialDecomposition.scaleX, and: finalDecomposition.scaleX, at: progress),
            scaleY: CGFloat.value(between: initialDecomposition.scaleY, and: finalDecomposition.scaleY, at: progress),
            translateX: CGFloat.value(between: initialDecomposition.translateX, and: finalDecomposition.translateX, at: progress),
            translateY: CGFloat.value(between: initialDecomposition.translateY, and: finalDecomposition.translateY, at: progress),
            rotation: CGFloat.value(between: initialDecomposition.rotation, and: finalDecomposition.rotation, at: progress),
            m11: CGFloat.value(between: initialDecomposition.m11, and: finalDecomposition.m11, at: progress),
            m12: CGFloat.value(between: initialDecomposition.m12, and: finalDecomposition.m12, at: progress),
            m21: CGFloat.value(between: initialDecomposition.m21, and: finalDecomposition.m21, at: progress),
            m22: CGFloat.value(between: initialDecomposition.m22, and: finalDecomposition.m22, at: progress)
        ).recompose()
    }

}

// MARK: -

extension CGAffineTransform {

    // MARK: - Internal Methods

    /// Returns the decomposed values that make up the transform.
    ///
    /// Rotation values will be in the range `[-π, π]`.
    func decomposed() -> DecomposedMatrix {
        if isIdentity {
            return .init()
        }

        var matrix = self
        var decomposedMatrix = DecomposedMatrix()

        // Affine transforms are represented by a 3x3 matrix:
        //
        //   ┌─         ─┐
        //   │ a   b   0 │
        //   │           │
        //   │ c   d   0 │
        //   │           │
        //   │ tx  ty  1 │
        //   └─         ─┘
        //
        // The `a`, `b`, `c`, and `d` elements are made from a combination of applied scale, rotation, and shear
        // transforms. The `tx` and `ty` elements represent the translation.

        // Translation
        //
        //   ┌─         ─┐┌─           ─┐   ┌─                                       ─┐
        //   │ 1   0   0 ││  a    b   0 │   │         a                  b          0 │
        //   │           ││             │   │                                         │
        //   │ 0   1   0 ││  c    d   0 │ = │         c                  d          0 │
        //   │           ││             │   │                                         │
        //   │ tx  ty  1 ││ tx0  ty0  1 │   │ tx·a + ty·c + tx0  tx·b + ty·d + ty0  1 │
        //   └─         ─┘└─           ─┘   └─                                       ─┘

        // Since translation only affects the `tx` and `ty` elements, we can store those directly.
        decomposedMatrix.translateX = matrix.tx
        decomposedMatrix.translateY = matrix.ty

        // Scaling
        //
        //   ┌─         ─┐┌─         ─┐   ┌─             ─┐
        //   │ sx  0   0 ││ a   b   0 │   │ sx·a  sx·b  0 │
        //   │           ││           │   │               │
        //   │ 0   sy  0 ││ c   d   0 │ = │ sy·c  sy·d  0 │
        //   │           ││           │   │               │
        //   │ 0   0   1 ││ tx  ty  1 │   │  tx    ty   1 │
        //   └─         ─┘└─         ─┘   └─             ─┘

        decomposedMatrix.scaleX = hypot(matrix.a, matrix.b)
        decomposedMatrix.scaleY = hypot(matrix.c, matrix.d)

        let determinant = matrix.a * matrix.d - matrix.b * matrix.c

        // If determinant is negative, one axis was flipped.
        if determinant <= 0 {
            // Flip axis with minimum unit vector dot product.
            if matrix.a < matrix.d {
                decomposedMatrix.scaleX *= -1
            } else {
                decomposedMatrix.scaleY *= -1
            }
        }

        // Remove any (non-zero) scale factor.

        if decomposedMatrix.scaleX != 0 {
            matrix.a /= decomposedMatrix.scaleX
            matrix.b /= decomposedMatrix.scaleX
        }

        if decomposedMatrix.scaleY != 0 {
            matrix.c /= decomposedMatrix.scaleY
            matrix.d /= decomposedMatrix.scaleY
        }

        // Rotation
        //
        //   ┌─                  ─┐┌─         ─┐   ┌─                                             ─┐
        //   │  cos(Θ)  sin(Θ)  0 ││ a   b   0 │   │  cos(Θ)·a + sin(Θ)·c   cos(Θ)·b + sin(Θ)·d  0 │
        //   │                    ││           │   │                                               │
        //   │ -sin(Θ)  cos(Θ)  0 ││ c   d   0 │ = │ -sin(Θ)·a + cos(Θ)·c  -sin(Θ)·b + cos(Θ)·d  0 │
        //   │                    ││           │   │                                               │
        //   │    0       0     1 ││ tx  ty  1 │   │          tx                    ty           1 │
        //   └─                  ─┘└─         ─┘   └─                                             ─┘

        decomposedMatrix.rotation = atan2(matrix.b, matrix.a)

        // Reverse the rotation if necessary, then assign the remaining matrix values to the m** decomposed fields to
        // account for any shear transforms.
        if decomposedMatrix.rotation != 0 {
            // Since we already removed the scale factor from our matrix, we can use `-matrix.b` for `sin(-Θ)` and
            // `matrix.a` for `cos(-Θ)`.
            let sin = -matrix.b
            let cos = matrix.a

            decomposedMatrix.m11 = cos * matrix.a + sin * matrix.c
            decomposedMatrix.m12 = cos * matrix.b + sin * matrix.d
            decomposedMatrix.m21 = -sin * matrix.a + cos * matrix.c
            decomposedMatrix.m22 = -sin * matrix.b + cos * matrix.d

        } else {
            decomposedMatrix.m11 = matrix.a
            decomposedMatrix.m12 = matrix.b
            decomposedMatrix.m21 = matrix.c
            decomposedMatrix.m22 = matrix.d
        }

        return decomposedMatrix
    }

    // MARK: - Internal Types

    internal struct DecomposedMatrix: Equatable {

        // MARK: - Life Cycle

        init(
            scaleX: CGFloat = 1,
            scaleY: CGFloat = 1,
            translateX: CGFloat = 0,
            translateY: CGFloat = 0,
            rotation: CGFloat = 0,
            m11: CGFloat = 1,
            m12: CGFloat = 0,
            m21: CGFloat = 0,
            m22: CGFloat = 1
        ) {
            self.scaleX = scaleX
            self.scaleY = scaleY
            self.translateX = translateX
            self.translateY = translateY
            self.rotation = rotation
            self.m11 = m11
            self.m12 = m12
            self.m21 = m21
            self.m22 = m22
        }

        // MARK: - Internal Properties

        var scaleX: CGFloat

        var scaleY: CGFloat

        var translateX: CGFloat

        var translateY: CGFloat

        /// Rotation, in radians.
        var rotation: CGFloat

        var m11: CGFloat

        var m12: CGFloat

        var m21: CGFloat

        var m22: CGFloat

        // MARK: - Internal Methods

        func recompose() -> CGAffineTransform {
            let transform = CGAffineTransform(
                a: m11,
                b: m12,
                c: m21,
                d: m22,
                tx: translateX,
                ty: translateY
            )

            // Apply the rotation and scaling in the reverse order from how they were decomposed.
            return transform
                .rotated(by: rotation)
                .scaledBy(x: scaleX, y: scaleY)
        }

    }

}
