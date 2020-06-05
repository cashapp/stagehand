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

import Stagehand

enum AnimationFactory {

    static func makeFadeOutAnimation() -> Animation<UIView> {
        var fadeOutAnimation = Animation<UIView>()
        fadeOutAnimation.addKeyframe(for: \.alpha, at: 0, value: 1)
        fadeOutAnimation.addKeyframe(for: \.alpha, at: 1, value: 0)
        fadeOutAnimation.addKeyframe(for: \.transform, at: 0, value: .identity)
        fadeOutAnimation.addKeyframe(for: \.transform, at: 1, value: .init(scaleX: 1.1, y: 1.1))
        return fadeOutAnimation
    }

    static func makeFadeInAnimation() -> Animation<UIView> {
        var fadeInAnimation = Animation<UIView>()
        fadeInAnimation.addKeyframe(for: \.alpha, at: 0, value: 0)
        fadeInAnimation.addKeyframe(for: \.alpha, at: 1, value: 1)
        fadeInAnimation.addKeyframe(for: \.transform, at: 0, value: .init(scaleX: 1.1, y: 1.1))
        fadeInAnimation.addKeyframe(for: \.transform, at: 1, value: .identity)
        return fadeInAnimation
    }

    static func makeResetTransformAnimation() -> Animation<UIView> {
        var resetAnimation = Animation<UIView>()
        resetAnimation.addKeyframe(for: \.transform, at: 0, relativeValue: { $0 })
        resetAnimation.addKeyframe(for: \.transform, at: 1, value: .identity)
        return resetAnimation
    }

    static func makeRotateAnimation() -> Animation<UIView> {
        var rotateAnimation = Animation<UIView>()
        rotateAnimation.addKeyframe(for: \.transform, at: 0, relativeValue: { $0 })
        rotateAnimation.addKeyframe(for: \.transform, at: 1, relativeValue: { $0.rotated(by: .pi / 4) })
        return rotateAnimation
    }

    static func makePopAnimation() -> Animation<UIView> {
        var popAnimation = Animation<UIView>()
        popAnimation.addKeyframe(for: \.transform, at: 0, relativeValue: { $0 })
        popAnimation.addKeyframe(for: \.transform, at: 0.1, relativeValue: { $0.scaledBy(x: 0.9, y: 0.9) })
        popAnimation.addKeyframe(for: \.transform, at: 0.5, relativeValue: { $0.scaledBy(x: 1.5, y: 1.5) })
        popAnimation.addKeyframe(for: \.transform, at: 0.9, relativeValue: { $0.scaledBy(x: 0.9, y: 0.9) })
        popAnimation.addKeyframe(for: \.transform, at: 1, relativeValue: { $0 })
        return popAnimation
    }

    static func makeSkewAnimation() -> Animation<UIView> {
        var popAnimation = Animation<UIView>()
        popAnimation.addKeyframe(for: \.transform, at: 0, relativeValue: { $0 })
        popAnimation.addKeyframe(
            for: \.transform,
            at: 1,
            relativeValue: { transform in
                let skewTransform = CGAffineTransform(
                    a: 1,
                    b: 0,
                    c: 0.2,
                    d: 1,
                    tx: 0,
                    ty: 0
                )
                return transform.concatenating(skewTransform)
            }
        )
        return popAnimation
    }

    static func makeGhostAnimation() -> Animation<UIView> {
        var ghostAnimation = Animation<UIView>()
        ghostAnimation.addKeyframe(for: \.alpha, at: 0, relativeValue: { $0 })
        ghostAnimation.addKeyframe(for: \.alpha, at: 0.25, value: 0)
        ghostAnimation.addKeyframe(for: \.alpha, at: 0.5, relativeValue: { $0 })
        ghostAnimation.addKeyframe(for: \.alpha, at: 0.75, value: 0)
        ghostAnimation.addKeyframe(for: \.alpha, at: 0, relativeValue: { $0 })
        return ghostAnimation
    }

}
