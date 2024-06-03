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

class DemoViewController: UIViewController {

    // MARK: - Life Cycle

    init() {
        super.init(nibName: nil, bundle: nil)

        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)

        view.backgroundColor = .white
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Properties

    var animationRows: [(name: String, action: () -> Void)] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    var contentView: UIView = .init() {
        didSet {
            oldValue.removeFromSuperview()
            view.addSubview(contentView)
            view.setNeedsLayout()
        }
    }

    var contentHeight: CGFloat = 200 {
        didSet {
            view.setNeedsLayout()
        }
    }

    // MARK: - Private Properties

    private let tableView: UITableView = .init()

    // MARK: - UIView

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let topInset = [
            view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0,
            navigationController?.navigationBar.frame.height,
        ].compactMap { $0 }.reduce(0, +)

        contentView.frame = CGRect(
            x: 0,
            y: topInset,
            width: view.bounds.width,
            height: contentHeight
        )

        tableView.frame = CGRect(
            x: 0,
            y: topInset + contentHeight,
            width: view.bounds.width,
            height: view.bounds.height - contentHeight - topInset
        )
    }

}

// MARK: -

extension DemoViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return animationRows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell(style: .default, reuseIdentifier: nil)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let row = animationRows[indexPath.row]
        cell.textLabel?.text = row.name
        cell.textLabel?.adjustsFontSizeToFitWidth = true
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = animationRows[indexPath.row]
        row.action()
        tableView.deselectRow(at: indexPath, animated: true)
    }

}
