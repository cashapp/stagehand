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

import XCTest

@testable import Stagehand

final class DisplayLinkDriverTests: XCTestCase {

    // MARK: - Tests - Rendering

    func testZeroDurationZeroDelay() {
        let driver = DisplayLinkDriver(
            delay: 0,
            duration: 0,
            repeatStyle: .none,
            completion: nil
        )

        let instance = TestAnimationInstance()
        driver.animationInstance = instance
        driver.animationInstanceDidInitialize()

        driver.start()

        // When there is a zero duration animation with no delay, the final frame should be rendered immediately.

        XCTAssertEqual(instance.executedBlockSequences.count, 1)

        if instance.executedBlockSequences.count >= 1 {
            XCTAssert(instance.executedBlockSequences[0] == (0, .inclusive, 1))
        }

        XCTAssertEqual(instance.renderedFrames, [1])
        XCTAssertEqual(instance.completeCount, 1)

        driver.animationInstanceDidCancel(behavior: .halt)
    }

    func testZeroDurationNonZeroDelay() {
        let displayLink = TestDisplayLink()

        let driver = DisplayLinkDriver(
            delay: 1,
            duration: 0,
            repeatStyle: .none,
            completion: nil,
            displayLinkFactory: { _, _ in displayLink }
        )

        displayLink.driver = driver

        let instance = TestAnimationInstance()
        driver.animationInstance = instance
        driver.animationInstanceDidInitialize()

        driver.start(timeFactory: Factory.timeFactory)

        // When there is an animation with a non-zero delay, no frames should be rendered immediately.

        XCTAssertEqual(instance.executedBlockSequences.count, 0)
        XCTAssertEqual(instance.renderedFrames, [])
        XCTAssertEqual(instance.completeCount, 0)

        // Until the delay is met, nothing should be rendering.
        displayLink.simulateRunLoop(at: 0.99)

        XCTAssertEqual(instance.executedBlockSequences.count, 0)
        XCTAssertEqual(instance.renderedFrames, [])
        XCTAssertEqual(instance.completeCount, 0)

        // As soon as the delay has been met, the final frame of the animation should be rendered.
        displayLink.simulateRunLoop(at: 1)

        XCTAssertEqual(instance.executedBlockSequences.count, 1)

        if instance.executedBlockSequences.count >= 1 {
            XCTAssert(instance.executedBlockSequences[0] == (0, .inclusive, 1))
        }

        XCTAssertEqual(instance.renderedFrames, [1])
        XCTAssertEqual(instance.completeCount, 1)

        driver.animationInstanceDidCancel(behavior: .halt)
    }

    func testNonZeroDurationZeroDelay() {
        let displayLink = TestDisplayLink()

        let driver = DisplayLinkDriver(
            delay: 0,
            duration: 1,
            repeatStyle: .none,
            completion: nil,
            displayLinkFactory: { _, _ in displayLink }
        )

        displayLink.driver = driver

        let instance = TestAnimationInstance()
        driver.animationInstance = instance
        driver.animationInstanceDidInitialize()

        driver.start(timeFactory: Factory.timeFactory)

        // When there is a non-zero duration animation with no delay, the initial frame should be rendered immediately.

        XCTAssertEqual(instance.executedBlockSequences.count, 1)

        if instance.executedBlockSequences.count >= 1 {
            XCTAssert(instance.executedBlockSequences[0] == (0, .inclusive, 0))
        }

        XCTAssertEqual(instance.renderedFrames, [0])
        XCTAssertEqual(instance.completeCount, 0)

        instance.clearGatheredData()

        // On the next run loop, the animation should be executed to that point.
        displayLink.simulateRunLoop(at: 0.5)

        XCTAssertEqual(instance.executedBlockSequences.count, 1)

        if instance.executedBlockSequences.count >= 1 {
            XCTAssert(instance.executedBlockSequences[0] == (0, .exclusive, 0.5))
        }

        XCTAssertEqual(instance.renderedFrames, [0.5])
        XCTAssertEqual(instance.completeCount, 0)

        instance.clearGatheredData()

        // On the final run loop, the animation should be executed to the end.
        displayLink.simulateRunLoop(at: 1)

        XCTAssertEqual(instance.executedBlockSequences.count, 1)

        if instance.executedBlockSequences.count >= 1 {
            XCTAssert(instance.executedBlockSequences[0] == (0.5, .exclusive, 1))
        }

        XCTAssertEqual(instance.renderedFrames, [1])
        XCTAssertEqual(instance.completeCount, 1)

        driver.animationInstanceDidCancel(behavior: .halt)
    }

