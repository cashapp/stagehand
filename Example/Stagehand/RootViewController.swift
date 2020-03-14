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

import UIKit

final class RootViewController: UITableViewController {

    // MARK: - Life Cycle

    init() {
        super.init(style: .plain)

        navigationItem.title = "Stagehand Demo"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Properties

    private let demoScreens: [(name: String, viewControllerFactory: () -> UIViewController)] = [
        ("Simple Animations", { SimpleAnimationsViewController() }),
        ("Relative Animations", { RelativeAnimationsViewController() }),
        ("Color Animations", { ColorAnimationsViewController() }),
        ("Child Animations", { ChildAnimationsViewController() }),
        ("Animation Curves", { AnimationCurveViewController() }),
        ("Child Animations with Curves", { ChildAnimationsWithCurvesViewController() }),
        ("Animation Cancellation", { AnimationCancelationViewController() }),
        ("Property Assignments", { PropertyAssignmentViewController() }),
        ("Repeating Animations", { RepeatingAnimationsViewController() }),
        ("Execution Blocks", { ExecutionBlockViewController() }),
        ("Animation Groups", { AnimationGroupViewController() }),
        ("Collection Keyframes", { CollectionKeyframesViewController() }),
        ("Performance Benchmark", { PerformanceBenchmarkViewController() }),
        ("Animation Queues", { AnimationQueueViewController() }),
        ("Layer Transforms", { LayerTransformViewController() }),
    ]

    // MARK: - UITableViewController

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return demoScreens.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell(style: .default, reuseIdentifier: nil)
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let screen = demoScreens[indexPath.row]
        cell.textLabel?.text = screen.name
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let screen = demoScreens[indexPath.row]
        navigationController?.pushViewController(screen.viewControllerFactory(), animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

