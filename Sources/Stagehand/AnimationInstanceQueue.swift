//
//  Copyright 2021 Square Inc.
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

internal final class AnimationInstanceQueue {

    // MARK: - Private Properties

    private var queue: [(instance: AnimationInstance, driver: DisplayLinkDriver)] = []

    // MARK: - Internal Methods

    internal func enqueue(instance: AnimationInstance, driver: DisplayLinkDriver) {
        queue.append((instance: instance, driver: driver))

        advanceToNextAnimationIfReady()
    }

    internal func cancelPendingAnimations() {
        queue.forEach { (instance, _) in
            if case .pending = instance.status {
                instance.cancel()
            }
        }

        purgeCompletedAndCanceledAnimations()
    }

    // MARK: - Private Methods

    private func advanceToNextAnimationIfReady() {
        guard let (currentInstance, _) = queue.first else {
            return
        }

        switch currentInstance.status {
        case .pending:
            // The current animation hasn't started yet. It will be started below.
            break

        case .animating:
            // The current animation isn't complete yet.
            return

        case .complete, .canceled:
            // The current animation is complete. It will be purged below, then the next animation (if one is enqueued)
            // wil be started.
            break
        }

        purgeCompletedAndCanceledAnimations()

        guard let (_, nextDriver) = queue.first else {
            // We've emptied the queue, nothing to do now.
            return
        }

        nextDriver.addCompletion { [weak self] _ in
            self?.advanceToNextAnimationIfReady()
        }

        nextDriver.start()
    }

    private func purgeCompletedAndCanceledAnimations() {
        queue.removeAll { (instance, _) -> Bool in
            switch instance.status {
            case .complete, .canceled:
                return true
            case .pending, .animating:
                return false
            }
        }
    }

}