    func testCompletesPastEndPoint() {
        let displayLink = TestDisplayLink()

        let driver = DisplayLinkDriver(
            delay: 0,
            duration: 1,
            repeatStyle: .none,
            completion: nil,
            displayLinkFactory: { _, _ in displayLink }
        )

        displayLink.driver = driver

        let instance = TestAnimationInstance()
        driver.animationInstance = instance
        driver.animationInstanceDidInitialize()

        driver.start(timeFactory: Factory.timeFactory)

        displayLink.simulateRunLoop(at: 0.5)
        instance.clearGatheredData()

        // There usually isn't a run loop at _exactly_ the end point of the animation. As soon as the first run loop
        // occurs after the animation should have ended, complete the animation.
        displayLink.simulateRunLoop(at: 1.1)

        XCTAssertEqual(instance.executedBlockSequences.count, 1)

        if instance.executedBlockSequences.count >= 1 {
            XCTAssert(instance.executedBlockSequences[0] == (0.5, .exclusive, 1))
        }

        XCTAssertEqual(instance.renderedFrames, [1])
        XCTAssertEqual(instance.completeCount, 1)

        driver.animationInstanceDidCancel(behavior: .halt)
    }

    func testRelativeTimestampCalculation() {
        let displayLink = TestDisplayLink()

        let driver = DisplayLinkDriver(
            delay: 1,
            duration: 4,
            repeatStyle: .none,
            completion: nil,
            displayLinkFactory: { _, _ in displayLink }
        )

        displayLink.driver = driver

        let instance = TestAnimationInstance()
        driver.animationInstance = instance
        driver.animationInstanceDidInitialize()

        driver.start(timeFactory: Factory.timeFactory)

        // At 2 seconds, the animation should have passed the delay (1 second) and be 1 second into the animation (which
        // is 25% of the duration).
        displayLink.simulateRunLoop(at: 2)

        XCTAssertEqual(instance.executedBlockSequences.count, 1)

        if instance.executedBlockSequences.count >= 1 {
            XCTAssert(instance.executedBlockSequences[0] == (0, .inclusive, 0.25))
        }

        XCTAssertEqual(instance.renderedFrames, [0.25])
        XCTAssertEqual(instance.completeCount, 0)

        instance.clearGatheredData()

        // At 4 seconds, the animation should be 3 seconds into the duration (75%).
        displayLink.simulateRunLoop(at: 4)

        XCTAssertEqual(instance.executedBlockSequences.count, 1)

        if instance.executedBlockSequences.count >= 1 {
            XCTAssert(instance.executedBlockSequences[0] == (0.25, .exclusive, 0.75))
        }

        XCTAssertEqual(instance.renderedFrames, [0.75])
        XCTAssertEqual(instance.completeCount, 0)

        instance.clearGatheredData()

        // At 5 seconds, the animation should be complete.
        displayLink.simulateRunLoop(at: 5)

        XCTAssertEqual(instance.executedBlockSequences.count, 1)

        if instance.executedBlockSequences.count >= 1 {
            XCTAssert(instance.executedBlockSequences[0] == (0.75, .exclusive, 1))
        }

        XCTAssertEqual(instance.renderedFrames, [1])
        XCTAssertEqual(instance.completeCount, 1)

        driver.animationInstanceDidCancel(behavior: .halt)
    }

