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

@testable import Stagehand

final class TestDriver: Driver {

    // MARK: - Private Properties

    private var renderedRelativeTimestamp: Double?

    // MARK: - Driver

    weak var animationInstance: DrivenAnimationInstance!

    func animationInstanceDidInitialize() {
        // No-op.
    }

    func animationInstanceDidCancel(behavior: AnimationInstance.CancelationBehavior) {
        // No-op.
    }

    // MARK: - Public Methods

    func runForward(to relativeTimestamp: Double) {
        if let lastRenderedTimestamp = renderedRelativeTimestamp {
            animationInstance.executeBlocks(from: lastRenderedTimestamp, .exclusive, to: relativeTimestamp)
        } else {
            animationInstance.executeBlocks(from: 0, .inclusive, to: relativeTimestamp)
        }

        animationInstance.renderFrame(at: relativeTimestamp)

        renderedRelativeTimestamp = relativeTimestamp
    }

}
