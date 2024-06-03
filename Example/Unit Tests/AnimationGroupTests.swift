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

final class AnimationGroupTests: XCTestCase {

    // MARK: - Tests - Keyframes

    @MainActor
    func testKeyframes_twoElementsOfSameType() {
        var animationGroup = AnimationGroup()

        var animationOne = Animation<ElementA>()
        animationOne.addKeyframe(for: \.propertyOne, at: 0, value: 0)
        animationOne.addKeyframe(for: \.propertyOne, at: 1, value: 1)

        let elementOne = ElementA()
        animationGroup.addAnimation(animationOne, for: elementOne, startingAt: 0, relativeDuration: 1)

        var animationTwo = Animation<ElementA>()
        animationTwo.addKeyframe(for: \.propertyOne, at: 0, value: 1)
        animationTwo.addKeyframe(for: \.propertyOne, at: 1, value: 0)

        let elementTwo = ElementA()
        animationGroup.addAnimation(animationTwo, for: elementTwo, startingAt: 0, relativeDuration: 1)

        let driver = TestDriver()

        let animationInstance = AnimationInstance(
            animation: animationGroup.animation,
            element: animationGroup.elementContainer,
            driver: driver
        )

        driver.runForward(to: 0.25)
        XCTAssertEqual(elementOne.propertyOne, 0.25)
        XCTAssertEqual(elementTwo.propertyOne, 0.75)

        _ = animationInstance
    }

    @MainActor
    func testKeyframes_twoElementsOfDifferentTypes() {
        var animationGroup = AnimationGroup()

        var animationOne = Animation<ElementA>()
        animationOne.addKeyframe(for: \.propertyOne, at: 0, value: 0)
        animationOne.addKeyframe(for: \.propertyOne, at: 1, value: 1)

        let elementOne = ElementA()
        animationGroup.addAnimation(animationOne, for: elementOne, startingAt: 0, relativeDuration: 1)

        var animationTwo = Animation<ElementB>()
        animationTwo.addKeyframe(for: \.property, at: 0, value: 1)
        animationTwo.addKeyframe(for: \.property, at: 1, value: 0)

        let elementTwo = ElementB()
        animationGroup.addAnimation(animationTwo, for: elementTwo, startingAt: 0, relativeDuration: 1)

        let driver = TestDriver()

        let animationInstance = AnimationInstance(
            animation: animationGroup.animation,
            element: animationGroup.elementContainer,
            driver: driver
        )

        driver.runForward(to: 0.25)
        XCTAssertEqual(elementOne.propertyOne, 0.25)
        XCTAssertEqual(elementTwo.property, 0.75)

        _ = animationInstance
    }

    @MainActor
    func testKeyframes_twoAnimationsForSameElement() {
        var animationGroup = AnimationGroup()

        let element = ElementA()

        var animationOne = Animation<ElementA>()
        animationOne.addKeyframe(for: \.propertyOne, at: 0, value: 0)
        animationOne.addKeyframe(for: \.propertyOne, at: 1, value: 1)
        animationGroup.addAnimation(animationOne, for: element, startingAt: 0, relativeDuration: 1)

        var animationTwo = Animation<ElementA>()
        animationTwo.addKeyframe(for: \.propertyTwo, at: 0, value: 1)
        animationTwo.addKeyframe(for: \.propertyTwo, at: 1, value: 0)
        animationGroup.addAnimation(animationTwo, for: element, startingAt: 0, relativeDuration: 1)

        let driver = TestDriver()

        let animationInstance = AnimationInstance(
            animation: animationGroup.animation,
            element: animationGroup.elementContainer,
            driver: driver
        )

        driver.runForward(to: 0.25)
        XCTAssertEqual(element.propertyOne, 0.25)
        XCTAssertEqual(element.propertyTwo, 0.75)

        _ = animationInstance
    }

