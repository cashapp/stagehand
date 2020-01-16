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

final class ChildAnimationTests: XCTestCase {

    // MARK: - Tests - Keyframes

    func testKeyframes_simpleConfiguration() {
        var childAnimation = Animation<Subelement>()
        childAnimation.addKeyframe(for: \.propertyOne, at: 0, value: 0)
        childAnimation.addKeyframe(for: \.propertyOne, at: 1, value: 1)

        var animation = Animation<Element>()
        animation.addChild(childAnimation, for: \.subelementOne, startingAt: 0, relativeDuration: 1)
        animation.addChild(childAnimation, for: \.subelementTwo, startingAt: 0, relativeDuration: 1)

        let element = Element()

        let driver = TestDriver()

        let animationInstance = AnimationInstance(
            animation: animation,
            element: element,
            driver: driver
        )

        driver.runForward(to: 0.25)
        XCTAssertEqual(element.subelementOne.propertyOne, 0.25)
        XCTAssertEqual(element.subelementTwo.propertyOne, 0.25)

        _ = animationInstance
    }

    func testKeyframes_twoChildrenForSameSubelement() {
        var childAnimation1 = Animation<Subelement>()
        childAnimation1.addKeyframe(for: \.propertyOne, at: 0, value: 0)
        childAnimation1.addKeyframe(for: \.propertyOne, at: 1, value: 1)

        var childAnimation2 = Animation<Subelement>()
        childAnimation2.addKeyframe(for: \.propertyTwo, at: 0, value: 0)
        childAnimation2.addKeyframe(for: \.propertyTwo, at: 1, value: 1)

        var animation = Animation<Element>()
        animation.addChild(childAnimation1, for: \.subelementOne, startingAt: 0, relativeDuration: 1)
        animation.addChild(childAnimation2, for: \.subelementOne, startingAt: 0, relativeDuration: 1)

        let element = Element()

        let driver = TestDriver()

        let animationInstance = AnimationInstance(
            animation: animation,
            element: element,
            driver: driver
        )

        driver.runForward(to: 0.25)
        XCTAssertEqual(element.subelementOne.propertyOne, 0.25)
        XCTAssertEqual(element.subelementOne.propertyTwo, 0.25)

        _ = animationInstance
    }

    func testKeyframes_childOverPartialCycle() {
        var childAnimation = Animation<Subelement>()
        childAnimation.addKeyframe(for: \.propertyOne, at: 0, value: 0)
        childAnimation.addKeyframe(for: \.propertyOne, at: 1, value: 1)

        var animation = Animation<Element>()
        animation.addChild(childAnimation, for: \.subelementOne, startingAt: 0.25, relativeDuration: 0.5)

        let element = Element()

        let driver = TestDriver()

        let animationInstance = AnimationInstance(
            animation: animation,
            element: element,
            driver: driver
        )

        // Until the child animation begins, the value should be the initial value.
        driver.runForward(to: 0.2)
        XCTAssertEqual(element.subelementOne.propertyOne, 0)

        driver.runForward(to: 0.5)
        XCTAssertEqual(element.subelementOne.propertyOne, 0.5)

        // After the child ends, the value should be the final value.
        driver.runForward(to: 0.8)
        XCTAssertEqual(element.subelementOne.propertyOne, 1)

        _ = animationInstance
    }

    func testKeyframes_childOverriddenByParent() {
        var childAnimation = Animation<Subelement>()
        childAnimation.addKeyframe(for: \.propertyOne, at: 0, value: 1)
        childAnimation.addKeyframe(for: \.propertyOne, at: 1, value: 0)

        var animation = Animation<Element>()
        animation.addKeyframe(for: \.subelementOne.propertyOne, at: 0, value: 0)
        animation.addKeyframe(for: \.subelementOne.propertyOne, at: 1, value: 1)

        animation.addChild(childAnimation, for: \.subelementOne, startingAt: 0, relativeDuration: 1)

        let element = Element()

        let driver = TestDriver()

        let animationInstance = AnimationInstance(
            animation: animation,
            element: element,
            driver: driver
        )

        // When the parent animation specifies keyframes for a property, those keyframes should be preferred over that
        // of the child animation (even when the child animation is added after the keyframes are defined).
        driver.runForward(to: 0.25)
        XCTAssertEqual(element.subelementOne.propertyOne, 0.25)

        _ = animationInstance
    }

    // This test is currently disabled because it doesn't handle delaying the start of the second child animation until
    // the first has finished.
    func testKeyframes_sequentialChildrenForSameProperty() {
        var downChildAnimation = Animation<Subelement>()
        downChildAnimation.addKeyframe(for: \.propertyOne, at: 0, value: 1)
        downChildAnimation.addKeyframe(for: \.propertyOne, at: 1, value: 0)

        var upChildAnimation = Animation<Subelement>()
        upChildAnimation.addKeyframe(for: \.propertyOne, at: 0, value: 0)
        upChildAnimation.addKeyframe(for: \.propertyOne, at: 1, value: 1)

        var animation = Animation<Element>()
        animation.addChild(downChildAnimation, for: \.subelementOne, startingAt: 0, relativeDuration: 0.5)
        animation.addChild(upChildAnimation, for: \.subelementOne, startingAt: 0.5, relativeDuration: 0.5)

        let element = Element()

        let driver = TestDriver()

        let animationInstance = AnimationInstance(
            animation: animation,
            element: element,
            driver: driver
        )

        driver.runForward(to: 0)
        XCTAssertEqual(element.subelementOne.propertyOne, 1)

        driver.runForward(to: 0.25)
        XCTAssertEqual(element.subelementOne.propertyOne, 0.5)

        driver.runForward(to: 0.5)
        XCTAssertEqual(element.subelementOne.propertyOne, 0)

        driver.runForward(to: 0.75)
        XCTAssertEqual(element.subelementOne.propertyOne, 0.5)

        driver.runForward(to: 1)
        XCTAssertEqual(element.subelementOne.propertyOne, 1)

        _ = animationInstance
    }

}

// MARK: -

private extension ChildAnimationTests {

    final class Element {

        var subelementOne: Subelement = .init()

        var subelementTwo: Subelement = .init()

    }

    final class Subelement {

        var propertyOne: CGFloat = -1

        var propertyTwo: CGFloat = -1

    }

}