    func testLooping() {
        let displayLink = TestDisplayLink()

        let driver = DisplayLinkDriver(
            delay: 0,
            duration: 1,
            repeatStyle: .repeating(count: 2, autoreversing: false),
            completion: nil,
            displayLinkFactory: { _, _ in displayLink }
        )

        displayLink.driver = driver

        let instance = TestAnimationInstance()
        driver.animationInstance = instance
        driver.animationInstanceDidInitialize()

        driver.start(timeFactory: Factory.timeFactory)

        // The initial frame should be rendered immediately.

        XCTAssertEqual(instance.executedBlockSequences.count, 1)

        if instance.executedBlockSequences.count >= 1 {
            XCTAssert(instance.executedBlockSequences[0] == (0, .inclusive, 0))
        }

        XCTAssertEqual(instance.renderedFrames, [0])
        XCTAssertEqual(instance.completeCount, 0)

        instance.clearGatheredData()

        // The first cycle should behave the same as a non-looping animation, except it doesn't complete at the end.
        displayLink.simulateRunLoop(at: 0.5)
        displayLink.simulateRunLoop(at: 0.75)

        XCTAssertEqual(instance.executedBlockSequences.count, 2)

        if instance.executedBlockSequences.count >= 2 {
            XCTAssert(instance.executedBlockSequences[0] == (0, .exclusive, 0.5))
            XCTAssert(instance.executedBlockSequences[1] == (0.5, .exclusive, 0.75))
        }

        XCTAssertEqual(instance.renderedFrames, [0.5, 0.75])
        XCTAssertEqual(instance.completeCount, 0)

        instance.clearGatheredData()

        // When we loop around to the second cycle, the first cycle should be completed, then the entire animation
        // should be run in reverse (to allow execution blocks to be undone), then the second cycle should be run up to
        // its current point.
        displayLink.simulateRunLoop(at: 1.25)

        XCTAssertEqual(instance.executedBlockSequences.count, 3)

        if instance.executedBlockSequences.count >= 3 {
            XCTAssert(instance.executedBlockSequences[0] == (0.75, .exclusive, 1))
            XCTAssert(instance.executedBlockSequences[1] == (1, .inclusive, 0))
            XCTAssert(instance.executedBlockSequences[2] == (0, .inclusive, 0.25))
        }

        XCTAssertEqual(instance.renderedFrames, [0.25])
        XCTAssertEqual(instance.completeCount, 0)

        instance.clearGatheredData()

        // When we pass the end of the second cycle, the animation should complete.
        displayLink.simulateRunLoop(at: 2.1)

        XCTAssertEqual(instance.executedBlockSequences.count, 1)

        if instance.executedBlockSequences.count >= 1 {
            XCTAssert(instance.executedBlockSequences[0] == (0.25, .exclusive, 1))
        }

        XCTAssertEqual(instance.renderedFrames, [1])
        XCTAssertEqual(instance.completeCount, 1)

        driver.animationInstanceDidCancel(behavior: .halt)
    }

    func testLoopingWithDelay() {
        let displayLink = TestDisplayLink()

        let driver = DisplayLinkDriver(
            delay: 1,
            duration: 1,
            repeatStyle: .repeating(count: 2, autoreversing: false),
            completion: nil,
            displayLinkFactory: { _, _ in displayLink }
        )

        displayLink.driver = driver

        let instance = TestAnimationInstance()
        driver.animationInstance = instance
        driver.animationInstanceDidInitialize()

        driver.start(timeFactory: Factory.timeFactory)

        // When the first run loop past the delay occurs, we should render from the beggining (inclusive) to the current
        // relative timestamp.
        displayLink.simulateRunLoop(at: 1.5)

        XCTAssertEqual(instance.executedBlockSequences.count, 1)

        if instance.executedBlockSequences.count >= 1 {
            XCTAssert(instance.executedBlockSequences[0] == (0, .inclusive, 0.5))
        }

        XCTAssertEqual(instance.renderedFrames, [0.5])
        XCTAssertEqual(instance.completeCount, 0)

        // The rest of the animation should behave identically to a looping animation without a delay.

        driver.animationInstanceDidCancel(behavior: .halt)
    }