    @MainActor
    func testKeyframes_offsetAnimations() {
        var animationGroup = AnimationGroup()

        var animationOne = Animation<ElementA>()
        animationOne.addKeyframe(for: \.propertyOne, at: 0, value: 0)
        animationOne.addKeyframe(for: \.propertyOne, at: 1, value: 1)

        let elementOne = ElementA()
        animationGroup.addAnimation(animationOne, for: elementOne, startingAt: 0, relativeDuration: 0.8)

        var animationTwo = Animation<ElementA>()
        animationTwo.addKeyframe(for: \.propertyOne, at: 0, value: 1)
        animationTwo.addKeyframe(for: \.propertyOne, at: 1, value: 0)

        let elementTwo = ElementA()
        animationGroup.addAnimation(animationTwo, for: elementTwo, startingAt: 0.3, relativeDuration: 0.6)

        let driver = TestDriver()

        let animationInstance = AnimationInstance(
            animation: animationGroup.animation,
            element: animationGroup.elementContainer,
            driver: driver
        )

        driver.runForward(to: 0.2)
        XCTAssertEqual(elementOne.propertyOne, 0.25)
        XCTAssertEqual(elementTwo.propertyOne, 1)

        driver.runForward(to: 0.6)
        XCTAssertEqual(elementOne.propertyOne, 0.75, accuracy: 0.001)
        XCTAssertEqual(elementTwo.propertyOne, 0.5)

        driver.runForward(to: 0.9)
        XCTAssertEqual(elementOne.propertyOne, 1)
        XCTAssertEqual(elementTwo.propertyOne, 0)

        _ = animationInstance
    }

    // MARK: - Tests - Completion Handler

    @MainActor
    func testCompletionCalledOnComplete() {
        var animationGroup = AnimationGroup()
        animationGroup.implicitDuration = 0.05

        let completionExpectation = expectation(description: "Calls completion handler")
        animationGroup.addCompletionHandler { finished in
            XCTAssertTrue(finished)
            completionExpectation.fulfill()
        }

        animationGroup.perform()

        waitForExpectations(timeout: 0.5, handler: nil)
    }

    @MainActor
    func testCompletionCalledOnCancel() {
        var animationGroup = AnimationGroup()
        animationGroup.implicitDuration = 1

        let completionExpectation = expectation(description: "Calls completion handler")
        animationGroup.addCompletionHandler { finished in
            XCTAssertFalse(finished)
            completionExpectation.fulfill()
        }

        let animationInstance = animationGroup.perform()
        animationInstance.cancel()

        waitForExpectations(timeout: 0.5, handler: nil)
    }

    // MARK: - Tests - Properties

    @MainActor
    func testDuration() {
        var animationGroup = AnimationGroup()

        // The duration should default to 1 second.
        XCTAssertEqual(animationGroup.implicitDuration, 1)

        animationGroup.implicitDuration = 3
        XCTAssertEqual(animationGroup.implicitDuration, 3)
        XCTAssertEqual(animationGroup.animation.implicitDuration, 3)
    }

    @MainActor
    func testRepeatStyle() {
        var animationGroup = AnimationGroup()

        // The repeat style should default to not repeating.
        XCTAssertEqual(animationGroup.implicitRepeatStyle, .noRepeat)

        animationGroup.implicitRepeatStyle = .infinitelyRepeating(autoreversing: true)
        XCTAssertEqual(animationGroup.implicitRepeatStyle, .infinitelyRepeating(autoreversing: true))
        XCTAssertEqual(animationGroup.animation.implicitRepeatStyle, .infinitelyRepeating(autoreversing: true))
    }

    @MainActor
    func testCurve() {
        var animationGroup = AnimationGroup()

        // The curve should default to linear.
        XCTAssert(animationGroup.curve is LinearAnimationCurve)

        animationGroup.curve = ParabolicEaseInAnimationCurve()
        XCTAssert(animationGroup.curve is ParabolicEaseInAnimationCurve)
        XCTAssert(animationGroup.animation.curve is ParabolicEaseInAnimationCurve)
    }

}

// MARK: -

private extension AnimationGroupTests {

    final class ElementA {

        var propertyOne: CGFloat = -1

        var propertyTwo: Float = -2

    }

    final class ElementB {

        var property: CGFloat = -1

    }

}
