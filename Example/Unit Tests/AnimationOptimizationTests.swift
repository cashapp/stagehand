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

@MainActor
final class AnimationOptimizationTests: XCTestCase {

    // MARK: - Tests - Ubiquitous Bezier Curve

    func testUbiquitousBezierCurveElevation_singleChild() {
        var parentAnimation = Animation<UIView>()

        var childAnimation = Animation<UIView>()
        childAnimation.addKeyframe(for: \.alpha, at: 0, value: 0)
        childAnimation.curve = CubicBezierAnimationCurve.easeInEaseOut
        parentAnimation.addChild(childAnimation, for: \.self, startingAt: 0, relativeDuration: 1)

        let optimizedAnimation = parentAnimation.optimized()

        XCTAssertEqual(optimizedAnimation.curve as? CubicBezierAnimationCurve, CubicBezierAnimationCurve.easeInEaseOut)
        XCTAssert(optimizedAnimation.children.allSatisfy { $0.animation.curve is LinearAnimationCurve })
    }

    func testUbiquitousBezierCurveElevation_multipleChildren() {
        var parentAnimation = Animation<UIView>()

        var firstChildAnimation = Animation<UIView>()
        firstChildAnimation.addKeyframe(for: \.alpha, at: 0, value: 0)
        firstChildAnimation.curve = CubicBezierAnimationCurve.easeInEaseOut
        parentAnimation.addChild(firstChildAnimation, for: \.self, startingAt: 0, relativeDuration: 1)

        var secondChildAnimation = Animation<UIView>()
        secondChildAnimation.addKeyframe(for: \.alpha, at: 0, value: 0)
        secondChildAnimation.curve = CubicBezierAnimationCurve.easeInEaseOut
        parentAnimation.addChild(secondChildAnimation, for: \.self, startingAt: 0, relativeDuration: 1)

        let optimizedAnimation = parentAnimation.optimized()

        XCTAssertEqual(optimizedAnimation.curve as? CubicBezierAnimationCurve, CubicBezierAnimationCurve.easeInEaseOut)
        XCTAssert(optimizedAnimation.children.allSatisfy { $0.animation.curve is LinearAnimationCurve })
    }

    func testUbiquitousBezierCurveElevation_grandchild() {
        var parentAnimation = Animation<UIView>()

        var grandchildAnimation = Animation<UIView>()
        grandchildAnimation.addKeyframe(for: \.alpha, at: 0, value: 0)
        grandchildAnimation.curve = CubicBezierAnimationCurve.easeInEaseOut

        var childAnimation = Animation<UIView>()
        childAnimation.addChild(grandchildAnimation, for: \.self, startingAt: 0, relativeDuration: 1)
        parentAnimation.addChild(childAnimation, for: \.self, startingAt: 0, relativeDuration: 1)

        let optimizedAnimation = parentAnimation.optimized()

        XCTAssertEqual(optimizedAnimation.curve as? CubicBezierAnimationCurve, CubicBezierAnimationCurve.easeInEaseOut)
        XCTAssert(optimizedAnimation.children.allSatisfy {
            $0.animation.curve is LinearAnimationCurve
            && $0.animation.children.allSatisfy { $0.animation.curve is LinearAnimationCurve }
        })
    }

    func testUbiquitousBezierCurveElevation_notElevatedWhenParentHasContent() {
        var parentAnimation = Animation<UIView>()
        parentAnimation.addKeyframe(for: \.alpha, at: 0, value: 1)

        var childAnimation = Animation<UIView>()
        childAnimation.addKeyframe(for: \.alpha, at: 0, value: 0)
        childAnimation.curve = CubicBezierAnimationCurve.easeInEaseOut
        parentAnimation.addChild(childAnimation, for: \.self, startingAt: 0, relativeDuration: 1)

        let optimizedAnimation = parentAnimation.optimized()

        XCTAssert(optimizedAnimation.curve is LinearAnimationCurve)
        XCTAssert(optimizedAnimation.children.allSatisfy {
            $0.animation.curve as? CubicBezierAnimationCurve == CubicBezierAnimationCurve.easeInEaseOut
        })
    }

    func testUbiquitousBezierCurveElevation_notElevatedWhenParentCurveIsNotLinear() {
        var parentAnimation = Animation<UIView>()
        parentAnimation.curve = ParabolicEaseInAnimationCurve()

        var childAnimation = Animation<UIView>()
        childAnimation.addKeyframe(for: \.alpha, at: 0, value: 0)
        childAnimation.curve = CubicBezierAnimationCurve.easeInEaseOut
        parentAnimation.addChild(childAnimation, for: \.self, startingAt: 0, relativeDuration: 1)

        let optimizedAnimation = parentAnimation.optimized()

        XCTAssert(optimizedAnimation.curve is ParabolicEaseInAnimationCurve)
        XCTAssert(optimizedAnimation.children.allSatisfy {
            $0.animation.curve as? CubicBezierAnimationCurve == CubicBezierAnimationCurve.easeInEaseOut
        })
    }