    func testLoopingWithAutoreversing() {
        let displayLink = TestDisplayLink()

        let driver = DisplayLinkDriver(
            delay: 0,
            duration: 1,
            repeatStyle: .repeating(count: 8, autoreversing: true),
            completion: nil,
            displayLinkFactory: { _, _ in displayLink }
        )

        displayLink.driver = driver

        let instance = TestAnimationInstance()
        driver.animationInstance = instance
        driver.animationInstanceDidInitialize()

        driver.start(timeFactory: Factory.timeFactory)

        // The initial frame should be rendered immediately.

        XCTAssertEqual(instance.executedBlockSequences.count, 1)

        if instance.executedBlockSequences.count >= 1 {
            XCTAssert(instance.executedBlockSequences[0] == (0, .inclusive, 0))
        }

        XCTAssertEqual(instance.renderedFrames, [0])
        XCTAssertEqual(instance.completeCount, 0)

        instance.clearGatheredData()

        // The first cycle should behave the same as a non-looping animation, except it doesn't complete at the end.
        displayLink.simulateRunLoop(at: 0.5)
        displayLink.simulateRunLoop(at: 0.75)

        XCTAssertEqual(instance.executedBlockSequences.count, 2)

        if instance.executedBlockSequences.count >= 2 {
            XCTAssert(instance.executedBlockSequences[0] == (0, .exclusive, 0.5))
            XCTAssert(instance.executedBlockSequences[1] == (0.5, .exclusive, 0.75))
        }

        XCTAssertEqual(instance.renderedFrames, [0.5, 0.75])
        XCTAssertEqual(instance.completeCount, 0)

        instance.clearGatheredData()

        // When we loop around to the second cycle, the first cycle should be completed, then the second cycle should be
        // run up to its current point (in reverse).
        displayLink.simulateRunLoop(at: 1.5)

        XCTAssertEqual(instance.executedBlockSequences.count, 2)

        if instance.executedBlockSequences.count >= 2 {
            XCTAssert(instance.executedBlockSequences[0] == (0.75, .exclusive, 1))
            XCTAssert(instance.executedBlockSequences[1] == (1, .inclusive, 0.5))
        }

        XCTAssertEqual(instance.renderedFrames, [0.5])
        XCTAssertEqual(instance.completeCount, 0)

        instance.clearGatheredData()

        // The second cycle should continue to execute in reverse.
        displayLink.simulateRunLoop(at: 1.75)

        XCTAssertEqual(instance.executedBlockSequences.count, 1)

        if instance.executedBlockSequences.count >= 1 {
            XCTAssert(instance.executedBlockSequences[0] == (0.5, .exclusive, 0.25))
        }

        XCTAssertEqual(instance.renderedFrames, [0.25])
        XCTAssertEqual(instance.completeCount, 0)

        instance.clearGatheredData()

        // The third cycle should be back to forward execution
        displayLink.simulateRunLoop(at: 2.5)

        XCTAssertEqual(instance.executedBlockSequences.count, 2)

        if instance.executedBlockSequences.count >= 2 {
            XCTAssert(instance.executedBlockSequences[0] == (0.25, .exclusive, 0))
            XCTAssert(instance.executedBlockSequences[1] == (0, .inclusive, 0.5))
        }

        XCTAssertEqual(instance.renderedFrames, [0.5])
        XCTAssertEqual(instance.completeCount, 0)

        instance.clearGatheredData()

        // If we somehow skip an entire cycle, execute the missing cycle.
        displayLink.simulateRunLoop(at: 4.25)

        XCTAssertEqual(instance.executedBlockSequences.count, 3)

        if instance.executedBlockSequences.count >= 3 {
            XCTAssert(instance.executedBlockSequences[0] == (0.5, .exclusive, 1))
            XCTAssert(instance.executedBlockSequences[1] == (1, .inclusive, 0))
            XCTAssert(instance.executedBlockSequences[2] == (0, .inclusive, 0.25))
        }

        XCTAssertEqual(instance.renderedFrames, [0.25])
        XCTAssertEqual(instance.completeCount, 0)

        instance.clearGatheredData()

        displayLink.simulateRunLoop(at: 5.5)
        instance.clearGatheredData()

        // Same thing going the other direction.
        displayLink.simulateRunLoop(at: 7.25)

        XCTAssertEqual(instance.executedBlockSequences.count, 3)

        if instance.executedBlockSequences.count >= 3 {
            XCTAssert(instance.executedBlockSequences[0] == (0.5, .exclusive, 0))
            XCTAssert(instance.executedBlockSequences[1] == (0, .inclusive, 1))
            XCTAssert(instance.executedBlockSequences[2] == (1, .inclusive, 0.75))
        }

        XCTAssertEqual(instance.renderedFrames, [0.75])
        XCTAssertEqual(instance.completeCount, 0)

        instance.clearGatheredData()

        // Once we have passed the end of the final cycle, the animation should complete.
        displayLink.simulateRunLoop(at: 8.1)

        XCTAssertEqual(instance.executedBlockSequences.count, 1)

        if instance.executedBlockSequences.count >= 3 {
            XCTAssert(instance.executedBlockSequences[0] == (0.75, .exclusive, 0))
        }

        XCTAssertEqual(instance.renderedFrames, [0])
        XCTAssertEqual(instance.completeCount, 1)

        driver.animationInstanceDidCancel(behavior: .halt)
    }

