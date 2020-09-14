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

import Stagehand
import StagehandTesting
import XCTest

final class CGAffineTransformInterpolationTests: SnapshotTestCase {

    func testRotationAcrossBoundaries() {
        assertMidpoint(
            between: .init(rotationAngle: CGFloat.pi * 0.25),
            and: .init(rotationAngle: CGFloat.pi * 0.75),
            is: .init(rotationAngle: CGFloat.pi * 0.5)
        )

        assertMidpoint(
            between: .init(rotationAngle: CGFloat.pi * 0.75),
            and: .init(rotationAngle: CGFloat.pi * -0.75),
            is: .init(rotationAngle: CGFloat.pi)
        )

        assertMidpoint(
            between: .init(rotationAngle: CGFloat.pi * -0.75),
            and: .init(rotationAngle: CGFloat.pi * -0.25),
            is: .init(rotationAngle: CGFloat.pi * -0.5)
        )

        assertMidpoint(
            between: .init(rotationAngle: CGFloat.pi * -0.25),
            and: .init(rotationAngle: CGFloat.pi * 0.25),
            is: .identity
        )

        assertMidpoint(
            between: .init(rotationAngle: CGFloat.pi * 0.25),
            and: .init(rotationAngle: CGFloat.pi * -0.25),
            is: .identity
        )

        assertMidpoint(
            between: .init(rotationAngle: CGFloat.pi * -0.25),
            and: .init(rotationAngle: CGFloat.pi * -0.75),
            is: .init(rotationAngle: CGFloat.pi * -0.5)
        )

        assertMidpoint(
            between: .init(rotationAngle: CGFloat.pi * -0.75),
            and: .init(rotationAngle: CGFloat.pi * -1.25),
            is: .init(rotationAngle: CGFloat.pi)
        )

        assertMidpoint(
            between: .init(rotationAngle: CGFloat.pi * -1.5),
            and: .init(rotationAngle: CGFloat.pi * -2),
            is: .init(rotationAngle: CGFloat.pi * 0.25)
        )
    }

    // MARK: - Helper Methods

    private func assertMidpoint(
        between initialTransform: CGAffineTransform,
        and finalTransform: CGAffineTransform,
        is expectedMidpointTransform: CGAffineTransform,
        accuracy: CGFloat = 1e-15,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let actualMidpointTransform = CGAffineTransform.value(between: initialTransform, and: finalTransform, at: 0.5)

        guard
            abs(expectedMidpointTransform.a - actualMidpointTransform.a) <= accuracy,
            abs(expectedMidpointTransform.b - actualMidpointTransform.b) <= accuracy,
            abs(expectedMidpointTransform.c - actualMidpointTransform.c) <= accuracy,
            abs(expectedMidpointTransform.d - actualMidpointTransform.d) <= accuracy,
            abs(expectedMidpointTransform.tx - actualMidpointTransform.tx) <= accuracy,
            abs(expectedMidpointTransform.ty - actualMidpointTransform.ty) <= accuracy
        else {
            XCTFail("\(expectedMidpointTransform) is not equal to \(actualMidpointTransform)", file: file, line: line)
            return
        }
    }

}
