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
import UIKit

final class ColorAnimationsViewController: DemoViewController {

    // MARK: - Life Cycle

    override init() {
        super.init()

        contentView = .init()
        contentView.backgroundColor = .red

        animationRows = [
            ("Reset to Red (sRGB)", { [unowned self] in
                self.animationInstance?.cancel()
                self.contentView.backgroundColor = .red
            }),
            ("Reset to Red (P3)", { [unowned self] in
                self.animationInstance?.cancel()
                self.contentView.backgroundColor = UIColor(displayP3Red: 1, green: 0, blue: 0, alpha: 1)
            }),
            ("Red (sRGB) -> Green (sRGB)", { [unowned self] in
                self.animationInstance?.cancel()

                var animation = Animation<UIView>()

                animation.addKeyframe(for: \.backgroundColor, at: 0, value: .red)
                animation.addKeyframe(for: \.backgroundColor, at: 1, value: .green)

                self.animationInstance = animation.perform(on: self.contentView, duration: 2)
            }),
            ("Red (sRGB) -> nil -> Green (sRGB)", { [unowned self] in
                self.animationInstance?.cancel()

                var animation = Animation<UIView>()

                animation.addKeyframe(for: \.backgroundColor, at: 0, value: .red)
                animation.addKeyframe(for: \.backgroundColor, at: 0.5, value: nil)
                animation.addKeyframe(for: \.backgroundColor, at: 1, value: .green)

                self.animationInstance = animation.perform(on: self.contentView, duration: 2)
            }),
            ("Red (P3) -> Green (P3)", { [unowned self] in
                self.animationInstance?.cancel()

                var animation = Animation<UIView>()

                animation.addKeyframe(for: \UIView.backgroundColor, at: 0, value: UIColor(displayP3Red: 1, green: 0, blue: 0, alpha: 1))
                animation.addKeyframe(for: \UIView.backgroundColor, at: 1, value: UIColor(displayP3Red: 0, green: 1, blue: 0, alpha: 1))

                self.animationInstance = animation.perform(on: self.contentView, duration: 2)
            }),
            ("Red (sRGB) -> Green (P3)", { [unowned self] in
                self.animationInstance?.cancel()

                var animation = Animation<UIView>()

                animation.addKeyframe(for: \UIView.backgroundColor, at: 0, value: .red)
                animation.addKeyframe(for: \UIView.backgroundColor, at: 1, value: UIColor(displayP3Red: 0, green: 1, blue: 0, alpha: 1))

                self.animationInstance = animation.perform(on: self.contentView, duration: 2)
            }),
            ("Red (sRGB) -> Red (P3)", { [unowned self] in
                self.animationInstance?.cancel()

                var animation = Animation<UIView>()

                animation.addKeyframe(for: \UIView.backgroundColor, at: 0, value: .red)
                animation.addKeyframe(for: \UIView.backgroundColor, at: 1, value: UIColor(displayP3Red: 1, green: 0, blue: 0, alpha: 1))

                self.animationInstance = animation.perform(on: self.contentView, duration: 2)
            }),
            ("Red (sRGB), with alpha 1 -> 0.5 -> 1", { [unowned self] in
                self.animationInstance?.cancel()

                var animation = Animation<UIView>()

                animation.addKeyframe(for: \UIView.backgroundColor, at: 0.0, value: UIColor.red)
                animation.addKeyframe(for: \UIView.backgroundColor, at: 0.5, value: UIColor.red.withAlphaComponent(0.5))
                animation.addKeyframe(for: \UIView.backgroundColor, at: 1.0, value: UIColor.red)

                self.animationInstance = animation.perform(on: self.contentView, duration: 2)
            }),
        ]
    }

    // MARK: - Private Properties

    private var animationInstance: AnimationInstance?

}