    func testLoopingWithAutoreversingAndDelayAndLateFirstRunLoop() {
        let displayLink = TestDisplayLink()

        let driver = DisplayLinkDriver(
            delay: 1,
            duration: 1,
            repeatStyle: .repeating(count: 2, autoreversing: true),
            completion: nil,
            displayLinkFactory: { _, _ in displayLink }
        )

        displayLink.driver = driver

        let instance = TestAnimationInstance()
        driver.animationInstance = instance
        driver.animationInstanceDidInitialize()

        driver.start(timeFactory: Factory.timeFactory)

        // In the edge case where our first render pass occurs in a reverse cycle, we should execute the first (forward)
        // cycle of the animation, then execute the second cycle up to the current relative timestamp.
        displayLink.simulateRunLoop(at: 2.5)

        XCTAssertEqual(instance.executedBlockSequences.count, 2)

        if instance.executedBlockSequences.count >= 2 {
            XCTAssert(instance.executedBlockSequences[0] == (0, .inclusive, 1))
            XCTAssert(instance.executedBlockSequences[1] == (1, .inclusive, 0.5))
        }

        XCTAssertEqual(instance.renderedFrames, [0.5])
        XCTAssertEqual(instance.completeCount, 0)

        driver.animationInstanceDidCancel(behavior: .halt)
    }

    func testCallsCompletion() {
        let expectation = self.expectation(description: "calls completion")
        let completion: (Bool) -> Void = { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }

        let displayLink = TestDisplayLink()

        let driver = DisplayLinkDriver(
            delay: 0,
            duration: 1,
            repeatStyle: .none,
            completion: completion,
            displayLinkFactory: { _, _ in displayLink }
        )

        displayLink.driver = driver

        let instance = TestAnimationInstance()
        driver.animationInstance = instance
        driver.animationInstanceDidInitialize()

        driver.start(timeFactory: Factory.timeFactory)

        displayLink.simulateRunLoop(at: 1)

        waitForExpectations(timeout: 1, handler: nil)
    }

    // MARK: - Tests - Cancellation

    func testCancelRevert() {
        let displayLink = TestDisplayLink()

        let driver = DisplayLinkDriver(
            delay: 0,
            duration: 1,
            repeatStyle: .none,
            completion: nil,
            displayLinkFactory: { _, _ in displayLink }
        )

        displayLink.driver = driver

        let instance = TestAnimationInstance()
        driver.animationInstance = instance
        driver.animationInstanceDidInitialize()

        driver.start(timeFactory: Factory.timeFactory)

        displayLink.simulateRunLoop(at: 0.5)
        instance.clearGatheredData()

        // Reverting the animation should finish executing the (forward) cycle, then reverse back to the beginning.
        driver.animationInstanceDidCancel(behavior: .revert)

        XCTAssertEqual(instance.executedBlockSequences.count, 2)

        if instance.executedBlockSequences.count >= 2 {
            XCTAssert(instance.executedBlockSequences[0] == (0.5, .exclusive, 1))
            XCTAssert(instance.executedBlockSequences[1] == (1, .inclusive, 0))
        }

        XCTAssertEqual(instance.renderedFrames, [0])
        XCTAssertEqual(instance.completeCount, 0)
    }

