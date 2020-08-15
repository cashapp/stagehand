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

import UIKit

extension CATransform3D: AnimatableProperty {

    // MARK: - AnimatableProperty

    public static func value(
        between initialValue: CATransform3D,
        and finalValue: CATransform3D,
        at progress: Double
    ) -> CATransform3D {
        let initialDecomposition = initialValue.decomposed()
        let finalDecomposition = finalValue.decomposed()

        switch (initialDecomposition, finalDecomposition) {
        case let (.some(initialDecomposition), .some(finalDecomposition)):
            return decomposition(between: initialDecomposition, and: finalDecomposition, at: progress).recompose()

        case let (.some(initialDecomposition), .none):
            // If we failed to decompose the final transform, it means that at least one of the axes has a scale of
            // zero. Since we can't tell which, treat them all as zero. Set the other decomposed fields to match the
            // initial transform so that we get a smooth transition.
            var finalDecomposition = initialDecomposition
            finalDecomposition.scaleX = 0
            finalDecomposition.scaleY = 0
            finalDecomposition.scaleZ = 0
            return decomposition(between: initialDecomposition, and: finalDecomposition, at: progress).recompose()

        case let (.none, .some(finalDecomposition)):
            // Do the same thing as the previous case, but in reverse.
            var initialDecomposition = finalDecomposition
            initialDecomposition.scaleX = 0
            initialDecomposition.scaleY = 0
            initialDecomposition.scaleZ = 0
            return decomposition(between: initialDecomposition, and: finalDecomposition, at: progress).recompose()

        case (.none, .none):
            // We failed to decompose both of the transforms. Fall back to an immediate change at the halfway point.
            return progress > 0.5 ? finalValue : initialValue
        }
    }

    // MARK: - Private Methods

    private static func decomposition(
        between initialDecomposition: CATransform3D.DecomposedTransform,
        and finalDecomposition: CATransform3D.DecomposedTransform,
        at progress: Double
    ) -> CATransform3D.DecomposedTransform {
        return CATransform3D.DecomposedTransform(
            scaleX: CGFloat.value(between: initialDecomposition.scaleX, and: finalDecomposition.scaleX, at: progress),
            scaleY: CGFloat.value(between: initialDecomposition.scaleY, and: finalDecomposition.scaleY, at: progress),
            scaleZ: CGFloat.value(between: initialDecomposition.scaleZ, and: finalDecomposition.scaleZ, at: progress),
            skewXY: CGFloat.value(between: initialDecomposition.skewXY, and: finalDecomposition.skewXY, at: progress),
            skewXZ: CGFloat.value(between: initialDecomposition.skewXZ, and: finalDecomposition.skewXZ, at: progress),
            skewYZ: CGFloat.value(between: initialDecomposition.skewYZ, and: finalDecomposition.skewYZ, at: progress),
            rotation: Quaternion.value(between: initialDecomposition.rotation, and: finalDecomposition.rotation, at: progress),
            translateX: CGFloat.value(between: initialDecomposition.translateX, and: finalDecomposition.translateX, at: progress),
            translateY: CGFloat.value(between: initialDecomposition.translateY, and: finalDecomposition.translateY, at: progress),
            translateZ: CGFloat.value(between: initialDecomposition.translateZ, and: finalDecomposition.translateZ, at: progress),
            perspectiveX: CGFloat.value(between: initialDecomposition.perspectiveX, and: finalDecomposition.perspectiveX, at: progress),
            perspectiveY: CGFloat.value(between: initialDecomposition.perspectiveY, and: finalDecomposition.perspectiveY, at: progress),
            perspectiveZ: CGFloat.value(between: initialDecomposition.perspectiveZ, and: finalDecomposition.perspectiveZ, at: progress),
            perspectiveW: CGFloat.value(between: initialDecomposition.perspectiveW, and: finalDecomposition.perspectiveW, at: progress)
        )
    }

}

// MARK: -

extension CATransform3D {

    // This logic is based on functionality in WebKit, which has the following copyrights:
    //   Copyright (C) 2005, 2006, 2013 Apple Inc.  All rights reserved.
    //   Copyright (C) 2009 Torch Mobile, Inc.

    // MARK: - Internal Methods