    func testUbiquitousBezierCurveElevation_notElevatedWhenAChildDoesNotCoverFullInterval() {
        var parentAnimation = Animation<UIView>()

        var firstChildAnimation = Animation<UIView>()
        firstChildAnimation.addKeyframe(for: \.alpha, at: 0, value: 0)
        firstChildAnimation.curve = CubicBezierAnimationCurve.easeInEaseOut
        parentAnimation.addChild(firstChildAnimation, for: \.self, startingAt: 0, relativeDuration: 1)

        var secondChildAnimation = Animation<UIView>()
        secondChildAnimation.addKeyframe(for: \.alpha, at: 0, value: 0)
        secondChildAnimation.curve = CubicBezierAnimationCurve.easeInEaseOut
        parentAnimation.addChild(secondChildAnimation, for: \.self, startingAt: 0.5, relativeDuration: 0.5)

        let optimizedAnimation = parentAnimation.optimized()

        XCTAssert(optimizedAnimation.curve is LinearAnimationCurve)
        XCTAssert(optimizedAnimation.children.allSatisfy {
            $0.animation.curve as? CubicBezierAnimationCurve == CubicBezierAnimationCurve.easeInEaseOut
        })
    }

    func testUbiquitousBezierCurveElevation_notElevatedWhenNotAllChildrenHaveSameCurve() {
        var parentAnimation = Animation<UIView>()

        var firstChildAnimation = Animation<UIView>()
        firstChildAnimation.addKeyframe(for: \.alpha, at: 0, value: 0)
        firstChildAnimation.curve = CubicBezierAnimationCurve.easeIn
        parentAnimation.addChild(firstChildAnimation, for: \.self, startingAt: 0, relativeDuration: 1)

        var secondChildAnimation = Animation<UIView>()
        secondChildAnimation.addKeyframe(for: \.alpha, at: 0, value: 0)
        secondChildAnimation.curve = CubicBezierAnimationCurve.easeOut
        parentAnimation.addChild(secondChildAnimation, for: \.self, startingAt: 0, relativeDuration: 1)

        let optimizedAnimation = parentAnimation.optimized()

        XCTAssert(optimizedAnimation.curve is LinearAnimationCurve)
        XCTAssert(optimizedAnimation.children[0].animation.curve as? CubicBezierAnimationCurve == .easeIn)
        XCTAssert(optimizedAnimation.children[1].animation.curve as? CubicBezierAnimationCurve == .easeOut)
    }

    // MARK: - Tests - Remove Obsolete Keyframes

    func testObsoleteKeyframeRemoval_selfProperty() {
        var parentAnimation = Animation<UIView>()
        parentAnimation.addKeyframe(for: \.alpha, at: 0, value: 1)

        var childAnimation = Animation<UIView>()
        childAnimation.addKeyframe(for: \.alpha, at: 0.5, value: 0.5)
        childAnimation.addKeyframe(for: \.transform, at: 0, value: .identity)
        parentAnimation.addChild(childAnimation, for: \.self, startingAt: 0, relativeDuration: 1)

        let optimizedAnimation = parentAnimation.optimized()

        XCTAssertEqual(Array(optimizedAnimation.keyframeSeriesByProperty.keys), [\UIView.alpha])
        XCTAssertEqual(Array(optimizedAnimation.children[0].animation.keyframeSeriesByProperty.keys), [\UIView.transform])
    }

    func testObsoleteKeyframeRemoval_subelementProperty() {
        var parentAnimation = Animation<Element>()
        parentAnimation.addKeyframe(for: \.subelement.propertyOne, at: 0, value: 1)

        var childAnimation = Animation<Subelement>()
        childAnimation.addKeyframe(for: \.propertyOne, at: 0.5, value: 0.5)
        childAnimation.addKeyframe(for: \.propertyTwo, at: 0.5, value: 0.5)
        parentAnimation.addChild(childAnimation, for: \.subelement, startingAt: 0, relativeDuration: 1)

        let optimizedAnimation = parentAnimation.optimized()

        XCTAssertEqual(Array(optimizedAnimation.keyframeSeriesByProperty.keys), [\Element.subelement.propertyOne])
        XCTAssertEqual(Array(optimizedAnimation.children[0].animation.keyframeSeriesByProperty.keys), [\Element.subelement.propertyTwo])
    }

    func testObsoleteKeyframeRemoval_removesEmptyChildAfterRemovingKeyframes() {
        var parentAnimation = Animation<Element>()
        parentAnimation.addKeyframe(for: \.subelement.propertyOne, at: 0, value: 1)

        var childAnimation = Animation<Subelement>()
        childAnimation.addKeyframe(for: \.propertyOne, at: 0.5, value: 0.5)
        parentAnimation.addChild(childAnimation, for: \.subelement, startingAt: 0, relativeDuration: 1)

        let optimizedAnimation = parentAnimation.optimized()

        XCTAssertEqual(Array(optimizedAnimation.keyframeSeriesByProperty.keys), [\Element.subelement.propertyOne])
        XCTAssert(optimizedAnimation.children.isEmpty)
    }

}

// MARK: -

private extension AnimationOptimizationTests {

    final class Element {

        init() { }

        var subelement: Subelement = .init()

    }

    final class Subelement {

        init() { }

        var propertyOne: Double = 0

        var propertyTwo: Double = 0

    }

}
