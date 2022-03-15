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
import StagehandTesting
import XCTest

@testable import Stagehand_Example

final class NewsFeedSnapshotTests: SnapshotTestCase {

    // MARK: - Tests

    func testPresentationTransition() {
        let listViewController = NewsFeedListViewController()

        let navigationController = UINavigationController(rootViewController: listViewController)
        let containerView = UIView(frame: UIScreen.main.bounds)
        containerView.addSubview(navigationController.view)

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = navigationController
        window.addSubview(containerView)
        window.makeKeyAndVisible()
        RunLoop.current.run(until: Date())

        listViewController.tableView.reloadData()
        window.layoutIfNeeded()

        let item = NewsFeedListViewController.newsFeedItems[1]
        guard
            let cell = listViewController.tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? NewsFeedListCell
        else {
            XCTFail("Unable to find cell for expected row")
            return
        }
        let fromContext = cell.makeTransitionContext()

        let itemViewController = NewsFeedItemViewController(item: item)
        let toContext = itemViewController.transitionContext

        let context = NewsFeedPresentationTransitioningAnimator.prepareForTransition(
            fromContext: fromContext,
            toContext: toContext,
            toViewController: itemViewController,
            containerView: containerView,
            navigationController: navigationController
        )

        let animation = NewsFeedPresentationTransitioningAnimator.makeAnimation()

        SnapshotVerify(animation: animation, on: context, using: containerView, fps: 20)

        // We don't really need to clean up the transition at this point, but if there were subsequent snapshot tests
        // or other assertions following the previous `SnapshotVerify(animationGroup:using:)` call, this clean up would
        // be necessary in many cases.
        NewsFeedPresentationTransitioningAnimator.cleanUpTransition(
            fromViewController: listViewController,
            context: context
        )
    }

    func testDismissalTransition() {
        let listViewController = NewsFeedListViewController()

        let navigationController = UINavigationController(rootViewController: listViewController)
        let containerView = UIView(frame: UIScreen.main.bounds)
        containerView.addSubview(navigationController.view)

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = navigationController
        window.addSubview(containerView)
        window.makeKeyAndVisible()
        RunLoop.current.run(until: Date())

        listViewController.tableView.reloadData()
        window.layoutIfNeeded()

        let item = NewsFeedListViewController.newsFeedItems[1]
        guard
            let cell = listViewController.tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? NewsFeedListCell
        else {
            XCTFail("Unable to find cell for expected row")
            return
        }
        let toContext = cell.makeTransitionContext()

        let itemViewController = NewsFeedItemViewController(item: item)
        let fromContext = itemViewController.transitionContext

        let context = NewsFeedDismissalTransitioningAnimator.prepareForTransition(
            fromContext: fromContext,
            toContext: toContext,
            toViewController: itemViewController,
            containerView: containerView,
            navigationController: navigationController
        )

        let animation = NewsFeedDismissalTransitioningAnimator.makeAnimation()

        SnapshotVerify(animation: animation, on: context, using: containerView, fps: 20)

        // We don't really need to clean up the transition at this point, but if there were subsequent snapshot tests
        // or other assertions following the previous `SnapshotVerify(animationGroup:using:)` call, this clean up would
        // be necessary in many cases.
        NewsFeedDismissalTransitioningAnimator.cleanUpTransition(
            fromViewController: listViewController,
            context: context
        )
    }

}