    func testCancelRevertLooping() {
        let displayLink = TestDisplayLink()

        let driver = DisplayLinkDriver(
            delay: 0,
            duration: 1,
            repeatStyle: .repeating(count: 3, autoreversing: false),
            completion: nil,
            displayLinkFactory: { _, _ in displayLink }
        )

        displayLink.driver = driver

        let instance = TestAnimationInstance()
        driver.animationInstance = instance
        driver.animationInstanceDidInitialize()

        driver.start(timeFactory: Factory.timeFactory)

        displayLink.simulateRunLoop(at: 0.5)
        instance.clearGatheredData()

        // Reverting the animation should finish executing the (forward) cycle, then reverse back to the beginning.
        driver.animationInstanceDidCancel(behavior: .revert)

        XCTAssertEqual(instance.executedBlockSequences.count, 2)

        if instance.executedBlockSequences.count >= 2 {
            XCTAssert(instance.executedBlockSequences[0] == (0.5, .exclusive, 1))
            XCTAssert(instance.executedBlockSequences[1] == (1, .inclusive, 0))
        }

        XCTAssertEqual(instance.renderedFrames, [0])
        XCTAssertEqual(instance.completeCount, 0)
    }

    func testCancelRevertLoopingDuringReverseCycle() {
        let displayLink = TestDisplayLink()

        let driver = DisplayLinkDriver(
            delay: 0,
            duration: 1,
            repeatStyle: .repeating(count: 3, autoreversing: true),
            completion: nil,
            displayLinkFactory: { _, _ in displayLink }
        )

        displayLink.driver = driver

        let instance = TestAnimationInstance()
        driver.animationInstance = instance
        driver.animationInstanceDidInitialize()

        driver.start(timeFactory: Factory.timeFactory)

        displayLink.simulateRunLoop(at: 1.5)
        instance.clearGatheredData()

        // Reverting the animation should finish executing the (reverse) cycle.
        driver.animationInstanceDidCancel(behavior: .revert)

        XCTAssertEqual(instance.executedBlockSequences.count, 1)

        if instance.executedBlockSequences.count >= 1 {
            XCTAssert(instance.executedBlockSequences[0] == (0.5, .exclusive, 0))
        }

        XCTAssertEqual(instance.renderedFrames, [0])
        XCTAssertEqual(instance.completeCount, 0)
    }

    func testCancelComplete() {
        let displayLink = TestDisplayLink()

        let driver = DisplayLinkDriver(
            delay: 0,
            duration: 1,
            repeatStyle: .none,
            completion: nil,
            displayLinkFactory: { _, _ in displayLink }
        )

        displayLink.driver = driver

        let instance = TestAnimationInstance()
        driver.animationInstance = instance
        driver.animationInstanceDidInitialize()

        driver.start(timeFactory: Factory.timeFactory)

        displayLink.simulateRunLoop(at: 0.5)
        instance.clearGatheredData()

        // Reverting the animation should finish executing the (forward) cycle.
        driver.animationInstanceDidCancel(behavior: .complete)

        XCTAssertEqual(instance.executedBlockSequences.count, 1)

        if instance.executedBlockSequences.count >= 1 {
            XCTAssert(instance.executedBlockSequences[0] == (0.5, .exclusive, 1))
        }

        XCTAssertEqual(instance.renderedFrames, [1])
        XCTAssertEqual(instance.completeCount, 0)
    }

    func testCancelCompleteLoopingWithOddCount() {
        let displayLink = TestDisplayLink()

        let driver = DisplayLinkDriver(
            delay: 0,
            duration: 1,
            repeatStyle: .repeating(count: 3, autoreversing: true),
            completion: nil,
            displayLinkFactory: { _, _ in displayLink }
        )

        displayLink.driver = driver

        let instance = TestAnimationInstance()
        driver.animationInstance = instance
        driver.animationInstanceDidInitialize()

        driver.start(timeFactory: Factory.timeFactory)

        displayLink.simulateRunLoop(at: 0.5)
        instance.clearGatheredData()

        // An odd loop count means the final cycle is forward. Reverting the animation should finish executing the
        // (forward) cycle.
        driver.animationInstanceDidCancel(behavior: .complete)

        XCTAssertEqual(instance.executedBlockSequences.count, 1)

        if instance.executedBlockSequences.count >= 1 {
            XCTAssert(instance.executedBlockSequences[0] == (0.5, .exclusive, 1))
        }

        XCTAssertEqual(instance.renderedFrames, [1])
        XCTAssertEqual(instance.completeCount, 0)
    }