    internal func decomposed() -> DecomposedTransform? {
        guard !CATransform3DIsIdentity(self) else {
            return .init()
        }

        var matrix = self

        guard matrix.m44 != 0 else {
            return nil
        }

        // Normalize the matrix.
        matrix.normalize()

        var perspectiveMatrix = matrix
        perspectiveMatrix.m14 = 0
        perspectiveMatrix.m24 = 0
        perspectiveMatrix.m34 = 0
        perspectiveMatrix.m44 = 1

        // If the matrix is singular, we won't be able to solve for perspective.
        guard perspectiveMatrix.determinant() != 0 else {
            return nil
        }

        var decomposedTransform = DecomposedTransform()

        if matrix.m14 != 0 || matrix.m24 != 0 || matrix.m34 != 0 {
            let rightHandSide = Vector4(v1: matrix.m14, v2: matrix.m24, v3: matrix.m34, v4: matrix.m44)
            let transposedInversePerspectiveMatrix = CATransform3DInvert(perspectiveMatrix).transposed()
            let perspectivePoint = rightHandSide * transposedInversePerspectiveMatrix

            decomposedTransform.perspectiveX = perspectivePoint.v1
            decomposedTransform.perspectiveY = perspectivePoint.v2
            decomposedTransform.perspectiveZ = perspectivePoint.v3
            decomposedTransform.perspectiveW = perspectivePoint.v4

            matrix = perspectiveMatrix
        }

        // Translate
        //
        //   ┌─             ─┐┌─                  ─┐   ┌─                                     ─┐
        //   │ 1   0   0   0 ││ m11  m12  m13  m14 │   │              m11                      │
        //   │               ││                    │   │                                       │
        //   │ 0   1   0   0 ││ m21  m22  m23  m24 │   │              m21                      │
        //   │               ││                    │ = │                                  ...  │
        //   │ 0   0   1   0 ││ m31  m32  m33  m34 │   │              m31                      │
        //   │               ││                    │   │                                       │
        //   │ tx  ty  tz  1 ││ m41  m42  m43  m44 │   │ tx·m11 + ty·m21 + tz·m31 + m41        │
        //   └─             ─┘└─                  ─┘   └─                                     ─┘
        //
        // Since translation only changes the bottom row of the matrix, we can pull the translation out directly.

        decomposedTransform.translateX = matrix.m41
        decomposedTransform.translateY = matrix.m42
        decomposedTransform.translateZ = matrix.m43

        var row1 = Vector3(v1: matrix.m11, v2: matrix.m12, v3: matrix.m13)
        var row2 = Vector3(v1: matrix.m21, v2: matrix.m22, v3: matrix.m23)
        var row3 = Vector3(v1: matrix.m31, v2: matrix.m32, v3: matrix.m33)

        // Scale
        //
        //   ┌─             ─┐┌─                  ─┐   ┌─                              ─┐
        //   │ sx  0   0   0 ││ m11  m12  m13  m14 │   │ sx·m11  sx·m12  sx·m13  sx·m14 │
        //   │               ││                    │   │                                │
        //   │ 0   sy  0   0 ││ m21  m22  m23  m24 │   │ sy·m21  sy·m22  sy·m23  sy·m24 │
        //   │               ││                    │ = │                                │
        //   │ 0   0   sz  0 ││ m31  m32  m33  m34 │   │ sz·m31  sz·m32  sz·m33  sz·m34 │
        //   │               ││                    │   │                                │
        //   │ 0   0   0   1 ││ m41  m42  m43  m44 │   │  m41     m42     m43     m44   │
        //   └─             ─┘└─                  ─┘   └─                              ─┘
        //
        // Shear
        //
        //   ┌─                ─┐┌─                  ─┐
        //   │  1   syx  szx  0 ││ m11  m12  m13  m14 │
        //   │                  ││                    │
        //   │ sxy   1   szy  0 ││ m21  m22  m23  m24 │
        //   │                  ││                    │ = ...
        //   │ sxz  syz   1   0 ││ m31  m32  m33  m34 │
        //   │                  ││                    │
        //   │  0    0    0   1 ││ m41  m42  m43  m44 │
        //   └─                ─┘└─                  ─┘
        //
        // We only decompose the XY, XZ, and YZ shears. The remaining values will be treated as part of the rotation.
        // This isn't ideal, but it's tough to differentiate between two shears with the same pinned axis and a rotation
        // around that axis (e.g. an XY shear plus a YX shear looks the same as rotating around the Z axis).

        decomposedTransform.scaleX = row1.length()
        row1.normalize()

        decomposedTransform.skewXY = row1.dot(row2)

        // Make row 2 orthogonal to row 1.
        row2 = row2 + (-decomposedTransform.skewXY * row1)

        decomposedTransform.scaleY = row2.length()
        row2.normalize()
        decomposedTransform.skewXY /= decomposedTransform.scaleY

        // Calculate XZ and YZ shears and orthagonalize row 3.
        decomposedTransform.skewXZ = row1.dot(row3)
        row3 = row3 + (-decomposedTransform.skewXZ * row1)

        decomposedTransform.skewYZ = row2.dot(row3)
        row3 = row3 + (-decomposedTransform.skewYZ * row2)

        decomposedTransform.scaleZ = row3.length()
        row3.normalize()
        decomposedTransform.skewXZ /= decomposedTransform.scaleZ
        decomposedTransform.skewYZ /= decomposedTransform.scaleZ

        // The rows are now orthonormal. Check for a coordinate system flip before moving on to rotation.
        let determinant = row1.dot(row2.cross(row3))
        if determinant < 0 {
            decomposedTransform.scaleX *= -1
            decomposedTransform.scaleY *= -1
            decomposedTransform.scaleZ *= -1

            row1 = -1 * row1
            row2 = -1 * row2
            row3 = -1 * row3
        }

        // Rotate
        //
        // The `CATransform3DRotate` method rotates the transform by a specified angle around an arbitrary axis. This
        // rotation could be broken down into three separate rotations, one around each of the axes, but this has the
        // potential to result in gimbal lock while we're interpolating. Instead, we'll decompose the rotation into
        // quaternions.

        let t = row1.v1 + row2.v2 + row3.v3 + 1
        if t > 1e-4 {
            let s = 0.5 / sqrt(t)
            decomposedTransform.rotation.x = (row3.v2 - row2.v3) * s
            decomposedTransform.rotation.y = (row1.v3 - row3.v1) * s
            decomposedTransform.rotation.z = (row2.v1 - row1.v2) * s
            decomposedTransform.rotation.w = 0.25 / s

        } else if row1.v1 > row2.v2 && row1.v1 > row3.v3 {
            let s = sqrt(1 + row1.v1 - row2.v2 - row3.v3) * 2
            decomposedTransform.rotation.x = 0.25 * s
            decomposedTransform.rotation.y = (row1.v2 + row2.v1) / s
            decomposedTransform.rotation.z = (row1.v3 + row3.v1) / s
            decomposedTransform.rotation.w = (row3.v2 - row2.v3) / s

        } else if row2.v2 > row3.v3 {
            let s = sqrt(1 + row2.v2 - row1.v1 - row3.v3) * 2
            decomposedTransform.rotation.x = (row1.v2 + row2.v1) / s
            decomposedTransform.rotation.y = 0.25 * s
            decomposedTransform.rotation.z = (row2.v3 + row3.v2) / s
            decomposedTransform.rotation.w = (row1.v3 - row3.v1) / s

        } else {
            let s = sqrt(1 + row3.v3 - row1.v1 - row2.v2) * 2
            decomposedTransform.rotation.x = (row1.v3 + row3.v1) / s
            decomposedTransform.rotation.y = (row2.v3 + row3.v2) / s
            decomposedTransform.rotation.z = 0.25 * s
            decomposedTransform.rotation.w = (row2.v1 - row1.v2) / s
        }

        return decomposedTransform
    }

