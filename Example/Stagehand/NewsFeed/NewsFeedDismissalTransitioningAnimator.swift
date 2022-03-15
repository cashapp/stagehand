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

final class NewsFeedDismissalTransitioningAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    private typealias FromViewController = NewsFeedTransitionDetailViewController
    private typealias ToViewController = NewsFeedTransitionListViewController
    internal typealias FromContext = NewsFeedTransitionDetailContext
    internal typealias ToContext = NewsFeedTransitionListContext

    // MARK: - UIViewControllerAnimatedTransitioning

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return Constants.duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let navigationController = transitionContext.viewController(forKey: .to) as? UINavigationController,
            let toViewController = navigationController.viewControllers.last as? ToViewController,
            let fromViewController = transitionContext.viewController(forKey: .from) as? FromViewController
        else {
            fatalError("Transition context must provide from and to view controllers for animation")
        }

        guard let toContext = toViewController.transitionContextForLastSelectedCell() else {
            fatalError("Attempting to transition to list view, but no row has been previously selected")
        }

        let fromContext = fromViewController.transitionContext

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
        fromContext: FromContext,
        toContext: ToContext,
        toViewController: UIViewController,
        containerView: UIView,
        navigationController: UINavigationController
    ) -> TransitionContext {
        containerView.bounds = navigationController.view.bounds

        containerView.insertSubview(navigationController.view, at: 0)

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
        animation.curve = CubicBezierAnimationCurve.easeInEaseOut

        var imageHeadlineAnimation = Animation<TransitionContext>()
        imageHeadlineAnimation.curve = CubicBezierAnimationCurve.easeInEaseOut
        imageHeadlineAnimation.addKeyframe(for: \.imageHeadlineView.frame, at: 0, relativeValue: { $0 })
        imageHeadlineAnimation.addKeyframe(for: \.imageHeadlineView.frame, at: 1, computedValue: {
            $0.containerView.convert($0.toContext.imageHeadlineView.bounds, from: $0.toContext.imageHeadlineView)
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
                context.toContext.imageHeadlineView.isHidden = false
                context.imageHeadlineView.isHidden = true
            },
            at: 1
        )
        animation.addChild(imageHeadlineAnimation, for: \.self, startingAt: 0, relativeDuration: 0.8)

        var backgroundAnimation = Animation<UIView>()
        backgroundAnimation.addKeyframe(for: \.backgroundColor, at: 0, relativeValue: { $0 })
        backgroundAnimation.addKeyframe(for: \.backgroundColor, at: 1, value: nil)
        animation.addChild(backgroundAnimation, for: \.fromContext.backgroundView, startingAt: 0.2, relativeDuration: 0.4)

        var bodyAnimation = Animation<UILabel>()
        bodyAnimation.addKeyframe(for: \.alpha, at: 0, value: 1)
        bodyAnimation.addKeyframe(for: \.alpha, at: 1, value: 0)
        animation.addChild(bodyAnimation, for: \.fromContext.bodyLabel, startingAt: 0, relativeDuration: 0.2)

        var closeButtonAnimation = Animation<UIView>()
        closeButtonAnimation.curve = CubicBezierAnimationCurve.easeIn
        closeButtonAnimation.addKeyframe(for: \.alpha, at: 0, value: 1)
        closeButtonAnimation.addKeyframe(for: \.alpha, at: 1, value: 0)
        closeButtonAnimation.addKeyframe(for: \.transform, at: 0, value: .identity)
        closeButtonAnimation.addKeyframe(for: \.transform, at: 1, value: .init(scaleX: 0.8, y: 0.8))
        animation.addChild(closeButtonAnimation, for: \.fromContext.closeButton, startingAt: 0, relativeDuration: 0.2)

        return animation
    }

    // MARK: - Private Types

    final class TransitionContext {

        internal init(
            fromContext: NewsFeedDismissalTransitioningAnimator.FromContext,
            toContext: NewsFeedDismissalTransitioningAnimator.ToContext,
            containerView: UIView,
            imageHeadlineView: NewsFeedImageHeadlineView
        ) {
            self.fromContext = fromContext
            self.toContext = toContext
            self.containerView = containerView
            self.imageHeadlineView = imageHeadlineView
        }

        let fromContext: FromContext

        let toContext: ToContext

        let containerView: UIView

        let imageHeadlineView: NewsFeedImageHeadlineView

    }

    enum Constants {

        static let duration: TimeInterval = 0.75

    }

}
