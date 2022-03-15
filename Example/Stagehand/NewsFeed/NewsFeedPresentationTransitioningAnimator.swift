//
//  Copyright 2021 Square Inc.
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

final class NewsFeedPresentationTransitioningAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    private typealias FromViewController = NewsFeedTransitionListViewController
    private typealias ToViewController = NewsFeedTransitionDetailViewController

    // MARK: - UIViewControllerAnimatedTransitioning

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return Constants.duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let navigationController = transitionContext.viewController(forKey: .from) as? UINavigationController,
            let fromViewController = navigationController.viewControllers.last as? FromViewController,
            let toViewController = transitionContext.viewController(forKey: .to) as? ToViewController
        else {
            fatalError("Transition context must provide from and to view controllers for animation")
        }

        guard let fromContext = fromViewController.transitionContextForLastSelectedCell() else {
            fatalError("Attempting to transition to item details, but no row has been selected")
        }

        let toContext = toViewController.transitionContext

        let context = Self.prepareForTransition(
            fromContext: fromContext,
            toContext: toContext,
            toViewController: toViewController,
            containerView: transitionContext.containerView,
            navigationController: navigationController
        )

        Self.makeAnimation().perform(on: context) { finished in
            Self.cleanUpTransition(fromViewController: fromViewController, context: context)
            transitionContext.completeTransition(finished)
        }
    }

    // MARK: - Static Methods

    static func prepareForTransition(
        fromContext: NewsFeedTransitionListContext,
        toContext: NewsFeedTransitionDetailContext,
        toViewController: UIViewController,
        containerView: UIView,
        navigationController: UINavigationController
    ) -> TransitionContext {
        containerView.bounds = navigationController.view.bounds

        toViewController.view.frame = containerView.bounds
        toViewController.view.layoutIfNeeded()
        containerView.addSubview(toViewController.view)

        let imageHeadlineView = NewsFeedImageHeadlineView()
        imageHeadlineView.imageView.image = toContext.imageHeadlineView.imageView.image
        imageHeadlineView.headlineLabel.text = toContext.imageHeadlineView.headlineLabel.text
        containerView.addSubview(imageHeadlineView)

        imageHeadlineView.frame = containerView.convert(
            fromContext.imageHeadlineView.bounds,
            from: fromContext.imageHeadlineView
        )

        return TransitionContext(
            fromContext: fromContext,
            toContext: toContext,
            containerView: containerView,
            imageHeadlineView: imageHeadlineView
        )
    }

    static func cleanUpTransition(
        fromViewController: UIViewController,
        context: TransitionContext
    ) {
        fromViewController.view.removeFromSuperview()
        context.imageHeadlineView.removeFromSuperview()
    }

    static func makeAnimation() -> Animation<TransitionContext> {
        var animation = Animation<TransitionContext>()
        animation.implicitDuration = Constants.duration

        var imageHeadlineAnimation = Animation<TransitionContext>()
        imageHeadlineAnimation.curve = CubicBezierAnimationCurve.easeInEaseOut
        imageHeadlineAnimation.addKeyframe(for: \.imageHeadlineView.frame, at: 0, relativeValue: { $0 })
        imageHeadlineAnimation.addKeyframe(for: \.imageHeadlineView.frame, at: 1, computedValue: { context in
            context.containerView.convert(
                context.toContext.imageHeadlineView.bounds,
                from: context.toContext.imageHeadlineView
            )
        })
        imageHeadlineAnimation.addKeyframe(for: \.imageHeadlineView.layer.cornerRadius, at: 0, computedValue: {
            $0.fromContext.imageHeadlineView.layer.cornerRadius
        })
        imageHeadlineAnimation.addKeyframe(for: \.imageHeadlineView.layer.cornerRadius, at: 1, computedValue: {
            $0.toContext.imageHeadlineView.layer.cornerRadius
        })
        imageHeadlineAnimation.addKeyframe(for: \.imageHeadlineView.headlineInsets, at: 0, computedValue: {
            $0.fromContext.imageHeadlineView.headlineInsets
        })
        imageHeadlineAnimation.addKeyframe(for: \.imageHeadlineView.headlineInsets, at: 1, computedValue: {
            $0.toContext.imageHeadlineView.headlineInsets
        })
        imageHeadlineAnimation.addKeyframe(for: \.imageHeadlineView.imageRegion, at: 0, computedValue: {
            $0.fromContext.imageHeadlineView.imageRegion
        })
        imageHeadlineAnimation.addKeyframe(for: \.imageHeadlineView.imageRegion, at: 1, computedValue: {
            $0.toContext.imageHeadlineView.imageRegion
        })
        imageHeadlineAnimation.addExecution(
            onForward: { context in
                context.fromContext.imageHeadlineView.isHidden = true
                context.toContext.imageHeadlineView.isHidden = true
                context.imageHeadlineView.isHidden = false
            },
            at: 0
        )
        imageHeadlineAnimation.addExecution(
            onForward: { context in
                context.fromContext.imageHeadlineView.isHidden = false
                context.toContext.imageHeadlineView.isHidden = false
                context.imageHeadlineView.isHidden = true
            },
            at: 1
        )
        animation.addChild(imageHeadlineAnimation, for: \.self, startingAt: 0, relativeDuration: 0.8)

        var backgroundAnimation = Animation<UIView>()
        backgroundAnimation.addKeyframe(for: \.backgroundColor, at: 0, value: nil)
        backgroundAnimation.addKeyframe(for: \.backgroundColor, at: 1, relativeValue: { $0 })
        animation.addChild(backgroundAnimation, for: \.toContext.backgroundView, startingAt: 0, relativeDuration: 0.4)

        var bodyAnimation = Animation<UILabel>()
        bodyAnimation.addKeyframe(for: \.transform, at: 0, value: .init(translationX: 0, y: 5))
        bodyAnimation.addKeyframe(for: \.transform, at: 1, value: .identity)
        bodyAnimation.addKeyframe(for: \.alpha, at: 0, value: 0)
        bodyAnimation.addKeyframe(for: \.alpha, at: 1, value: 1)
        animation.addChild(bodyAnimation, for: \.toContext.bodyLabel, startingAt: 0.7, relativeDuration: 0.3)

        var closeButtonAnimation = Animation<UIView>()
        closeButtonAnimation.curve = CubicBezierAnimationCurve.easeOut
        closeButtonAnimation.addKeyframe(for: \.alpha, at: 0, value: 0)
        closeButtonAnimation.addKeyframe(for: \.alpha, at: 1, value: 1)
        closeButtonAnimation.addKeyframe(for: \.transform, at: 0, value: .init(scaleX: 0.8, y: 0.8))
        closeButtonAnimation.addKeyframe(for: \.transform, at: 1, value: .identity)
        animation.addChild(closeButtonAnimation, for: \.toContext.closeButton, startingAt: 0.85, relativeDuration: 0.15)

        return animation
    }

    // MARK: - Internal Types

    final class TransitionContext {

        internal init(
            fromContext: NewsFeedTransitionListContext,
            toContext: NewsFeedTransitionDetailContext,
            containerView: UIView,
            imageHeadlineView: NewsFeedImageHeadlineView
        ) {
            self.fromContext = fromContext
            self.toContext = toContext
            self.containerView = containerView
            self.imageHeadlineView = imageHeadlineView
        }

        let fromContext: NewsFeedTransitionListContext

        let toContext: NewsFeedTransitionDetailContext

        let containerView: UIView

        let imageHeadlineView: NewsFeedImageHeadlineView

    }

    enum Constants {

        static let duration: TimeInterval = 0.75

    }

}
