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

extension Animation {

    // MARK: - Internal Methods

    func optimized() -> Animation<ElementType> {
        var animation = self

        animation.children = animation.children.map { child in
            var child = child
            child.animation = child.animation.optimized()
            return child
        }

        animation.elevateUbiquitousBezierCurve()

        animation.removeObsoleteKeyframes()

        // Now that we've potentially removed keyframes from our children, we can simplify the animation by removing any
        // empty children.
        animation.removeEmptyChildren()

        return animation
    }

    // MARK: - Private Methods

    /// Optimizes for the case where an animation is used as container for a set of child animations that all have the
    /// same cubic Bézier curve. Bézier curves are relatively expensive to calculate, so avoiding calculating values for
    /// the same curve many times each frame can help save a fair amount of computation.
    private mutating func elevateUbiquitousBezierCurve() {
        // In order to elevate a curve from children, the parent animation needs to strictly be a container - i.e. an
        // animation that doesn't define any content (keyframes, execution blocks, etc.) itself, only acts as a
        // container for child animations.
        guard
            keyframeSeriesByProperty.isEmpty
            && collectionKeyframeSeriesByProperty.isEmpty
            && assignments.isEmpty
            && executionBlocks.isEmpty
            && perFrameExecutionBlocks.isEmpty
            && !children.isEmpty
        else {
            return
        }

        // The curve can only be elevated to replace the parent curve if the parent curve is linear. In the future, this
        // requirement could be removed by creating a wrapper animation curve that stacks the two curves.
        guard curve is LinearAnimationCurve else {
            return
        }

        // The curve can only be elevated if all children are animated over the entire parent animation. In the future,
        // this requirement could be relaxed to check that all children are animated over the same interval, even if it
        // is not 0 to 1, by creating a wrapper animation curve that applies the wrapped curve over that interval and
        // otherwise returns an out of bounds (i.e. < 0 or > 1) adjusted progress outside that interval.
        guard children.allSatisfy({ $0.relativeStartTimestamp == 0 && $0.relativeDuration == 1 }) else {
            return
        }

        // The curve can only be elevated if all children use the same cubic Bézier animation curve.
        guard
            let curve = children.first?.animation.curve as? CubicBezierAnimationCurve,
            children.allSatisfy({ ($0.animation.curve as? CubicBezierAnimationCurve) == curve })
        else {
            return
        }

        // Elevate the curve by replacing the (linear) curve of the parent with the Bézier curve, and the curve of each
        // child with a linear curve.
        self.curve = curve
        self.children = children.map { child in
            var child = child
            child.animation.curve = LinearAnimationCurve()
            return child
        }
    }

    /// Removes keyframes in children that would be overridden by their parent. Since keyframes in parents override any
    /// keyframes for the same property in their children, those keyframes are obsolete.
    private mutating func removeObsoleteKeyframes() {
        // If we don't have any children, there's nothing to do.
        guard !children.isEmpty else {
            return
        }

        let propertiesInParent = Set(keyframeSeriesByProperty.keys)

        for (index, child) in children.enumerated() {
            let obsoleteProperties = child.animation.propertiesWithKeyframes.intersection(propertiesInParent)

            for property in obsoleteProperties {
                children[index].animation.removeKeyframes(for: property)
            }
        }
    }

    private mutating func removeKeyframes(for property: PartialKeyPath<ElementType>) {
        keyframeSeriesByProperty.removeValue(forKey: property)

        children = children.map { child in
            var child = child
            child.animation.removeKeyframes(for: property)
            return child
        }
    }

    private mutating func removeEmptyChildren() {
        self.children = children.filter { child in
            return !child.animation.keyframeSeriesByProperty.isEmpty
                || !child.animation.collectionKeyframeSeriesByProperty.isEmpty
                || !child.animation.assignments.isEmpty
                || !child.animation.executionBlocks.isEmpty
                || !child.animation.perFrameExecutionBlocks.isEmpty
                || !child.animation.children.isEmpty
        }
    }

}