    func testCancelCompleteLoopingWithOddCountDuringReverseCycle() {
        let displayLink = TestDisplayLink()

        let driver = DisplayLinkDriver(
            delay: 0,
            duration: 1,
            repeatStyle: .repeating(count: 3, autoreversing: true),
            completion: nil,
            displayLinkFactory: { _, _ in displayLink }
        )

        displayLink.driver = driver

        let instance = TestAnimationInstance()
        driver.animationInstance = instance
        driver.animationInstanceDidInitialize()

        driver.start(timeFactory: Factory.timeFactory)

        displayLink.simulateRunLoop(at: 1.5)
        instance.clearGatheredData()

        // An odd loop count means the final cycle is forward. Reverting the animation should finish executing the
        // (reverse) cycle, then run a full forward cycle.
        driver.animationInstanceDidCancel(behavior: .complete)

        XCTAssertEqual(instance.executedBlockSequences.count, 2)

        if instance.executedBlockSequences.count >= 2 {
            XCTAssert(instance.executedBlockSequences[0] == (0.5, .exclusive, 0))
            XCTAssert(instance.executedBlockSequences[1] == (0, .inclusive, 1))
        }

        XCTAssertEqual(instance.renderedFrames, [1])
        XCTAssertEqual(instance.completeCount, 0)
    }

    func testCancelCompleteLoopingWithOddCountBeforeFirstFrameRendered() {
        let displayLink = TestDisplayLink()

        let driver = DisplayLinkDriver(
            delay: 1,
            duration: 1,
            repeatStyle: .repeating(count: 3, autoreversing: true),
            completion: nil,
            displayLinkFactory: { _, _ in displayLink }
        )

        displayLink.driver = driver

        let instance = TestAnimationInstance()
        driver.animationInstance = instance
        driver.animationInstanceDidInitialize()

        driver.start(timeFactory: Factory.timeFactory)

        // An odd loop count means the final cycle is forward. If the animation is cancelled before it begins, we should
        // execute a single forward cycle.
        driver.animationInstanceDidCancel(behavior: .complete)

        XCTAssertEqual(instance.executedBlockSequences.count, 1)

        if instance.executedBlockSequences.count >= 1 {
            XCTAssert(instance.executedBlockSequences[0] == (0, .inclusive, 1))
        }

        XCTAssertEqual(instance.renderedFrames, [1])
        XCTAssertEqual(instance.completeCount, 0)
    }

    func testCancelCompleteLoopingWithEvenCount() {
        let displayLink = TestDisplayLink()

        let driver = DisplayLinkDriver(
            delay: 0,
            duration: 1,
            repeatStyle: .repeating(count: 4, autoreversing: true),
            completion: nil,
            displayLinkFactory: { _, _ in displayLink }
        )

        displayLink.driver = driver

        let instance = TestAnimationInstance()
        driver.animationInstance = instance
        driver.animationInstanceDidInitialize()

        driver.start(timeFactory: Factory.timeFactory)

        displayLink.simulateRunLoop(at: 0.5)
        instance.clearGatheredData()

        // An even loop count means the final cycle is reversed. Reverting the animation should finish executing the
        // (forward) cycle, then run a full reverse cycle.
        driver.animationInstanceDidCancel(behavior: .complete)

        XCTAssertEqual(instance.executedBlockSequences.count, 2)

        if instance.executedBlockSequences.count >= 2 {
            XCTAssert(instance.executedBlockSequences[0] == (0.5, .exclusive, 1))
            XCTAssert(instance.executedBlockSequences[1] == (1, .inclusive, 0))
        }

        XCTAssertEqual(instance.renderedFrames, [0])
        XCTAssertEqual(instance.completeCount, 0)
    }

