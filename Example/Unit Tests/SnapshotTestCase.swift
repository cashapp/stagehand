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

import FBSnapshotTestCase

class SnapshotTestCase: FBSnapshotTestCase {

    // MARK: - Private Types

    @MainActor
    private struct TestDeviceConfig {

        // MARK: - Public Properties

        let systemVersion: String
        let screenSize: CGSize
        let screenScale: CGFloat

        // MARK: - Public Methods

        func matchesCurrentDevice() -> Bool {
            let device = UIDevice.current
            let screen = UIScreen.main

            return device.systemVersion == systemVersion
                && screen.bounds.size == screenSize
                && screen.scale == screenScale
        }

    }

    // MARK: - Private Static Properties

    private static let testedDevices = [
        TestDeviceConfig(systemVersion: "13.7", screenSize: CGSize(width: 375, height: 812), screenScale: 3),
    ]

    // MARK: - FBSnapshotTestCase

    @MainActor
    override func setUp() {
        super.setUp()

        guard SnapshotTestCase.testedDevices.contains(where: { $0.matchesCurrentDevice() }) else {
            fatalError("Attempting to run tests on a device for which we have not collected test data")
        }

        guard ProcessInfo.processInfo.environment["FB_REFERENCE_IMAGE_DIR"] != nil else {
            fatalError("The environment variable FB_REFERENCE_IMAGE_DIR must be set for the current scheme")
        }

        fileNameOptions = [.OS, .screenSize, .screenScale]

        recordMode = false
    }

}
