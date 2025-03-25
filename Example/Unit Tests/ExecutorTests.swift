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

@MainActor
final class ExecutorTests: XCTestCase {

    // MARK: - Tests - Property Assignment

    func testPropertyAssignment() {
        let initialValue = "A"
        let midpointValue = "B"
        let finalValue = "C"

        let element = Element(property: initialValue)

        var animation = Animation<Element>()
        animation.addAssignment(for: \.property, at: 0.5, value: midpointValue)
        animation.addAssignment(for: \.property, at: 1, value: finalValue)

        let executor = Executor(animation: animation, element: element)

        executor.executeBlocks(from: 0, .inclusive, to: 0.49)
        XCTAssertEqual(element.property, initialValue)

        executor.executeBlocks(from: 0.49, .exclusive, to: 0.51)
        XCTAssertEqual(element.property, midpointValue)

        executor.executeBlocks(from: 0.51, .exclusive, to: 0.99)
        XCTAssertEqual(element.property, midpointValue)

        executor.executeBlocks(from: 0.99, .exclusive, to: 1)
        XCTAssertEqual(element.property, finalValue)

        executor.executeBlocks(from: 1, .inclusive, to: 0.99)
        XCTAssertEqual(element.property, midpointValue)

        executor.executeBlocks(from: 0.99, .exclusive, to: 0.51)
        XCTAssertEqual(element.property, midpointValue)

        executor.executeBlocks(from: 0.51, .exclusive, to: 0.49)
        XCTAssertEqual(element.property, initialValue)

        executor.executeBlocks(from: 0.49, .exclusive, to: 0)
        XCTAssertEqual(element.property, initialValue)
    }

    func testPropertyAssignmentOnExactFrame() {
        let initialValue = "A"
        let midpointValue = "B"
        let finalValue = "C"

        let element = Element(property: initialValue)

        var animation = Animation<Element>()
        animation.addAssignment(for: \.property, at: 0.5, value: midpointValue)
        animation.addAssignment(for: \.property, at: 1, value: finalValue)

        let executor = Executor(animation: animation, element: element)

        executor.executeBlocks(from: 0, .inclusive, to: 0.49)
        XCTAssertEqual(element.property, initialValue)

        // Ending on the assignment's timestamp exactly should still trigger the assignment.
        executor.executeBlocks(from: 0.49, .exclusive, to: 0.5)
        XCTAssertEqual(element.property, midpointValue)
    }

    func testPropertyAssignmentSkippingFrames() {
        let initialValue = "A"
        let midpointValue = "B"
        let finalValue = "C"

        let element = Element(property: initialValue)

        var animation = Animation<Element>()
        animation.addAssignment(for: \.property, at: 0.5, value: midpointValue)
        animation.addAssignment(for: \.property, at: 1, value: finalValue)

        let executor = Executor(animation: animation, element: element)

        executor.executeBlocks(from: 0, .inclusive, to: 0.49)
        XCTAssertEqual(element.property, initialValue)

        // Jumping from 0.49 to 1 should execute the assignments at 0.5 and 1.
        executor.executeBlocks(from: 0.49, .exclusive, to: 1)
        XCTAssertEqual(element.property, finalValue)

        // We should still have the inner midpoint value stored for the reverse cycle.
        executor.executeBlocks(from: 1, .inclusive, to: 0.99)
        XCTAssertEqual(element.property, midpointValue)

        executor.executeBlocks(from: 0.99, .exclusive, to: 0.51)
        XCTAssertEqual(element.property, midpointValue)

        executor.executeBlocks(from: 0.51, .exclusive, to: 0.49)
        XCTAssertEqual(element.property, initialValue)

        executor.executeBlocks(from: 0.49, .exclusive, to: 0)
        XCTAssertEqual(element.property, initialValue)
    }

