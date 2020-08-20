//
//  Copyright 2020 Square Inc.
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

extension CATransform3D {

    func translatedBy(x: CGFloat = 0, y: CGFloat = 0, z: CGFloat = 0) -> CATransform3D {
        return CATransform3DTranslate(self, x, y, z)
    }

    func scaledBy(x: CGFloat = 1, y: CGFloat = 1, z: CGFloat = 1) -> CATransform3D {
        return CATransform3DScale(self, x, y, z)
    }

    func rotatedBy(angle: CGFloat, x: CGFloat, y: CGFloat, z: CGFloat) -> CATransform3D {
        return CATransform3DRotate(self, angle, x, y, z)
    }

    func shearedBy(
        xy: CGFloat = 0,
        yx: CGFloat = 0,
        xz: CGFloat = 0,
        zx: CGFloat = 0,
        yz: CGFloat = 0,
        zy: CGFloat = 0
    ) -> CATransform3D {
        var shearMatrix = CATransform3DIdentity
        shearMatrix.m12 = yx
        shearMatrix.m13 = zx
        shearMatrix.m21 = xy
        shearMatrix.m23 = zy
        shearMatrix.m31 = xz
        shearMatrix.m32 = yz
        return CATransform3DConcat(shearMatrix, self)
    }

    func withPerspective(eyePosition: CGFloat) -> CATransform3D {
        var transform = self
        transform.m34 = -1 / eyePosition
        return transform
    }

}
