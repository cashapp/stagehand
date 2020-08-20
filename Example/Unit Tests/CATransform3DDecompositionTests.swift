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

import XCTest

@testable import Stagehand

final class CATransform3DDecompositionTests: XCTestCase {

    // MARK: - Tests - Decomposition

    func testDecompositionIdentity() {
        XCTAssertEqual(
            CATransform3DIdentity.decomposed(),
            CATransform3D.DecomposedTransform()
        )
    }

    func testDecompositionTranslation() {
        func assertDecomposesTranslation(
            x: CGFloat,
            y: CGFloat,
            z: CGFloat,
            file: StaticString = #file,
            line: UInt = #line
        ) {
            XCTAssertEqual(
                CATransform3DMakeTranslation(x, y, z).decomposed(),
                CATransform3D.DecomposedTransform(translateX: x, translateY: y, translateZ: z),
                file: file,
                line: line
            )
        }

        assertDecomposesTranslation(x: 10, y: 0, z: 0)
        assertDecomposesTranslation(x: 0, y: 20, z: 0)
        assertDecomposesTranslation(x: 0, y: 0, z: 30)

        assertDecomposesTranslation(x: 10, y: 20, z: 30)
        assertDecomposesTranslation(x: -10, y: 20, z: 30)
        assertDecomposesTranslation(x: 10, y: -20, z: 30)
        assertDecomposesTranslation(x: 10, y: 20, z: -30)
        assertDecomposesTranslation(x: -10, y: -20, z: 30)
        assertDecomposesTranslation(x: -10, y: 20, z: -30)
        assertDecomposesTranslation(x: 10, y: -20, z: -30)
        assertDecomposesTranslation(x: -10, y: -20, z: -30)
    }

    func testDecompositionScale() {
        func assertDecomposesScale(
            x: CGFloat,
            y: CGFloat,
            z: CGFloat,
            file: StaticString = #file,
            line: UInt = #line
        ) {
            XCTAssertEqual(
                CATransform3DMakeScale(x, y, z).decomposed(),
                CATransform3D.DecomposedTransform(scaleX: x, scaleY: y, scaleZ: z),
                file: file,
                line: line
            )
        }

        assertDecomposesScale(x: 2, y: 1, z: 1)
        assertDecomposesScale(x: 1, y: 2, z: 1)
        assertDecomposesScale(x: 1, y: 1, z: 2)
        assertDecomposesScale(x: 2, y: 3, z: 4)

        // When all axes are scaled by a negative amount, this decomposes properly. When only one or two axes are scaled
        // by a negative amount, it considers it a positive scale with a rotation. Only test the one that decomposes
        // cleanly here. We'll test the other cases in the round trip tests below.
        assertDecomposesScale(x: -2, y: -3, z: -4)

        // Note that we can't test any scales where one of the axes is scaled by zero, since we would fail to decompse
        // the transform.
    }

    // MARK: - Tests - Recomposition

    func testRecompositionIdentity() {
        XCTAssertEqual(
            CATransform3D.DecomposedTransform().recompose(),
            CATransform3DIdentity
        )
    }

    func testRecompositionTranslation() {
        func assertRecomposesTranslation(
            x: CGFloat,
            y: CGFloat,
            z: CGFloat,
            file: StaticString = #file,
            line: UInt = #line
        ) {
            XCTAssertEqual(
                CATransform3D.DecomposedTransform(translateX: x, translateY: y, translateZ: z).recompose(),
                CATransform3DMakeTranslation(x, y, z),
                file: file,
                line: line
            )
        }

        assertRecomposesTranslation(x: 10, y: 0, z: 0)
        assertRecomposesTranslation(x: 0, y: 20, z: 0)
        assertRecomposesTranslation(x: 0, y: 0, z: 30)
        assertRecomposesTranslation(x: 10, y: 20, z: 30)

        assertRecomposesTranslation(x: -10, y: 20, z: 30)
        assertRecomposesTranslation(x: 10, y: -20, z: 30)
        assertRecomposesTranslation(x: 10, y: 20, z: -30)
        assertRecomposesTranslation(x: -10, y: -20, z: 30)
        assertRecomposesTranslation(x: -10, y: 20, z: -30)
        assertRecomposesTranslation(x: 10, y: -20, z: -30)
        assertRecomposesTranslation(x: -10, y: -20, z: -30)
    }