    func testPropertyAssignmentInChildAnimation() {
        let initialValue = "-"
        let startValue = "A"
        let midpointValue = "B"
        let finalValue = "C"

        let element = Element(property: initialValue)

        var childAnimation = Animation<Element>()
        childAnimation.addAssignment(for: \.property, at: 0, value: startValue)
        childAnimation.addAssignment(for: \.property, at: 0.5, value: midpointValue)
        childAnimation.addAssignment(for: \.property, at: 1, value: finalValue)

        var parentAnimation = Animation<Element>()
        parentAnimation.addChild(childAnimation, for: \.self, startingAt: 0.3, relativeDuration: 0.6)

        let executor = Executor(animation: parentAnimation, element: element)

        executor.executeBlocks(from: 0, .inclusive, to: 0.29)
        XCTAssertEqual(element.property, initialValue)

        executor.executeBlocks(from: 0.29, .exclusive, to: 0.31)
        XCTAssertEqual(element.property, startValue)

        executor.executeBlocks(from: 0.31, .exclusive, to: 0.59)
        XCTAssertEqual(element.property, startValue)

        executor.executeBlocks(from: 0.59, .exclusive, to: 0.61)
        XCTAssertEqual(element.property, midpointValue)

        executor.executeBlocks(from: 0.61, .exclusive, to: 0.89)
        XCTAssertEqual(element.property, midpointValue)

        executor.executeBlocks(from: 0.89, .exclusive, to: 0.91)
        XCTAssertEqual(element.property, finalValue)

        executor.executeBlocks(from: 0.91, .exclusive, to: 1)
        executor.executeBlocks(from: 1, .inclusive, to: 0.91)
        XCTAssertEqual(element.property, finalValue)

        executor.executeBlocks(from: 0.91, .exclusive, to: 0.89)
        XCTAssertEqual(element.property, midpointValue)

        executor.executeBlocks(from: 0.89, .exclusive, to: 0.61)
        XCTAssertEqual(element.property, midpointValue)

        executor.executeBlocks(from: 0.61, .exclusive, to: 0.59)
        XCTAssertEqual(element.property, startValue)

        executor.executeBlocks(from: 0.59, .exclusive, to: 0.31)
        XCTAssertEqual(element.property, startValue)

        executor.executeBlocks(from: 0.31, .exclusive, to: 0.29)
        XCTAssertEqual(element.property, initialValue)
    }

    func testPropertyAssignmentWithCurvedAnimation() {
        let initialValue = "A"
        let midpointValue = "B"
        let finalValue = "C"

        let element = Element(property: initialValue)

        var animation = Animation<Element>()
        animation.addAssignment(for: \.property, at: 0.5, value: midpointValue)
        animation.addAssignment(for: \.property, at: 1, value: finalValue)

        // Apply a parabolic easing curve. We can calculate the uncurved timestamp at which the assignment should occur
        // by taking the square root of the curved timestamp.
        animation.curve = ParabolicEaseInAnimationCurve()

        let executor = Executor(animation: animation, element: element)

        executor.executeBlocks(from: 0, .inclusive, to: 0.7)
        XCTAssertEqual(element.property, initialValue)

        executor.executeBlocks(from: 0.7, .exclusive, to: 0.71)
        XCTAssertEqual(element.property, midpointValue)

        executor.executeBlocks(from: 0.71, .exclusive, to: 0.99)
        XCTAssertEqual(element.property, midpointValue)

        executor.executeBlocks(from: 0.99, .exclusive, to: 1)
        XCTAssertEqual(element.property, finalValue)

        executor.executeBlocks(from: 1, .inclusive, to: 0.99)
        XCTAssertEqual(element.property, midpointValue)

        executor.executeBlocks(from: 0.99, .exclusive, to: 0.71)
        XCTAssertEqual(element.property, midpointValue)

        executor.executeBlocks(from: 0.71, .exclusive, to: 0.7)
        XCTAssertEqual(element.property, initialValue)

        executor.executeBlocks(from: 0.7, .exclusive, to: 0)
        XCTAssertEqual(element.property, initialValue)
    }

    func testPropertyAssignmentInCurvedChildAnimation() {
        let initialValue = "-"
        let startValue = "A"
        let midpointValue = "B"
        let finalValue = "C"

        let element = Element(property: initialValue)

        var childAnimation = Animation<Element>()
        childAnimation.addAssignment(for: \.property, at: 0, value: startValue)
        childAnimation.addAssignment(for: \.property, at: 0.5, value: midpointValue)
        childAnimation.addAssignment(for: \.property, at: 1, value: finalValue)

        // Apply a parabolic easing curve. We can calculate the uncurved timestamp at which the assignment should occur
        // by taking the square root of the curved timestamp.
        childAnimation.curve = ParabolicEaseInAnimationCurve()

        var parentAnimation = Animation<Element>()
        parentAnimation.addChild(childAnimation, for: \.self, startingAt: 0.3, relativeDuration: 0.6)

        let executor = Executor(animation: parentAnimation, element: element)

        executor.executeBlocks(from: 0, .inclusive, to: 0.29)
        XCTAssertEqual(element.property, initialValue)

        executor.executeBlocks(from: 0.29, .exclusive, to: 0.31)
        XCTAssertEqual(element.property, startValue)

        executor.executeBlocks(from: 0.31, .exclusive, to: 0.72)
        XCTAssertEqual(element.property, startValue)

        executor.executeBlocks(from: 0.72, .exclusive, to: 0.73)
        XCTAssertEqual(element.property, midpointValue)

        executor.executeBlocks(from: 0.73, .exclusive, to: 0.89)
        XCTAssertEqual(element.property, midpointValue)

        executor.executeBlocks(from: 0.89, .exclusive, to: 0.91)
        XCTAssertEqual(element.property, finalValue)

        executor.executeBlocks(from: 0.91, .exclusive, to: 1)
        executor.executeBlocks(from: 1, .inclusive, to: 0.91)
        XCTAssertEqual(element.property, finalValue)

        executor.executeBlocks(from: 0.91, .exclusive, to: 0.89)
        XCTAssertEqual(element.property, midpointValue)

        executor.executeBlocks(from: 0.89, .exclusive, to: 0.73)
        XCTAssertEqual(element.property, midpointValue)

        executor.executeBlocks(from: 0.73, .exclusive, to: 0.72)
        XCTAssertEqual(element.property, startValue)

        executor.executeBlocks(from: 0.72, .exclusive, to: 0.31)
        XCTAssertEqual(element.property, startValue)

        executor.executeBlocks(from: 0.31, .exclusive, to: 0.29)
        XCTAssertEqual(element.property, initialValue)
    }

