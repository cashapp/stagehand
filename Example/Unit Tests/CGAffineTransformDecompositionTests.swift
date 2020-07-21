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

final class CGAffineTransformDecompositionTests: XCTestCase {

    // MARK: - Tests - Decomposition

    func testDecompositionIdentity() {
        XCTAssertEqual(CGAffineTransform.identity.decomposed(), CGAffineTransform.DecomposedMatrix())
    }

    func testDecompositionTranslation() {
        func assertDecomposesTranslation(x: CGFloat, y: CGFloat, file: StaticString = #file, line: UInt = #line) {
            XCTAssertEqual(
                CGAffineTransform.identity
                    .translatedBy(x: x, y: y)
                    .decomposed(),
                CGAffineTransform.DecomposedMatrix(
                    translateX: x,
                    translateY: y
                ),
                file: file,
                line: line
            )
        }

        assertDecomposesTranslation(x: 10, y: 20)
        assertDecomposesTranslation(x: -4, y: -5)
        assertDecomposesTranslation(x: 10, y: 0)
        assertDecomposesTranslation(x: 0, y: 10)
    }

    func testDecompositionScale() {
        func assertDecomposesScale(x: CGFloat, y: CGFloat, file: StaticString = #file, line: UInt = #line) {
            XCTAssertEqual(
                CGAffineTransform.identity
                    .scaledBy(x: x, y: y)
                    .decomposed(),
                CGAffineTransform.DecomposedMatrix(
                    scaleX: x,
                    scaleY: y,
                    m11: (x == 0) ? 0 : 1,
                    m22: (y == 0) ? 0 : 1
                ),
                file: file,
                line: line
            )
        }

        assertDecomposesScale(x: 1, y: 2)
        assertDecomposesScale(x: 3, y: 2)
        assertDecomposesScale(x: 3, y: 1)
        assertDecomposesScale(x: -3, y: 2)
        assertDecomposesScale(x: 3, y: -2)
        assertDecomposesScale(x: 0, y: 2)
        assertDecomposesScale(x: 0, y: -2)
        assertDecomposesScale(x: 3, y: 0)
        assertDecomposesScale(x: -3, y: 0)
        assertDecomposesScale(x: 0, y: 0)

        // Note that we specifically don't test the case where both x and y scale factors are negative. This is because
        // a negative scale on both axes is indistinguishable from a positive scale of equal magnitude combined with a
        // rotation of 180º.
    }

    func testDecompositionRotation() {
        func assertDecomposesRotation(
            _ angle: CGFloat,
            decomposedAngle: CGFloat? = nil,
            file: StaticString = #file,
            line: UInt = #line
        ) {
            assertEqual(
                CGAffineTransform.identity
                    .rotated(by: angle)
                    .decomposed(),
                CGAffineTransform.DecomposedMatrix(
                    rotation: decomposedAngle ?? angle
                ),
                accuracy: 1e-10,
                file: file,
                line: line
            )
        }

        assertDecomposesRotation(0)
        assertDecomposesRotation(.pi / 4)
        assertDecomposesRotation(.pi / 2)
        assertDecomposesRotation(.pi)
        assertDecomposesRotation(-.pi / 4)
        assertDecomposesRotation(-.pi / 2)
        assertDecomposesRotation(-.pi)

        // Rotating past 180º is the same as rotating a smaller angle in the opposite direction. The decomposed angle
        // should be the smallest angle resulting in the same transition.
        assertDecomposesRotation(.pi * 1.5, decomposedAngle: -.pi / 2)
        assertDecomposesRotation(-.pi * 1.5, decomposedAngle: .pi / 2)

        // Rotating past a full rotation is equivalent to removing some number of full rotations and rotating the
        // remainder of the way. The decomposed angle should be the smallest angle resulting in the same transform.
        assertDecomposesRotation(2 * .pi, decomposedAngle: 0)
        assertDecomposesRotation(3 * .pi, decomposedAngle: .pi)
        assertDecomposesRotation(4 * .pi, decomposedAngle: 0)
        assertDecomposesRotation(-2 * .pi, decomposedAngle: 0)
        assertDecomposesRotation(-3 * .pi, decomposedAngle: -.pi)
    }

