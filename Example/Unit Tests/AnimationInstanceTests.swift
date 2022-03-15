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

final class AnimationInstanceTests: XCTestCase {

    // MARK: - Tests - Keyframes

    func testKeyframesWithFixedValues() {
        let element = AnimatableElement(
            propertyOne: 0,
            propertyTwo: 0
        )

        var animation = Animation<AnimatableElement>()

        // Run the first property forward.
        animation.addKeyframe(for: \.propertyOne, at: 0, value: 1)
        animation.addKeyframe(for: \.propertyOne, at: 1, value: 2)

        // Run the second property in reverse.
        animation.addKeyframe(for: \.propertyTwo, at: 0, value: 2)
        animation.addKeyframe(for: \.propertyTwo, at: 1, value: 1)

        let driver = TestDriver()

        let animationInstance = AnimationInstance(
            animation: animation,
            element: element,
            driver: driver
        )

        driver.runForward(to: 0)
        XCTAssertEqual(element.propertyOne, 1)
        XCTAssertEqual(element.propertyTwo, 2)

        driver.runForward(to: 0.5)
        XCTAssertEqual(element.propertyOne, 1.5)
        XCTAssertEqual(element.propertyTwo, 1.5)

        driver.runForward(to: 1)
        XCTAssertEqual(element.propertyOne, 2)
        XCTAssertEqual(element.propertyTwo, 1)

        _ = animationInstance
    }

    func testKeyframesWithRelativeValues() {
        let element = AnimatableElement(
            propertyOne: 2,
            propertyTwo: 2
        )

        var animation = Animation<AnimatableElement>()

        animation.addKeyframe(for: \.propertyOne, at: 0, value: 1)
        animation.addKeyframe(for: \.propertyOne, at: 1, relativeValue: { $0 })

        animation.addKeyframe(for: \.propertyTwo, at: 0, relativeValue: { $0 })
        animation.addKeyframe(for: \.propertyTwo, at: 1, value: 1)

        let driver = TestDriver()

        let animationInstance = AnimationInstance(
            animation: animation,
            element: element,
            driver: driver
        )

        driver.runForward(to: 0)
        XCTAssertEqual(element.propertyOne, 1)
        XCTAssertEqual(element.propertyTwo, 2)

        driver.runForward(to: 0.5)
        XCTAssertEqual(element.propertyOne, 1.5)
        XCTAssertEqual(element.propertyTwo, 1.5)

        driver.runForward(to: 1)
        XCTAssertEqual(element.propertyOne, 2)
        XCTAssertEqual(element.propertyTwo, 1)

        _ = animationInstance
    }

    func testKeyframesWithMissingTerminalValues() {
        let element = AnimatableElement(
            propertyOne: 0
        )

        var animation = Animation<AnimatableElement>()

        animation.addKeyframe(for: \.propertyOne, at: 0.25, value: 2)
        animation.addKeyframe(for: \.propertyOne, at: 0.75, value: 4)

        let driver = TestDriver()

        let animationInstance = AnimationInstance(
            animation: animation,
            element: element,
            driver: driver
        )

        // Before the first keyframe, the value of the first keyframe should be used.
        driver.runForward(to: 0)
        XCTAssertEqual(element.propertyOne, 2)

        driver.runForward(to: 0.25)
        XCTAssertEqual(element.propertyOne, 2)

        driver.runForward(to: 0.5)
        XCTAssertEqual(element.propertyOne, 3)

        driver.runForward(to: 0.75)
        XCTAssertEqual(element.propertyOne, 4)

        // After the last keyframe, the value of the last keyframe should be used.
        driver.runForward(to: 1)
        XCTAssertEqual(element.propertyOne, 4)

        _ = animationInstance
    }

    func testKeyframesWithMultipleSegments() {
        let element = AnimatableElement(
            propertyOne: 0
        )

        var animation = Animation<AnimatableElement>()

        animation.addKeyframe(for: \.propertyOne, at: 0, value: 1)
        animation.addKeyframe(for: \.propertyOne, at: 0.5, value: 2)
        animation.addKeyframe(for: \.propertyOne, at: 1, value: 4)

        let driver = TestDriver()

        let animationInstance = AnimationInstance(
            animation: animation,
            element: element,
            driver: driver
        )

        driver.runForward(to: 0)
        XCTAssertEqual(element.propertyOne, 1)

        driver.runForward(to: 0.25)
        XCTAssertEqual(element.propertyOne, 1.5)

        driver.runForward(to: 0.5)
        XCTAssertEqual(element.propertyOne, 2)

        driver.runForward(to: 0.75)
        XCTAssertEqual(element.propertyOne, 3)

        driver.runForward(to: 1)
        XCTAssertEqual(element.propertyOne, 4)

        _ = animationInstance
    }