    // MARK: - Tests - Execution Blocks

    func testExecutionBlocks() {
        var executedBlocks: [String] = []

        var animation = Animation<Element>()
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

        let element = Element()
        let executor = Executor(animation: animation, element: element)

        // Test that the starting timestamp is inclusive when specified as such.
        executor.executeBlocks(from: 0, .inclusive, to: 0.25)
        XCTAssertEqual(executedBlocks, ["A"])

        // Test that the ending timestamp is inclusive.
        executedBlocks = []
        executor.executeBlocks(from: 0.25, .exclusive, to: 0.5)
        XCTAssertEqual(executedBlocks, ["B"])

        // Test that the execution blocks are executed in the correct order.
        executedBlocks = []
        executor.executeBlocks(from: 0, .inclusive, to: 1)
        XCTAssertEqual(executedBlocks, ["A", "B", "C"])

        // Test that excluding the starting timestamp doesn't include a block at that timestamp.
        executedBlocks = []
        executor.executeBlocks(from: 0, .exclusive, to: 1)
        XCTAssertEqual(executedBlocks, ["B", "C"])

        // Test that the ending timestamp is inclusive when running in reverse.
        executedBlocks = []
        executor.executeBlocks(from: 1, .exclusive, to: 0.75)
        XCTAssertEqual(executedBlocks, ["C'"])

        // Test that the starting timestamp is inclusive when specified as such.
        executedBlocks = []
        executor.executeBlocks(from: 0.75, .inclusive, to: 0.5)
        XCTAssertEqual(executedBlocks, ["C'", "B'"])

        // Test that the starting timestamp is exclusive when specified as such.
        executedBlocks = []
        executor.executeBlocks(from: 0.75, .exclusive, to: 0.5)
        XCTAssertEqual(executedBlocks, ["B'"])

        // Test that the blocks are ordered correctly when running in reverse.
        executedBlocks = []
        executor.executeBlocks(from: 1, .inclusive, to: 0)
        XCTAssertEqual(executedBlocks, ["C'", "B'", "A'"])
    }

    func testExecutionBlocksInChildAnimation() {
        var executedBlocks: [String] = []

        var childAnimation = Animation<Element>()
        childAnimation.addExecution(
            onForward: { _ in executedBlocks.append("A") },
            onReverse: { _ in executedBlocks.append("A'") },
            at: 0
        )
        childAnimation.addExecution(
            onForward: { _ in executedBlocks.append("C") },
            onReverse: { _ in executedBlocks.append("C'") },
            at: 0.75
        )
        childAnimation.addExecution(
            onForward: { _ in executedBlocks.append("B") },
            onReverse: { _ in executedBlocks.append("B'") },
            at: 0.5
        )

        var parentAnimation = Animation<Element>()
        parentAnimation.addChild(childAnimation, for: \.self, startingAt: 0.3, relativeDuration: 0.6)

        let element = Element()
        let executor = Executor(animation: parentAnimation, element: element)

        // Test that blocks aren't executed before the child animation begins.
        executor.executeBlocks(from: 0, .inclusive, to: 0.29)
        XCTAssertEqual(executedBlocks, [])

        executedBlocks = []
        executor.executeBlocks(from: 0.29, .exclusive, to: 0.31)
        XCTAssertEqual(executedBlocks, ["A"])

        executedBlocks = []
        executor.executeBlocks(from: 0.31, .exclusive, to: 0.59)
        XCTAssertEqual(executedBlocks, [])

        executedBlocks = []
        executor.executeBlocks(from: 0.59, .inclusive, to: 0.61)
        XCTAssertEqual(executedBlocks, ["B"])

        executedBlocks = []
        executor.executeBlocks(from: 0.61, .inclusive, to: 0.74)
        XCTAssertEqual(executedBlocks, [])

        executedBlocks = []
        executor.executeBlocks(from: 0.74, .inclusive, to: 0.76)
        XCTAssertEqual(executedBlocks, ["C"])

        // Test that blocks are executed in the correct order when going forward.
        executedBlocks = []
        executor.executeBlocks(from: 0, .inclusive, to: 1)
        XCTAssertEqual(executedBlocks, ["A", "B", "C"])

        // Test that blocks are executed in the correct order when going in reverse.
        executedBlocks = []
        executor.executeBlocks(from: 1, .inclusive, to: 0)
        XCTAssertEqual(executedBlocks, ["C'", "B'", "A'"])
    }