    func testCancelCompleteLoopingWithEvenCountDuringReverseCycle() {
        let displayLink = TestDisplayLink()

        let driver = DisplayLinkDriver(
            delay: 0,
            duration: 1,
            repeatStyle: .repeating(count: 4, autoreversing: true),
            completion: nil,
            displayLinkFactory: { _, _ in displayLink }
        )

        displayLink.driver = driver

        let instance = TestAnimationInstance()
        driver.animationInstance = instance
        driver.animationInstanceDidInitialize()

        driver.start(timeFactory: Factory.timeFactory)

        displayLink.simulateRunLoop(at: 1.5)
        instance.clearGatheredData()

        // An even loop count means the final cycle is reversed. Reverting the animation should finish executing the
        // (reverse) cycle.
        driver.animationInstanceDidCancel(behavior: .complete)

        XCTAssertEqual(instance.executedBlockSequences.count, 1)

        if instance.executedBlockSequences.count >= 1 {
            XCTAssert(instance.executedBlockSequences[0] == (0.5, .exclusive, 0))
        }

        XCTAssertEqual(instance.renderedFrames, [0])
        XCTAssertEqual(instance.completeCount, 0)
    }

    func testCancelCompleteLoopingWithEvenCountBeforeFirstFrameRendered() {
        let displayLink = TestDisplayLink()

        let driver = DisplayLinkDriver(
            delay: 1,
            duration: 1,
            repeatStyle: .repeating(count: 4, autoreversing: true),
            completion: nil,
            displayLinkFactory: { _, _ in displayLink }
        )

        displayLink.driver = driver

        let instance = TestAnimationInstance()
        driver.animationInstance = instance
        driver.animationInstanceDidInitialize()

        driver.start(timeFactory: Factory.timeFactory)

        // An even loop count means the final cycle is reversed. If the animation is cancelled before it begins, we
        // don't need to execute any frames.
        driver.animationInstanceDidCancel(behavior: .complete)

        XCTAssertEqual(instance.executedBlockSequences.count, 0)
        XCTAssertEqual(instance.renderedFrames, [0])
        XCTAssertEqual(instance.completeCount, 0)
    }

}

// MARK: -

private final class TestAnimationInstance: DrivenAnimationInstance {

    // MARK: - Public Properties

    private(set) var executedBlockSequences: [(Double, AnimationInstance.Inclusivity, Double)] = []

    private(set) var renderedFrames: [Double] = []

    private(set) var completeCount: Int = 0

    // MARK: - Public Methods

    func clearGatheredData() {
        executedBlockSequences = []
        renderedFrames = []
        completeCount = 0
    }

    // MARK: - DrivenAnimationInstance

    func executeBlocks(from startingRelativeTimestamp: Double, _ fromInclusivity: AnimationInstance.Inclusivity, to endingRelativeTimestamp: Double) {
        executedBlockSequences.append((startingRelativeTimestamp, fromInclusivity, endingRelativeTimestamp))
    }

    func renderFrame(at relativeTimestamp: Double) {
        renderedFrames.append(relativeTimestamp)
    }

    func markAnimationAsComplete() {
        completeCount += 1
    }

}

// MARK: -

private final class TestDisplayLink: DisplayLinkDriverDisplayLink {

    // MARK: - DisplayLinkDriverDisplayLink

    private(set) var timestamp: CFTimeInterval = 0

    func add(to runloop: RunLoop, forMode mode: RunLoop.Mode) {
        // No-op.
    }

    func invalidate() {
        // No-op.
    }

    // MARK: - Private  Properties

    unowned var driver: DisplayLinkDriver!

    // MARK: - Public Methods

    func simulateRunLoop(at timeOffset: CFTimeInterval) {
        timestamp = Factory.startTime + timeOffset

        driver.renderCurrentFrame()
    }

}

// MARK: -

private enum Factory {
    // An arbitrarily selected start time for the display link to begin, which must be greater than zero to
    // differentiate between not being added to the run loop.
    static let startTime: CFTimeInterval = 1000

    static let timeFactory: () -> CFTimeInterval = { Factory.startTime }

}
