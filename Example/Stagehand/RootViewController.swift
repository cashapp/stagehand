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

    private typealias RowModel = (name: String, viewControllerFactory: () -> UIViewController)

    /// Screens that show an example of a complete animation.
    private let demoScreens: [RowModel] = [
    ]

    /// Screens that show how a specific feature can be used.
    private let featureScreens: [RowModel] = [
        ("Simple Keyframe Animations", { SimpleAnimationsViewController() }),
        ("Relative Keyframe Animations", { RelativeAnimationsViewController() }),
        ("Color Keyframe Animations", { ColorAnimationsViewController() }),
        ("Child Animations", { ChildAnimationsViewController() }),
        ("Animation Curves", { AnimationCurveViewController() }),
        ("Child Animations with Curves", { ChildAnimationsWithCurvesViewController() }),
        ("Animation Cancellation", { AnimationCancelationViewController() }),
        ("Property Assignments", { PropertyAssignmentViewController() }),
        ("Repeating Animations", { RepeatingAnimationsViewController() }),
        ("Execution Blocks", { ExecutionBlockViewController() }),
        ("Animation Groups", { AnimationGroupViewController() }),
        ("Animation Queues", { AnimationQueueViewController() }),
    ]

    /// Screens that are used for debugging specific functionality.
    private let debuggingScreens: [RowModel] = [
        ("Child Animation Progress", { ChildAnimationProgressViewController() }),
        ("Performance Benchmark", { PerformanceBenchmarkViewController() }),
        ("CGAffineTransform Debugging", { CGAffineTransformDebuggingViewController() }),
    ]

    // MARK: - UITableViewController

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows(for: Section(rawValue: section)!).count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell(style: .default, reuseIdentifier: nil)
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let screen = rows(for: Section(rawValue: indexPath.section)!)[indexPath.row]
        cell.textLabel?.text = screen.name
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let screen = rows(for: Section(rawValue: indexPath.section)!)[indexPath.row]
        navigationController?.pushViewController(screen.viewControllerFactory(), animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .integrationDemos:
            return "Sample Animations"
        case .featureDemos:
            return "Feature Explorations"
        case .debuggingTools:
            return "Debugging Tools"
        }
    }

    // MARK: - Private Methods

    private func rows(for section: Section) -> [RowModel] {
        switch section {
        case .integrationDemos:
            return demoScreens
        case .featureDemos:
            return featureScreens
        case .debuggingTools:
            return debuggingScreens
        }
    }

    // MARK: - Private Types

    private enum Section: Int, CaseIterable {
        case integrationDemos
        case featureDemos
        case debuggingTools
    }

}