    func testExecutionBlocksWithCurvedAnimation() {
        var executedBlocks: [String] = []

        var animation = Animation<Element>()
        animation.addExecution(
            onForward: { _ in executedBlocks.append("B") },
            onReverse: { _ in executedBlocks.append("B'") },
            at: 0.5
        )

        // Apply a parabolic easing curve. We can calculate the uncurved timestamp at which the assignment should occur
        // by taking the square root of the curved timestamp.
        animation.curve = ParabolicEaseInAnimationCurve()

        let element = Element()
        let executor = Executor(animation: animation, element: element)

        executor.executeBlocks(from: 0, .inclusive, to: 0.7)
        XCTAssertEqual(executedBlocks, [])

        executedBlocks = []
        executor.executeBlocks(from: 0.7, .exclusive, to: 0.71)
        XCTAssertEqual(executedBlocks, ["B"])

        executedBlocks = []
        executor.executeBlocks(from: 0.71, .exclusive, to: 1)
        XCTAssertEqual(executedBlocks, [])

        executedBlocks = []
        executor.executeBlocks(from: 1, .exclusive, to: 0.71)
        XCTAssertEqual(executedBlocks, [])

        executedBlocks = []
        executor.executeBlocks(from: 0.71, .inclusive, to: 0.7)
        XCTAssertEqual(executedBlocks, ["B'"])

        executedBlocks = []
        executor.executeBlocks(from: 0.7, .exclusive, to: 0)
        XCTAssertEqual(executedBlocks, [])
    }

    func testExecutionBlocksInCurvedChildAnimation() {
        var executedBlocks: [String] = []

        var childAnimation = Animation<Element>()
        childAnimation.addExecution(
            onForward: { _ in executedBlocks.append("B") },
            onReverse: { _ in executedBlocks.append("B'") },
            at: 0.5
        )

        // Apply a parabolic easing curve. We can calculate the uncurved timestamp at which the assignment should occur
        // by taking the square root of the curved timestamp.
        childAnimation.curve = ParabolicEaseInAnimationCurve()

        var parentAnimation = Animation<Element>()
        parentAnimation.addChild(childAnimation, for: \.self, startingAt: 0.3, relativeDuration: 0.6)

        let element = Element()
        let executor = Executor(animation: parentAnimation, element: element)

        executor.executeBlocks(from: 0, .inclusive, to: 0.72)
        XCTAssertEqual(executedBlocks, [])

        executedBlocks = []
        executor.executeBlocks(from: 0.72, .exclusive, to: 0.73)
        XCTAssertEqual(executedBlocks, ["B"])

        executedBlocks = []
        executor.executeBlocks(from: 0.73, .exclusive, to: 1)
        XCTAssertEqual(executedBlocks, [])

        executedBlocks = []
        executor.executeBlocks(from: 1, .exclusive, to: 0.73)
        XCTAssertEqual(executedBlocks, [])

        executedBlocks = []
        executor.executeBlocks(from: 0.73, .inclusive, to: 0.72)
        XCTAssertEqual(executedBlocks, ["B'"])

        executedBlocks = []
        executor.executeBlocks(from: 0.72, .exclusive, to: 0)
        XCTAssertEqual(executedBlocks, [])
    }

}

// MARK: -

extension ExecutorTests {

    private final class Element {

        // MARK: - Life Cycle

        init(
            property: String = ""
        ) {
            self.property = property
        }

        // MARK: - Public Properties

        var property: String

    }

}