    // MARK: - Private Methods

    /// Normalizes the matrix.
    ///
    /// If `m44 = 0`, this method will no-op.
    private mutating func normalize() {
        guard m44 != 0 else {
            return
        }

        let members: [WritableKeyPath<CATransform3D, CGFloat>] = [
            \.m11, \.m12, \.m13, \.m14,
            \.m21, \.m22, \.m23, \.m24,
            \.m31, \.m32, \.m33, \.m34,
            \.m41, \.m42, \.m43, \.m44,
        ]

        for member in members {
            self[keyPath: member] /= m44
        }
    }

    /// Calculate the determinant of the matrix.
    private func determinant() -> CGFloat {
        return m11 * determinant3x3(m11: m22, m12: m23, m13: m24, m21: m32, m22: m33, m23: m34, m31: m42, m32: m43, m33: m44)
             - m21 * determinant3x3(m11: m12, m12: m13, m13: m14, m21: m32, m22: m33, m23: m34, m31: m42, m32: m43, m33: m44)
             + m31 * determinant3x3(m11: m12, m12: m13, m13: m14, m21: m22, m22: m23, m23: m24, m31: m42, m32: m43, m33: m44)
             - m41 * determinant3x3(m11: m12, m12: m13, m13: m14, m21: m22, m22: m23, m23: m24, m31: m32, m32: m33, m33: m34)
    }

