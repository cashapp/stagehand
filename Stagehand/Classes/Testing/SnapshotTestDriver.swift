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

@testable import Stagehand

final class SnapshotTestDriver: Driver {

    // MARK: - Life Cycle

    init(
        relativeTimestamp: Double
    ) {
        self.relativeTimestamp = relativeTimestamp
    }

    // MARK: - Private Properties

    private let relativeTimestamp: Double

    // MARK: - Driver

    weak var animationInstance: DrivenAnimationInstance!

    func animationInstanceDidInitialize() {
        animationInstance.executeBlocks(from: 0, .inclusive, to: relativeTimestamp)
        animationInstance.renderFrame(at: relativeTimestamp)
    }

    func animationInstanceDidCancel(behavior: AnimationInstance.CancelationBehavior) {
        if relativeTimestamp < 1 {
            animationInstance.executeBlocks(from: relativeTimestamp, .exclusive, to: 1)
        }
        animationInstance.executeBlocks(from: 1, .inclusive, to: 0)

        animationInstance.renderFrame(at: 0)
    }

}
