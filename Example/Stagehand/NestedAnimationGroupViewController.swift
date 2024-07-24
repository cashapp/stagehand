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

final class NestedAnimationGroupViewController: DemoViewController {
    
    // MARK: - Life Cycle
    
    override init() {
        super.init()
        
        contentView = mainView
        
        animationRows = [
            ("Sequential Nested Groups", { [unowned self] in
                self.performSequentialNestedGroupAnimations()
            })
        ]
    }
    
    // MARK: - Private Properties
    
    private let mainView: View = .init()
    
    // MARK: - Private Methods
    
    private func performSequentialNestedGroupAnimations() {
        var parentGroup = AnimationGroup()
        
        let leftGroup = makeLeftAnimationGroup()
        let rightGroup = makeRightAnimationGroup()
        
        parentGroup.addAnimationGroup(leftGroup, startingAt: 0, relativeDuration: 1)
        parentGroup.addAnimationGroup(rightGroup, startingAt: 0, relativeDuration: 1)
        
        parentGroup.perform(duration: 2)
    }
    
    private func makeLeftAnimationGroup() -> AnimationGroup {
        var leftGroup = AnimationGroup()
        let leftAnimation1 = self.makeAnimation(translationX: 100)
        let leftAnimation2 = self.makeAnimation(translationX: 75)
        leftGroup.addAnimation(leftAnimation1, for: self.mainView.leftView, startingAt: 0, relativeDuration: 0.5)
        leftGroup.addAnimation(leftAnimation2, for: self.mainView.leftNestView, startingAt: 0.5, relativeDuration: 0.5)
        return leftGroup
    }
    
    private func makeRightAnimationGroup() -> AnimationGroup {
        var rightGroup = AnimationGroup()
        let rightAnimation1 = self.makeAnimation(translationX: -100)
        let rightAnimation2 = self.makeAnimation(translationX: -75)
        rightGroup.addAnimation(rightAnimation1, for: self.mainView.rightView, startingAt: 0, relativeDuration: 0.5)
        rightGroup.addAnimation(rightAnimation2, for: self.mainView.rightNestView, startingAt: 0.5, relativeDuration: 0.5)
        return rightGroup
    }
    
    private func makeAnimation(translationX: CGFloat) -> Animation<UIView> {
        var animation = Animation<UIView>()
        animation.addKeyframe(for: \.transform, at: 0, value: .identity)
        animation.addKeyframe(for: \.transform, at: 1, value: .init(translationX: translationX, y: 0))
        return animation
    }
}

// MARK: -

extension NestedAnimationGroupViewController {
    
    final class View: UIView {
        
        // MARK: - Life Cycle
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            leftView.backgroundColor = .red
            addSubview(leftView)
            
            leftNestView.backgroundColor = .red
            addSubview(leftNestView)
            
            rightView.backgroundColor = .blue
            addSubview(rightView)
            
            rightNestView.backgroundColor = .blue
            addSubview(rightNestView)
        }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // MARK: - Public Properties
        
        let leftView: UIView = .init()
        let leftNestView: UIView = .init()
        let rightView: UIView = .init()
        let rightNestView: UIView = .init()
        
        // MARK: - UIView
        
        override func layoutSubviews() {
            leftView.bounds.size = .init(width: 50, height: 50)
            leftView.center = .init(
                x: bounds.width / 3,
                y: bounds.height / 2
            )
            
            leftNestView.bounds.size = .init(width: 25, height: 25)
            leftNestView.center = .init(
                x: bounds.width / 3,
                y: bounds.height / 2
            )
            
            rightView.bounds.size = .init(width: 50, height: 50)
            rightView.center = .init(
                x: bounds.width * 2 / 3,
                y: bounds.height / 2
            )
            
            rightNestView.bounds.size = .init(width: 25, height: 25)
            rightNestView.center = .init(
                x: bounds.width * 2 / 3,
                y: bounds.height / 2
            )
        }
    }
}
