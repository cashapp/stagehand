//
//  Copyright 2023 Block Inc.
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
import UIKit

final class TextMorphAnimationViewController: DemoViewController {

    // MARK: - Life Cycle

    override init() {
        super.init()

        contentView = mainView

        animationRows = [
            ("System Font", { [unowned self] in
//                let animation = AnimationFactory.makeFadeOutAnimation()
//                animation.perform(on: self.mainView.animatableView)
                self.mainView.label.font = .systemFont(ofSize: 48)
                self.mainView.setNeedsLayout()
            }),
            ("Palatino", { [unowned self] in
                let animation = makeAnimation(from: mainView.label.font, to: UIFont(name: "Palatino", size: 48)!, text: mainView.label.text!)!
                animation.perform(on: self.mainView)
//                self.mainView.label.font = .init(name: "Palatino", size: 48)
//                self.mainView.setNeedsLayout()
            }),
        ]
    }

    // MARK: - Private Properties

    private let mainView: View = .init()

    // MARK: - Private Methods

    private func makeAnimation(from fromFont: UIFont, to toFont: UIFont, text: String) -> Animation<View>? {
        var animation = Animation<View>()

        animation.addAssignment(for: \.label.isHidden, at: 0, value: true)
        animation.addAssignment(for: \.label.isHidden, at: 1, value: false)

        animation.addExecution(onForward: { view in
            view.label.font = toFont
            view.setNeedsLayout()
        }, at: 0)

        animation.addAssignment(for: \.shapeLayer.isHidden, at: 0, value: false)
        animation.addAssignment(for: \.shapeLayer.isHidden, at: 1, value: true)

        var characters = Array<UniChar>(text.utf16)
        var fromGlyphs = Array<CGGlyph>(repeating: 0, count: characters.count)
        var toGlyphs = Array<CGGlyph>(repeating: 0, count: characters.count)

        guard
            CTFontGetGlyphsForCharacters(fromFont, &characters, &fromGlyphs, characters.count),
            CTFontGetGlyphsForCharacters(toFont, &characters, &toGlyphs, characters.count)
        else {
            return nil
        }

//        func pathForGlyphs(_ glyphs: [CGGlyph], in font: UIFont) -> CGPath? {
//
//        }

        var flipTransform = CGAffineTransform(scaleX: 1, y: -1)

        var fromPath = CGMutablePath()
        for glyph in fromGlyphs {
            fromPath.addPath(CTFontCreatePathForGlyph(fromFont, glyph, &flipTransform)!)
        }
        var fromTranslation = CGAffineTransform(translationX: 0, y: fromPath.boundingBox.height)
        fromPath = fromPath.mutableCopy(using: &fromTranslation)!

        var toPath = CGMutablePath()
        for glyph in toGlyphs {
            toPath.addPath(CTFontCreatePathForGlyph(toFont, glyph,  &flipTransform)!)
        }
        var toTranslation = CGAffineTransform(translationX: 0, y: toPath.boundingBox.height)
        toPath = toPath.mutableCopy(using: &toTranslation)!

        var pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.fromValue = fromPath
        pathAnimation.toValue = toPath
        pathAnimation.duration = 2

        animation.addExecution(onForward: { view in
            view.shapeLayer.add(pathAnimation, forKey: "path-anim")
        }, at: 0)

        animation.addExecution(onForward: { view in
            view.shapeLayer.removeAnimation(forKey: "path-anim")
        }, at: 1)

        animation.implicitDuration = 2
        return animation
    }

}

// TODO: Make the addAssociatedObject<Object>(factory: () -> Object) -> KeyPath<Animation, Object>

// MARK: -

extension TextMorphAnimationViewController {

    final class View: UIView {

        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            label.text = "SA"
            label.font = .systemFont(ofSize: 48)
            label.textColor = .black
            addSubview(label)

            shapeLayer.isHidden = true
            shapeLayer.strokeColor = nil
            shapeLayer.fillColor = UIColor.black.cgColor
            layer.addSublayer(shapeLayer)

            backgroundColor = .white
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Public Properties

        let label: UILabel = .init()

        let shapeLayer: CAShapeLayer = .init()

        // MARK: - UIView

        override func layoutSubviews() {
            label.sizeToFit()
            label.center = .init(
                x: (bounds.maxX - bounds.minX) / 2,
                y: (bounds.maxY - bounds.minY) / 2
            )

            shapeLayer.frame = label.frame
        }

    }

}