    func testDecompositionClampsRotationValues() {
        func assertRotation(
            of initialAngle: CGFloat,
            resultsIn resultingAngle: CGFloat,
            file: StaticString = #file,
            line: UInt = #line
        ) {
            XCTAssertEqual(
                CGAffineTransform.identity
                    .rotated(by: initialAngle)
                    .decomposed()
                    .rotation,
                resultingAngle,
                accuracy: 1e-10,
                file: file,
                line: line
            )
        }

        // Values in [0, π] should be preserved.
        assertRotation(of: 0, resultsIn: 0)
        assertRotation(of: .pi / 4, resultsIn: .pi / 4)
        assertRotation(of: .pi, resultsIn: .pi)

        // Values in (π, 2π] should be mapped to (-π, 0], or in other words (x - 2π).
        assertRotation(of: 1.5 * .pi, resultsIn: -.pi / 2)
        assertRotation(of: 2 * .pi, resultsIn: 0)

        // Values in [-π, 0] should be preserved.
        assertRotation(of: -.pi / 4, resultsIn: -.pi / 4)
        assertRotation(of: -.pi, resultsIn: -.pi)

        // Values in [-2π, -π) should be mapped to [0, π), or in other words (x + 2π).
        assertRotation(of: -1.5 * .pi, resultsIn: .pi / 2)
        assertRotation(of: -2 * .pi, resultsIn: 0)
    }

    func testDecompositionRotationAndScale() {
        assertEqual(
            CGAffineTransform.identity
                .rotated(by: .pi / 4)
                .scaledBy(x: 3, y: 2)
                .decomposed(),
            CGAffineTransform.DecomposedMatrix(
                scaleX: 3,
                scaleY: 2,
                rotation: .pi / 4
            ),
            accuracy: 1e-10
        )
    }

    // MARK: - Tests - Recomposition

    func testRecompositionIdentity() {
        XCTAssertEqual(CGAffineTransform.DecomposedMatrix().recompose(), CGAffineTransform.identity)
    }

    func testRecompositionTranslation() {
        func assertRecomposesTranslation(x: CGFloat, y: CGFloat, file: StaticString = #file, line: UInt = #line) {
            XCTAssertEqual(
                CGAffineTransform.DecomposedMatrix(
                    translateX: x,
                    translateY: y
                ).recompose(),
                CGAffineTransform.identity
                    .translatedBy(x: x, y: y),
                file: file,
                line: line
            )
        }

        assertRecomposesTranslation(x: 10, y: 20)
        assertRecomposesTranslation(x: -4, y: -5)
        assertRecomposesTranslation(x: 10, y: 0)
        assertRecomposesTranslation(x: 0, y: 10)
    }

    func testRecompositionScale() {
        func assertRecomposesScale(x: CGFloat, y: CGFloat, file: StaticString = #file, line: UInt = #line) {
            XCTAssertEqual(
                CGAffineTransform.DecomposedMatrix(
                    scaleX: x,
                    scaleY: y
                ).recompose(),
                CGAffineTransform.identity
                    .scaledBy(x: x, y: y),
                file: file,
                line: line
            )
        }

        assertRecomposesScale(x: 1, y: 2)
        assertRecomposesScale(x: 3, y: 2)
        assertRecomposesScale(x: 3, y: 1)
        assertRecomposesScale(x: -3, y: 2)
        assertRecomposesScale(x: 3, y: -2)
        assertRecomposesScale(x: 0, y: 2)
        assertRecomposesScale(x: 0, y: -2)
        assertRecomposesScale(x: 3, y: 0)
        assertRecomposesScale(x: -3, y: 0)
        assertRecomposesScale(x: 0, y: 0)
    }