    func testKeyframesOfOptionalProperty() {
        let element = AnimatableElement()

        var animation = Animation<AnimatableElement>()

        animation.addKeyframe(for: \.propertyFive, at: 0, value: 0)
        animation.addKeyframe(for: \.propertyFive, at: 1, value: 1)

        let driver = TestDriver()

        let animationInstance = AnimationInstance(
            animation: animation,
            element: element,
            driver: driver
        )

        driver.runForward(to: 0.5)
        XCTAssertEqual(element.propertyFive, 0.5)

        _ = animationInstance
    }

    // MARK: - Tests - Property Assignments

    func testPropertyAssignment() {
        let initialValue = "Hello world"
        let midpointValue = "What's up world"
        let finalValue = "Yo"

        let element = AnimatableElement(
            propertyThree: initialValue
        )

        var animation = Animation<AnimatableElement>()
        animation.addAssignment(for: \.propertyThree, at: 0.5, value: midpointValue)
        animation.addAssignment(for: \.propertyThree, at: 1, value: finalValue)

        let driver = TestDriver()

        let animationInstance = AnimationInstance(
            animation: animation,
            element: element,
            driver: driver
        )

        driver.runForward(to: 0.33)
        XCTAssertEqual(element.propertyThree, initialValue)

        driver.runForward(to: 0.5)
        XCTAssertEqual(element.propertyThree, midpointValue)

        driver.runForward(to: 0.66)
        XCTAssertEqual(element.propertyThree, midpointValue)

        driver.runForward(to: 1)
        XCTAssertEqual(element.propertyThree, finalValue)

        animationInstance.executeBlocks(from: 1, .inclusive, to: 0.66)
        XCTAssertEqual(element.propertyThree, midpointValue)

        animationInstance.executeBlocks(from: 1, .inclusive, to: 0.5)
        XCTAssertEqual(element.propertyThree, initialValue)

        _ = animationInstance
    }

    // MARK: - Tests - Execution Blocks

    func testExecutionBlocks() {
        let element = AnimatableElement()

        var executedBlocks: [String] = []

        var animation = Animation<AnimatableElement>()

        animation.addExecution(
            onForward: { _ in executedBlocks.append("A") },
            onReverse: { _ in executedBlocks.append("A'") },
            at: 0
        )

        animation.addExecution(
            onForward: { _ in executedBlocks.append("C") },
            onReverse: { _ in executedBlocks.append("C'") },
            at: 0.75
        )

        animation.addExecution(
            onForward: { _ in executedBlocks.append("B") },
            onReverse: { _ in executedBlocks.append("B'") },
            at: 0.5
        )

        let animationInstance = AnimationInstance(
            animation: animation,
            element: element,
            driver: TestDriver()
        )

        // Test that the starting timestamp is inclusive when specified as such.
        animationInstance.executeBlocks(from: 0, .inclusive, to: 0.25)
        XCTAssertEqual(executedBlocks, ["A"])

        // Test that the ending timestamp is inclusive.
        executedBlocks = []
        animationInstance.executeBlocks(from: 0.25, .exclusive, to: 0.5)
        XCTAssertEqual(executedBlocks, ["B"])

        // Test that the execution blocks are executed in the correct order.
        executedBlocks = []
        animationInstance.executeBlocks(from: 0, .inclusive, to: 1)
        XCTAssertEqual(executedBlocks, ["A", "B", "C"])

        // Test that excluding the starting timestamp doesn't include a block at that timestamp.
        executedBlocks = []
        animationInstance.executeBlocks(from: 0, .exclusive, to: 1)
        XCTAssertEqual(executedBlocks, ["B", "C"])

        // Test that the ending timestamp is inclusive when running in reverse.
        executedBlocks = []
        animationInstance.executeBlocks(from: 1, .exclusive, to: 0.75)
        XCTAssertEqual(executedBlocks, ["C'"])

        // Test that the starting timestamp is inclusive when specified as such.
        executedBlocks = []
        animationInstance.executeBlocks(from: 0.75, .inclusive, to: 0.5)
        XCTAssertEqual(executedBlocks, ["C'", "B'"])

        // Test that the starting timestamp is exclusive when specified as such.
        executedBlocks = []
        animationInstance.executeBlocks(from: 0.75, .exclusive, to: 0.5)
        XCTAssertEqual(executedBlocks, ["B'"])

        // Test that the blocks are ordered correctly when running in reverse.
        executedBlocks = []
        animationInstance.executeBlocks(from: 1, .inclusive, to: 0)
        XCTAssertEqual(executedBlocks, ["C'", "B'", "A'"])
    }