    /// Calculate the determinant of a 3x3 matrix.
    private func determinant3x3(
        m11: CGFloat, m12: CGFloat, m13: CGFloat,
        m21: CGFloat, m22: CGFloat, m23: CGFloat,
        m31: CGFloat, m32: CGFloat, m33: CGFloat
    ) -> CGFloat {
        return m11 * determinant2x2(m11: m22, m12: m23, m21: m32, m22: m33)
             - m21 * determinant2x2(m11: m12, m12: m13, m21: m32, m22: m33)
             + m31 * determinant2x2(m11: m12, m12: m13, m21: m22, m22: m23)
    }

    /// Calculate the determinant of a 2x2 matrix.
    private func determinant2x2(
        m11: CGFloat, m12: CGFloat,
        m21: CGFloat, m22: CGFloat
    ) -> CGFloat {
        return (m11 * m22) - (m12 * m21)
    }

    private func transposed() -> CATransform3D {
        return CATransform3D(
            m11: m11, m12: m21, m13: m31, m14: m41,
            m21: m12, m22: m22, m23: m32, m24: m42,
            m31: m13, m32: m23, m33: m33, m34: m43,
            m41: m14, m42: m24, m43: m34, m44: m44
        )
    }

}

// MARK: -

extension CATransform3D {

    internal struct DecomposedTransform: Equatable {

        var scaleX: CGFloat = 1

        var scaleY: CGFloat = 1

        var scaleZ: CGFloat = 1

        var skewXY: CGFloat = 0

        var skewXZ: CGFloat = 0

        var skewYZ: CGFloat = 0

        var rotation: Quaternion = .init()

        var translateX: CGFloat = 0

        var translateY: CGFloat = 0

        var translateZ: CGFloat = 0

        var perspectiveX: CGFloat = 0

        var perspectiveY: CGFloat = 0

        var perspectiveZ: CGFloat = 0

        var perspectiveW: CGFloat = 1

    }

}

// MARK: -

extension CATransform3D.DecomposedTransform {

    internal func recompose() -> CATransform3D {
        var transform = CATransform3DIdentity

        transform.m14 = perspectiveX
        transform.m24 = perspectiveY
        transform.m34 = perspectiveZ
        transform.m44 = perspectiveW

        transform = CATransform3DTranslate(transform, translateX, translateY, translateZ)

        let qxx = rotation.x * rotation.x
        let qxy = rotation.x * rotation.y
        let qxz = rotation.x * rotation.z
        let qxw = rotation.x * rotation.w
        let qyy = rotation.y * rotation.y
        let qyz = rotation.y * rotation.z
        let qyw = rotation.y * rotation.w
        let qzz = rotation.z * rotation.z
        let qzw = rotation.z * rotation.w

        let rotationMatrix = CATransform3D(
            m11: 1 - 2 * (qyy + qzz),
            m12: 2 * (qxy - qzw),
            m13: 2 * (qxz + qyw),
            m14: 0,
            m21: 2 * (qxy + qzw),
            m22: 1 - 2 * (qxx + qzz),
            m23: 2 * (qyz - qxw),
            m24: 0,
            m31: 2 * (qxz - qyw),
            m32: 2 * (qyz + qxw),
            m33: 1 - 2 * (qxx + qyy),
            m34: 0,
            m41: 0,
            m42: 0,
            m43: 0,
            m44: 1
        )

        transform = CATransform3DConcat(rotationMatrix, transform)

        if skewYZ != 0 {
            var skewMatrix = CATransform3DIdentity
            skewMatrix.m32 = skewYZ
            transform = CATransform3DConcat(skewMatrix, transform)
        }

        if skewXZ != 0 {
            var skewMatrix = CATransform3DIdentity
            skewMatrix.m31 = skewXZ
            transform = CATransform3DConcat(skewMatrix, transform)
        }

        if skewXY != 0 {
            var skewMatrix = CATransform3DIdentity
            skewMatrix.m21 = skewXY
            transform = CATransform3DConcat(skewMatrix, transform)
        }

        transform = CATransform3DScale(transform, scaleX, scaleY, scaleZ)

        return transform
    }

}
