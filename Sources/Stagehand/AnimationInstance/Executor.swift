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

import Foundation

internal final class Executor {

    // MARK: - Life Cycle

    internal init<ElementType: AnyObject>(
        animation: Animation<ElementType>,
        element: ElementType
    ) {
        self.rootExecutionGroup = Executor.makeExecutionGroup(animation: animation, element: element)
            ?? ExecutionGroup(sortedExecutionBlocks: [], curve: LinearAnimationCurve(), children: [])
    }

    // MARK: - Private Properties

    private var rootExecutionGroup: ExecutionGroup

    // MARK: - Internal Methods

    internal func executeBlocks(
        from startingRelativeTimestamp: Double,
        _ fromInclusivity: Inclusivity,
        to endingRelativeTimestamp: Double
    ) {
        executeBlocks(
            in: &rootExecutionGroup,
            from: startingRelativeTimestamp,
            fromInclusivity: fromInclusivity,
            to: endingRelativeTimestamp
        )
    }

    // MARK: - Private Methods

    private func executeBlocks(
        in group: inout ExecutionGroup,
        from uncurvedStartingRelativeTimestamp: Double,
        fromInclusivity uncurvedFromInclusivity: Inclusivity,
        to uncurvedEndingRelativeTimestamp: Double
    ) {
        // Apply the animation curve to the start/end timestamps.
        let startingRelativeTimestamp = group.curve.adjustedProgress(
            for: uncurvedStartingRelativeTimestamp.clamped(in: 0...1)
        )
        let fromInclusivity = ((0...1).contains(uncurvedStartingRelativeTimestamp) ? uncurvedFromInclusivity : .inclusive)
        let endingRelativeTimestamp = group.curve.adjustedProgress(
            for: uncurvedEndingRelativeTimestamp.clamped(in: 0...1)
        )

        if endingRelativeTimestamp >= startingRelativeTimestamp {
            // Iterate forward through the execution blocks.
            for (index, executionBlock) in group.sortedExecutionBlocks.enumerated() {
                let relativeTimestamp = executionBlock.relativeTimestamp
                if fromInclusivity.forwardFromCompare(relativeTimestamp, startingRelativeTimestamp) && relativeTimestamp <= endingRelativeTimestamp {
                    // Perform the forward invocation of the execution block. When executing a property assignment, the
                    // forward block will set the reverse block, so update the stored execution block.
                    var executionBlock = executionBlock
                    executionBlock.forwardBlock(&executionBlock)
                    group.sortedExecutionBlocks[index] = executionBlock
                }
            }

        } else {
            // Iterate in reverse through the execution blocks.
            for executionBlock in group.sortedExecutionBlocks.reversed() {
                let relativeTimestamp = executionBlock.relativeTimestamp
                if fromInclusivity.reverseFromCompare(relativeTimestamp, startingRelativeTimestamp) && relativeTimestamp >= endingRelativeTimestamp {
                    executionBlock.reverseBlock()
                }
            }
        }

        let executionRange = ClosedRange(unorderedBounds: (startingRelativeTimestamp, endingRelativeTimestamp))

        for childIndex in group.children.indices {
            let child = group.children[childIndex]

            let childRange = (child.startingRelativeTimestamp)...(child.endingRelativeTimestamp)
            guard executionRange.overlaps(childRange) else {
                continue
            }

            // Find the start and end points relative to the child's timeline by reinterpolating over time in which the
            // child animation should take place.
            let startingTimestampInChild = (startingRelativeTimestamp - child.startingRelativeTimestamp) / child.relativeDuration
            let endingTimestampInChild = (endingRelativeTimestamp - child.startingRelativeTimestamp) / child.relativeDuration

            executeBlocks(
                in: &group.children[childIndex].group,
                from: startingTimestampInChild,
                fromInclusivity: fromInclusivity,
                to: endingTimestampInChild
            )
        }
    }

    // MARK: - Private Static Methods

    private static func makeExecutionGroup<ElementType: AnyObject>(
        animation: Animation<ElementType>,
        element: ElementType
    ) -> ExecutionGroup? {
        let executionBlocks: [ExecutionBlock] = animation.executionBlocks
            .map { executionBlock in
                return ExecutionBlock(
                    relativeTimestamp: executionBlock.relativeTimestamp,
                    forwardBlock: { [weak element] _ in
                        guard let element = element else {
                            return
                        }

                        executionBlock.forwardBlock(element)
                    },
                    reverseBlock: { [weak element] in
                        guard let element = element else {
                            return
                        }

                        executionBlock.reverseBlock(element)
                    }
                )
            }

        let assignmentBlocks: [ExecutionBlock] = animation.assignments
            .map { assignment in
                return ExecutionBlock(
                    relativeTimestamp: assignment.relativeTimestamp,
                    forwardBlock: { [weak element] executionBlock in
                        guard let element = element else {
                            return
                        }

                        let reverseAssignment = assignment.generateReverseAssignBlock(element)
                        executionBlock.reverseBlock = { [weak element] in
                            guard let element = element else {
                                return
                            }

                            reverseAssignment(element)
                        }

                        assignment.assignBlock(element)
                    },
                    reverseBlock: {
                        // No-op. This block will be replaced when the `forwardBlock` is invoked.
                    }
                )
            }

        let sortedExecutionBlocks = (executionBlocks + assignmentBlocks)
            .sorted { $0.relativeTimestamp < $1.relativeTimestamp }

        let children: [ChildGroup] = animation.children.compactMap { child in
            guard let childGroup = makeExecutionGroup(animation: child.animation, element: element) else {
                return nil
            }

            return .init(
                group: childGroup,
                startingRelativeTimestamp: child.relativeStartTimestamp,
                relativeDuration: child.relativeDuration
            )
        }

        guard !sortedExecutionBlocks.isEmpty || !children.isEmpty else {
            return nil
        }

        return ExecutionGroup(
            sortedExecutionBlocks: sortedExecutionBlocks,
            curve: animation.curve,
            children: children
        )
    }

}

// MARK: -

extension Executor {

    internal enum Inclusivity {

        case inclusive
        case exclusive

        // MARK: - Private Computed Properties

        fileprivate var forwardFromCompare: (Double, Double) -> Bool {
            switch self {
            case .inclusive:
                return (>=)
            case .exclusive:
                return (>)
            }
        }

        fileprivate var reverseFromCompare: (Double, Double) -> Bool {
            switch self {
            case .inclusive:
                return (<=)
            case .exclusive:
                return (<)
            }
        }

    }

}

// MARK: -

extension Executor {

    private struct ExecutionGroup {

        var sortedExecutionBlocks: [ExecutionBlock]

        var curve: AnimationCurve

        var children: [ChildGroup]

    }

    private struct ChildGroup {

        var group: ExecutionGroup

        /// The timestamp at which the child animation begins, relative to the parent animation's timeline.
        var startingRelativeTimestamp: Double

        /// The duration over which the child animation occurs, relative to the parent animation's timeline.
        var relativeDuration: Double

        /// The timestamp at which the child animation ends, relative to the parent animation's timeline.
        var endingRelativeTimestamp: Double {
            return startingRelativeTimestamp + relativeDuration
        }

    }

    private struct ExecutionBlock {

        /// The timestamp at which the block should be executed, relative to the animation's timeline.
        var relativeTimestamp: Double

        var forwardBlock: (inout ExecutionBlock) -> Void

        var reverseBlock: () -> Void

    }

}