    // MARK: - Tests - Per-Frame Execution Blocks

    func testPerFrameExecutionBlocks() {
        let element = AnimatableElement()

        var animation = Animation<AnimatableElement>()
        animation.curve = ReverseAnimationCurve()

        var executionCount: Int = 0
        var lastContext: Animation<AnimatableElement>.FrameContext? = nil

        func resetExecutedContext() {
            executionCount = 0
            lastContext = nil
        }

        animation.addPerFrameExecution { context in
            executionCount += 1
            lastContext = context
        }

        let animationInstance = AnimationInstance(
            animation: animation,
            element: element,
            driver: TestDriver()
        )

        animationInstance.renderFrame(at: 0)
        XCTAssertEqual(executionCount, 1)
        XCTAssertEqual(
            lastContext,
            Animation<AnimatableElement>.FrameContext(
                element: element,
                uncurvedProgress: 0,
                progress: 1
            )
        )

        resetExecutedContext()

        animationInstance.renderFrame(at: 0.25)
        XCTAssertEqual(executionCount, 1)
        XCTAssertEqual(
            lastContext,
            Animation<AnimatableElement>.FrameContext(
                element: element,
                uncurvedProgress: 0.25,
                progress: 0.75
            )
        )
    }

    // MARK: - Tests - Animation Curves

    func testAnimationCurves() {
        let element = AnimatableElement()

        var animation = Animation<AnimatableElement>()
        animation.curve = SinusoidalEaseInEaseOutAnimationCurve()

        animation.addKeyframe(for: \.propertyFour, at: 0, value: 0)
        animation.addKeyframe(for: \.propertyFour, at: 1, value: 1)

        animation.addPerFrameExecution { context in
            XCTAssertEqual(context.progress, element.propertyFour)
        }

        let animationInstance = AnimationInstance(
            animation: animation,
            element: element,
            driver: TestDriver()
        )

        animationInstance.renderFrame(at: 0)
        animationInstance.renderFrame(at: 0.25)
        animationInstance.renderFrame(at: 0.5)
        animationInstance.renderFrame(at: 0.75)
        animationInstance.renderFrame(at: 1)
    }

}

// MARK: -

extension AnimationInstanceTests {

    final class AnimatableElement: Equatable {

        // MARK: - Life Cycle

        init(
            propertyOne: CGFloat = 0,
            propertyTwo: CGFloat = 0,
            propertyThree: String = "",
            propertyFour: Double = 0,
            propertyFive: Double? = nil
        ) {
            self.propertyOne = propertyOne
            self.propertyTwo = propertyTwo
            self.propertyThree = propertyThree
            self.propertyFour = propertyFour
            self.propertyFive = propertyFive
        }

        // MARK: - Public Properties

        var propertyOne: CGFloat

        var propertyTwo: CGFloat

        var propertyThree: String

        var propertyFour: Double

        var propertyFive: Double?

        // MARK: - Equatable

        static func == (lhs: AnimationInstanceTests.AnimatableElement, rhs: AnimationInstanceTests.AnimatableElement) -> Bool {
            return lhs.propertyOne == rhs.propertyOne
                && lhs.propertyTwo == rhs.propertyTwo
                && lhs.propertyThree == rhs.propertyThree
                && lhs.propertyFour == rhs.propertyFour
                && lhs.propertyFive == rhs.propertyFive
        }

    }

}

// MARK: -

private struct ReverseAnimationCurve: AnimationCurve {

    func adjustedProgress(for progress: Double) -> Double {
        return 1 - progress
    }

    func rawProgress(for adjustedProgress: Double) -> [Double] {
        return [1 - adjustedProgress]
    }

}

// MARK: -

extension Animation.FrameContext: Equatable where ElementType: Equatable {

    public static func == (lhs: Animation<ElementType>.FrameContext, rhs: Animation<ElementType>.FrameContext) -> Bool {
        return lhs.element == rhs.element
            && lhs.uncurvedProgress == rhs.uncurvedProgress
            && lhs.progress == rhs.progress
    }

}

// MARK: -

extension Double: AnimatableOptionalProperty {

    public static func optionalValue(between initialValue: Double?, and finalValue: Double?, at progress: Double) -> Double? {
        guard let initialValue = initialValue, let finalValue = finalValue else {
            return nil
        }

        return Double.value(between: initialValue, and: finalValue, at: progress)
    }

}
