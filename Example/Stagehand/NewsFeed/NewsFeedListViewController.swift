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

import UIKit

final class NewsFeedListViewController: UITableViewController {

    // MARK: - Life Cycle

    init() {
        super.init(style: .plain)

        tableView.register(
            NewsFeedListCell.self,
            forCellReuseIdentifier: String(describing: NewsFeedListCell.self)
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Properties

    private let itemTransitioningDelegate = NewsFeedTransitioningDelegate()

    private var lastSelectedCell: NewsFeedListCell?

    // MARK: - UITableViewController

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Self.newsFeedItems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: String(describing: NewsFeedListCell.self), for: indexPath)
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? NewsFeedListCell else {
            fatalError("Invalid cell type in news feed")
        }

        cell.configure(with: Self.newsFeedItems[indexPath.row])
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return NewsFeedListCell.height(for: Self.newsFeedItems[indexPath.row], in: tableView)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        lastSelectedCell = tableView.cellForRow(at: indexPath) as? NewsFeedListCell

        let itemViewController = NewsFeedItemViewController(item: Self.newsFeedItems[indexPath.row])
        itemViewController.modalPresentationStyle = .fullScreen
        itemViewController.transitioningDelegate = itemTransitioningDelegate
        present(itemViewController, animated: true)
    }

}

// MARK: -

extension NewsFeedListViewController: NewsFeedTransitionListViewController {

    func transitionContextForLastSelectedCell() -> NewsFeedTransitionListContext? {
        return lastSelectedCell?.makeTransitionContext()
    }

}

// MARK: -

extension NewsFeedListViewController {

    static let newsFeedItems: [NewsFeedItem] = [
        .init(
            image: UIImage(named: "NewsFeedImage1")!,
            imageHighlightRegion: CGRect(x: 0.35, y: 0.126, width: 0.372, height: 0.321),
            headline: "Shapes",
            body: """
                Shapes are awesome. You should use lots of shapes. In fact, most things are made out of shapes.
                """
        ),
        .init(
            image: UIImage(named: "NewsFeedImage2")!,
            imageHighlightRegion: CGRect(x: 0, y: 0.244, width: 0.6, height: 0.7),
            headline: "Night Sky",
            body: """
                The night sky is... very cool. Like seriously, it's cold out there. But also how beautiful is the big, \
                bright moon against the wonderful backdrop of stars.
                """
        ),
        .init(
            image: UIImage(named: "NewsFeedImage1")!,
            imageHighlightRegion: CGRect(x: 0.35, y: 0.126, width: 0.372, height: 0.321),
            headline: "Shapes",
            body: """
                Shapes are awesome. You should use lots of shapes. In fact, most things are made out of shapes.
                """
        ),
        .init(
            image: UIImage(named: "NewsFeedImage2")!,
            imageHighlightRegion: CGRect(x: 0, y: 0.244, width: 0.6, height: 0.7),
            headline: "Night Sky",
            body: """
                The night sky is... very cool. Like seriously, it's cold out there. But also how beautiful is the big, \
                bright moon against the wonderful backdrop of stars.
                """
        ),
        .init(
            image: UIImage(named: "NewsFeedImage1")!,
            imageHighlightRegion: CGRect(x: 0.35, y: 0.126, width: 0.372, height: 0.321),
            headline: "Shapes",
            body: """
                Shapes are awesome. You should use lots of shapes. In fact, most things are made out of shapes.
                """
        ),
        .init(
            image: UIImage(named: "NewsFeedImage2")!,
            imageHighlightRegion: CGRect(x: 0, y: 0.244, width: 0.6, height: 0.7),
            headline: "Night Sky",
            body: """
                The night sky is... very cool. Like seriously, it's cold out there. But also how beautiful is the big, \
                bright moon against the wonderful backdrop of stars.
                """
        ),
    ]

}