    func testRecompositionScale() {
        func assertRecomposesScale(
            x: CGFloat,
            y: CGFloat,
            z: CGFloat,
            file: StaticString = #file,
            line: UInt = #line
        ) {
            XCTAssertEqual(
                CATransform3D.DecomposedTransform(scaleX: x, scaleY: y, scaleZ: z).recompose(),
                CATransform3DMakeScale(x, y, z),
                file: file,
                line: line
            )
        }

        assertRecomposesScale(x: 2, y: 1, z: 1)
        assertRecomposesScale(x: 1, y: 2, z: 1)
        assertRecomposesScale(x: 1, y: 1, z: 2)
        assertRecomposesScale(x: 2, y: 3, z: 4)

        assertRecomposesScale(x: -2, y: 3, z: 4)
        assertRecomposesScale(x: 2, y: -3, z: 4)
        assertRecomposesScale(x: 2, y: 3, z: -4)
        assertRecomposesScale(x: -2, y: -3, z: 4)
        assertRecomposesScale(x: -2, y: 3, z: -4)
        assertRecomposesScale(x: 2, y: -3, z: -4)
        assertRecomposesScale(x: -2, y: -3, z: -4)

        assertRecomposesScale(x: 0, y: 3, z: 4)
        assertRecomposesScale(x: 2, y: 0, z: 4)
        assertRecomposesScale(x: 2, y: 3, z: 0)
        assertRecomposesScale(x: 2, y: 0, z: 0)
        assertRecomposesScale(x: 0, y: 3, z: 0)
        assertRecomposesScale(x: 0, y: 0, z: 4)
        assertRecomposesScale(x: 0, y: 0, z: 0)
    }

    // MARK: - Tests - Round Trip

    func testRoundTripIdentity() {
        assertDecomposesAndRecomposes(CATransform3DIdentity)
    }

    func testRoundTripScale() {
        // Single axis scales.
        assertDecomposesAndRecomposes(CATransform3DMakeScale(2, 1, 1))
        assertDecomposesAndRecomposes(CATransform3DMakeScale(1, 2, 1))
        assertDecomposesAndRecomposes(CATransform3DMakeScale(1, 1, 2))

        // All axis scaled by mixed positive and negative amounts.
        assertDecomposesAndRecomposes(CATransform3DMakeScale(2, 3, 4))
        assertDecomposesAndRecomposes(CATransform3DMakeScale(-2, 3, 4))
        assertDecomposesAndRecomposes(CATransform3DMakeScale(2, -3, 4))
        assertDecomposesAndRecomposes(CATransform3DMakeScale(2, 3, -4))
        assertDecomposesAndRecomposes(CATransform3DMakeScale(-2, -3, 4))
        assertDecomposesAndRecomposes(CATransform3DMakeScale(-2, 3, -4))
        assertDecomposesAndRecomposes(CATransform3DMakeScale(2, -3, -4))
        assertDecomposesAndRecomposes(CATransform3DMakeScale(-2, -3, -4))

        // Note that we can't test any scales where one of the axes is scaled by zero, since we would fail to decompse
        // the transform.
    }

    func testRoundTripRotation() {
        assertDecomposesAndRecomposes(CATransform3DMakeRotation(.pi / 2, 1, 0, 0), accuracy: 1e-15)
        assertDecomposesAndRecomposes(CATransform3DMakeRotation(.pi / 2, 0, 1, 0), accuracy: 1e-15)
        assertDecomposesAndRecomposes(CATransform3DMakeRotation(.pi / 2, 0, 0, 1), accuracy: 1e-15)
        assertDecomposesAndRecomposes(CATransform3DMakeRotation(.pi / 2, 1, 1, 0), accuracy: 1e-15)
        assertDecomposesAndRecomposes(CATransform3DMakeRotation(.pi / 2, 1, 0, 1), accuracy: 1e-15)
        assertDecomposesAndRecomposes(CATransform3DMakeRotation(.pi / 2, 0, 1, 1), accuracy: 1e-15)
        assertDecomposesAndRecomposes(CATransform3DMakeRotation(.pi / 2, 1, 1, 1), accuracy: 1e-15)

        assertDecomposesAndRecomposes(CATransform3DMakeRotation(-.pi / 4, 1, 0, 0), accuracy: 1e-15)
        assertDecomposesAndRecomposes(CATransform3DMakeRotation(.pi * 1.5, 1, 0, 0), accuracy: 1e-15)

        assertDecomposesAndRecomposes(
            CATransform3DIdentity
                .rotatedBy(angle: .pi / 4, x: 1, y: 0, z: 0)
                .rotatedBy(angle: .pi / 3, x: 0, y: 1, z: 0),
            accuracy: 1e-15
        )
    }

