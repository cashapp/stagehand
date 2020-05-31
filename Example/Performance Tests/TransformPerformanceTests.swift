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
import XCTest

final class TransformPerformanceTests: XCTestCase {

    func testCGAffineTransformInterpolationPerformance_identityToIdentity() {
        measure {
            for _ in 0...100 {
                for i in 0...10000 {
                    let progress = Double(i) / 10000
                    _ = CGAffineTransform.value(between: .identity, and: .identity, at: progress)
                }
            }
        }
    }

    func testCGAffineTransformInterpolationPerformance_complexTransforms() {
        measure {
            let fromTransform = CGAffineTransform.identity
                .rotated(by: 1)
                .scaledBy(x: 2, y: 3)
                .translatedBy(x: 4, y: 5)

            let toTransform = CGAffineTransform.identity
                .rotated(by: 6)
                .scaledBy(x: 7, y: 8)
                .translatedBy(x: 9, y: 10)

            for _ in 0...100 {
                for i in 0...10000 {
                    let progress = Double(i) / 10000
                    _ = CGAffineTransform.value(between: fromTransform, and: toTransform, at: progress)
                }
            }
        }
    }

}
