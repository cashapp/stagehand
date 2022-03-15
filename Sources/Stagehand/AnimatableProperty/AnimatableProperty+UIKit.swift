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

extension UIEdgeInsets: AnimatableProperty {

    public static func value(between initialValue: UIEdgeInsets, and finalValue: UIEdgeInsets, at progress: Double) -> UIEdgeInsets {
        return UIEdgeInsets(
            top: CGFloat.value(between: initialValue.top, and: finalValue.top, at: progress),
            left: CGFloat.value(between: initialValue.left, and: finalValue.left, at: progress),
            bottom: CGFloat.value(between: initialValue.bottom, and: finalValue.bottom, at: progress),
            right: CGFloat.value(between: initialValue.right, and: finalValue.right, at: progress)
        )
    }

}