    func testRecompositionRotation() {
        func assertRecomposesRotation(
            _ angle: CGFloat,
            file: StaticString = #file,
            line: UInt = #line
        ) {
            XCTAssertEqual(
                CGAffineTransform.DecomposedMatrix(
                    rotation: angle
                ).recompose(),
                CGAffineTransform.identity
                    .rotated(by: angle),
                file: file,
                line: line
            )
        }

        assertRecomposesRotation(0)
        assertRecomposesRotation(.pi / 4)
        assertRecomposesRotation(.pi / 2)
        assertRecomposesRotation(.pi)
        assertRecomposesRotation(-.pi / 4)
        assertRecomposesRotation(-.pi / 2)
        assertRecomposesRotation(-.pi)

        assertRecomposesRotation(.pi * 1.5)
        assertRecomposesRotation(-.pi * 1.5)
    }

    func testRecompositionRotationAndScale() {
        XCTAssertEqual(
            CGAffineTransform.DecomposedMatrix(
                scaleX: 3,
                scaleY: 2,
                rotation: .pi / 4
            ).recompose(),
            CGAffineTransform.identity
                .rotated(by: .pi / 4)
                .scaledBy(x: 3, y: 2)
        )
    }

    // MARK: - Tests - Round Trip

    func testRoundTripIdentity() {
        assertDecomposesAndRecomposes(.identity)
    }

    func testRoundTripScaleAndRotation() {
        assertDecomposesAndRecomposes(
            CGAffineTransform.identity
                .scaledBy(x: 3, y: 2)
                .rotated(by: .pi / 2),
            accuracy: 1e-16
        )
    }

    func testRoundTripScaleAndRotationAndTranslation() {
        assertDecomposesAndRecomposes(
            CGAffineTransform.identity
                .scaledBy(x: 3, y: 2)
                .rotated(by: .pi / 2)
                .translatedBy(x: 10, y: -5),
            accuracy: 1e-16
        )
    }

    func testRoundTripSkew() {
        var skewTransform = CGAffineTransform.identity
        skewTransform.c = 5
        assertDecomposesAndRecomposes(skewTransform)
    }

    // MARK: - Private Methods - Assertions

    private func assertEqual(
        _ lhs: CGAffineTransform.DecomposedMatrix,
        _ rhs: CGAffineTransform.DecomposedMatrix,
        accuracy: CGFloat,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard
            abs(lhs.scaleX - rhs.scaleX) <= accuracy,
            abs(lhs.scaleY - rhs.scaleY) <= accuracy,
            abs(lhs.translateX - rhs.translateX) <= accuracy,
            abs(lhs.translateY - rhs.translateY) <= accuracy,
            abs(lhs.rotation - rhs.rotation) <= accuracy,
            abs(lhs.m11 - rhs.m11) <= accuracy,
            abs(lhs.m12 - rhs.m12) <= accuracy,
            abs(lhs.m21 - rhs.m21) <= accuracy,
            abs(lhs.m22 - rhs.m22) <= accuracy
        else {
            XCTFail("\(lhs) is not equal to \(rhs)", file: file, line: line)
            return
        }
    }

    private func assertDecomposesAndRecomposes(
        _ transform: CGAffineTransform,
        accuracy: CGFloat = 0,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let recomposedTransform = transform.decomposed().recompose()

        guard
            abs(recomposedTransform.a - transform.a) <= accuracy,
            abs(recomposedTransform.b - transform.b) <= accuracy,
            abs(recomposedTransform.c - transform.c) <= accuracy,
            abs(recomposedTransform.d - transform.d) <= accuracy,
            abs(recomposedTransform.tx - transform.tx) <= accuracy,
            abs(recomposedTransform.ty - transform.ty) <= accuracy
        else {
            XCTFail("\(recomposedTransform) is not equal to \(transform)", file: file, line: line)
            return
        }
    }

}
