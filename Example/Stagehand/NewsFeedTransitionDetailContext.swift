//
//  Copyright 2022 Square Inc.
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

final class NewsFeedTransitionDetailContext {

    internal init(
        backgroundView: UIView,
        imageHeadlineView: NewsFeedImageHeadlineView,
        bodyLabel: UILabel,
        closeButton: UIView
    ) {
        self.backgroundView = backgroundView
        self.imageHeadlineView = imageHeadlineView
        self.bodyLabel = bodyLabel
        self.closeButton = closeButton
    }

    let backgroundView: UIView

    let imageHeadlineView: NewsFeedImageHeadlineView

    let bodyLabel: UILabel

    let closeButton: UIView

}

protocol NewsFeedTransitionDetailViewController: UIViewController {

    var transitionContext: NewsFeedTransitionDetailContext { get }

}