    func testRoundTripPerspective() {
        var perspectiveTransform = CATransform3DIdentity
        perspectiveTransform.m34 = -0.05
        assertDecomposesAndRecomposes(perspectiveTransform)

        perspectiveTransform.m34 = 0.1
        assertDecomposesAndRecomposes(perspectiveTransform)

        assertDecomposesAndRecomposes(CATransform3DScale(perspectiveTransform, 2, 3, 4))
        assertDecomposesAndRecomposes(CATransform3DRotate(perspectiveTransform, .pi / 4, 1, 1, 0), accuracy: 1e-15)
    }

    func testRoundTripSkew() {
        var skewYZTransform = CATransform3DIdentity
        skewYZTransform.m32 = 5
        assertDecomposesAndRecomposes(skewYZTransform)

        var skewXZTransform = CATransform3DIdentity
        skewXZTransform.m31 = 5
        assertDecomposesAndRecomposes(skewXZTransform)

        var skewXYTransform = CATransform3DIdentity
        skewXYTransform.m21 = 5
        assertDecomposesAndRecomposes(skewXYTransform)

        assertDecomposesAndRecomposes(CATransform3DIdentity.shearedBy(xy: 2, yx: 2), accuracy: 1e-10)
    }

    // MARK: - Private Methods

    private func assertDecomposesAndRecomposes(
        _ transform: CATransform3D,
        accuracy: CGFloat = 0,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard let recomposedTransform = transform.decomposed()?.recompose() else {
            XCTFail("Failed to decompose transform", file: file, line: line)
            return
        }

        let fields: [(KeyPath<CATransform3D, CGFloat>, String)] = [
            (\.m11, "m11"), (\.m12, "m12"), (\.m13, "m13"), (\.m14, "m14"),
            (\.m21, "m21"), (\.m22, "m22"), (\.m23, "m23"), (\.m24, "m24"),
            (\.m31, "m31"), (\.m32, "m32"), (\.m33, "m33"), (\.m34, "m34"),
            (\.m41, "m41"), (\.m42, "m42"), (\.m43, "m43"), (\.m44, "m44"),
        ]

        let differingFields = fields
            .map { ($0.1, abs(recomposedTransform[keyPath: $0.0] - transform[keyPath: $0.0])) }
            .filter { $1 > accuracy }
            .map { $0.0 }

        guard differingFields.isEmpty else {
            XCTFail(
                """
                \(recomposedTransform) is not equal to \(transform)
                Differing fields: \(differingFields.joined(separator: ", "))
                """,
                file: file,
                line: line
            )
            return
        }
    }

}

// MARK: -

extension CATransform3D: Equatable {

    public static func == (lhs: CATransform3D, rhs: CATransform3D) -> Bool {
        return lhs.m11 == rhs.m11
            && lhs.m12 == rhs.m12
            && lhs.m13 == rhs.m13
            && lhs.m14 == rhs.m14
            && lhs.m21 == rhs.m21
            && lhs.m22 == rhs.m22
            && lhs.m23 == rhs.m23
            && lhs.m24 == rhs.m24
            && lhs.m31 == rhs.m31
            && lhs.m32 == rhs.m32
            && lhs.m33 == rhs.m33
            && lhs.m34 == rhs.m34
            && lhs.m41 == rhs.m41
            && lhs.m42 == rhs.m42
            && lhs.m43 == rhs.m43
            && lhs.m44 == rhs.m44
    }

}
