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

import FBSnapshotTestCase
import ImageIO

@testable import Stagehand

extension FBSnapshotTestCase {

    // MARK: - Public Methods

    /// Snapshots the `element` over time as the `animation` is performed on it.
    ///
    /// When `recordMode` is true, records an animated snapshot of the view. When `recordMode` is false, performs a
    /// comparison with the existing snapshot.
    ///
    /// Note that this method can generate fairly large snapshot files. The higher the `fps`, the more frames will be
    /// captured, and therefore the larger the file output.
    ///
    /// - parameter animation: The animation to perform on the element.
    /// - parameter element: The view to be animated, and which will be snapshotted to verify the animation.
    /// - parameter fps: The number of frames per seconds at which to record the snapshot.
    /// - parameter bookendFrameDuration: The behavior to use for determining the duration of the first and last frame
    /// the recording. For looping animations, it is recommended to use `.matchIntermediateFrames`.
    /// - parameter identifier: An optional identifier included in the snapshot name, for use when there are multiple
    /// snapshot tests in a given test method. Defaults to no identifier.
    /// - parameter suffixes: An ordered set of strings representing the platform suffixes.
    /// - parameter file: The file in which the test result should be attributed.
    /// - parameter line: The line in which the test result should be attributed.
    public func SnapshotVerify<ElementType: UIView>(
        animation: Animation<ElementType>,
        on element: ElementType,
        fps: Double = AnimationSnapshotting.defaultAnimationSnapshotFPS,
        bookendFrameDuration: AnimationSnapshotting.BookendFrameDuration = .default,
        identifier: String = "",
        suffixes: NSOrderedSet = FBSnapshotTestCaseDefaultSuffixes(),
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let driver = NoOpDriver()

        let animationInstance = AnimationInstance(
            animation: animation,
            element: element,
            driver: driver
        )

        let includeReverseCycle: Bool
        switch animation.implicitRepeatStyle {
        case let .repeating(count: count, autoreversing: autoreversing):
            includeReverseCycle = (count != 1 && autoreversing)
        }

        SnapshotVerify(
            animationInstance: animationInstance,
            using: element,
            animationDuration: animation.implicitDuration,
            includeReverseCycle: includeReverseCycle,
            fps: fps,
            bookendFrameDuration: bookendFrameDuration,
            identifier: identifier,
            suffixes: suffixes,
            file: file,
            line: line
        )

        animationInstance.cancel(behavior: .revert)
    }

    /// Snapshots the `view` over time as the `animation` is performed on the `element`.
    ///
    /// When `recordMode` is true, records an animated snapshot of the view. When `recordMode` is false, performs a
    /// comparison with the existing snapshot.
    ///
    /// Note that this method can generate fairly large snapshot files. The higher the `fps`, the more frames will be
    /// captured, and therefore the larger the file output.
    ///
    /// - parameter animation: The animation to perform on the element.
    /// - parameter element: The element to be animated.
    /// - parameter view: The view which will be snapshotted to verify the animation.
    /// - parameter fps: The number of frames per seconds at which to record the snapshot.
    /// - parameter bookendFrameDuration: The behavior to use for determining the duration of the first and last frame
    /// the recording. For looping animations, it is recommended to use `.matchIntermediateFrames`.
    /// - parameter identifier: An optional identifier included in the snapshot name, for use when there are multiple
    /// snapshot tests in a given test method. Defaults to no identifier.
    /// - parameter suffixes: An ordered set of strings representing the platform suffixes.
    /// - parameter file: The file in which the test result should be attributed.
    /// - parameter line: The line in which the test result should be attributed.
    public func SnapshotVerify<ElementType>(
        animation: Animation<ElementType>,
        on element: ElementType,
        using view: UIView,
        fps: Double = AnimationSnapshotting.defaultAnimationSnapshotFPS,
        bookendFrameDuration: AnimationSnapshotting.BookendFrameDuration = .default,
        identifier: String = "",
        suffixes: NSOrderedSet = FBSnapshotTestCaseDefaultSuffixes(),
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let driver = NoOpDriver()

        let animationInstance = AnimationInstance(
            animation: animation,
            element: element,
            driver: driver
        )

        let includeReverseCycle: Bool
        switch animation.implicitRepeatStyle {
        case let .repeating(count: count, autoreversing: autoreversing):
            includeReverseCycle = (count != 1 && autoreversing)
        }

        SnapshotVerify(
            animationInstance: animationInstance,
            using: view,
            animationDuration: animation.implicitDuration,
            includeReverseCycle: includeReverseCycle,
            fps: fps,
            bookendFrameDuration: bookendFrameDuration,
            identifier: identifier,
            suffixes: suffixes,
            file: file,
            line: line
        )

        animationInstance.cancel(behavior: .revert)
    }

    /// Snapshots the `view` over time as the `animationGroup` is performed.
    ///
    /// When `recordMode` is true, records an animated snapshot of the view. When `recordMode` is false, performs a
    /// comparison with the existing snapshot.
    ///
    /// Note that this method can generate fairly large snapshot files. The higher the `fps`, the more frames will be
    /// captured, and therefore the larger the file output.
    ///
    /// - parameter animationGroup: The animation group to execute.
    /// - parameter view: The view that should be snapshotted to verify the animation group. In practice, this will
    /// usually be a view that is either in the animation group, or is a parent that contains the views in the animation
    /// group.
    /// - parameter fps: The number of frames per seconds at which to record the snapshot.
    /// - parameter bookendFrameDuration: The behavior to use for determining the duration of the first and last frame
    /// the recording. For looping animations, it is recommended to use `.matchIntermediateFrames`.
    /// - parameter identifier: An optional identifier included in the snapshot name, for use when there are multiple
    /// snapshot tests in a given test method. Defaults to no identifier.
    /// - parameter suffixes: An ordered set of strings representing the platform suffixes.
    /// - parameter file: The file in which the test result should be attributed.
    /// - parameter line: The line in which the test result should be attributed.
    public func SnapshotVerify(
        animationGroup: AnimationGroup,
        using view: UIView,
        fps: Double = AnimationSnapshotting.defaultAnimationSnapshotFPS,
        bookendFrameDuration: AnimationSnapshotting.BookendFrameDuration = .default,
        identifier: String = "",
        suffixes: NSOrderedSet = FBSnapshotTestCaseDefaultSuffixes(),
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let driver = NoOpDriver()

        let animationInstance = AnimationInstance(
            animation: animationGroup.animation,
            element: animationGroup.elementContainer,
            driver: driver
        )

        let includeReverseCycle: Bool
        switch animationGroup.implicitRepeatStyle {
        case let .repeating(count: count, autoreversing: autoreversing):
            includeReverseCycle = (count != 1 && autoreversing)
        }

        SnapshotVerify(
            animationInstance: animationInstance,
            using: view,
            animationDuration: animationGroup.implicitDuration,
            includeReverseCycle: includeReverseCycle,
            fps: fps,
            bookendFrameDuration: bookendFrameDuration,
            identifier: identifier,
            suffixes: suffixes,
            file: file,
            line: line
        )

        animationInstance.cancel(behavior: .revert)
    }

    // MARK: - Private Methods

    private func SnapshotVerify(
        animationInstance: AnimationInstance,
        using view: UIView,
        animationDuration: TimeInterval,
        includeReverseCycle: Bool,
        fps: Double,
        bookendFrameDuration: AnimationSnapshotting.BookendFrameDuration,
        identifier: String,
        suffixes: NSOrderedSet,
        file: StaticString,
        line: UInt
    ) {
        if recordMode {
            recordSnapshot(
                of: animationInstance,
                using: view,
                animationDuration: animationDuration,
                includeReverseCycle: includeReverseCycle,
                fps: fps,
                bookendFrameDuration: bookendFrameDuration,
                identifier: identifier,
                suffix: suffixes.firstObject as! String,
                file: file,
                line: line
            )

        } else {
            performComparisonToReferenceSnapshot(
                of: animationInstance,
                using: view,
                animationDuration: animationDuration,
                includeReverseCycle: includeReverseCycle,
                fps: fps,
                bookendFrameDuration: bookendFrameDuration,
                identifier: identifier,
                suffixes: suffixes,
                file: file,
                line: line
            )
        }
    }

    private func recordSnapshot(
        of animationInstance: AnimationInstance,
        using view: UIView,
        animationDuration: TimeInterval,
        includeReverseCycle: Bool,
        fps: Double,
        bookendFrameDuration: AnimationSnapshotting.BookendFrameDuration,
        identifier: String,
        suffix: String,
        file: StaticString,
        line: UInt
    ) {
        guard let imageURL = AnimationSnapshotting.generateAnimatedSnapshot(
            of: animationInstance,
            using: view,
            animationDuration: animationDuration,
            includeReverseCycle: includeReverseCycle,
            fps: fps,
            bookendFrameDuration: bookendFrameDuration
        ) else {
            XCTFail("Failed to generate reference image.", file: file, line: line)
            return
        }

        let testName = NSStringFromSelector(invocation!.selector)

        XCTContext.runActivity(named: identifier.isEmpty ? testName : identifier) { activity in
            let attachment = XCTAttachment(contentsOfFile: imageURL)
            attachment.name = "Recorded Image"
            activity.add(attachment)
        }

        let filePath = referenceFilePath(for: testName, identifier: identifier, suffix: suffix)

        try! FileManager().createDirectory(
            atPath: (filePath as NSString).deletingLastPathComponent,
            withIntermediateDirectories: true,
            attributes: nil
        )

        let fileURL = URL(fileURLWithPath: filePath)
        let data = try! Data(contentsOf: imageURL)
        try! data.write(to: fileURL, options: .atomicWrite)

        XCTFail(
            "Test ran in record mode. Reference image is now saved."
                + " Disable record mode to perform an actual snapshot comparison!",
            file: file,
            line: line
        )
    }

    private func performComparisonToReferenceSnapshot(
        of animationInstance: AnimationInstance,
        using view: UIView,
        animationDuration: TimeInterval,
        includeReverseCycle: Bool,
        fps: Double,
        bookendFrameDuration: AnimationSnapshotting.BookendFrameDuration,
        identifier: String,
        suffixes: NSOrderedSet,
        file: StaticString,
        line: UInt
    ) {
        guard
            let testImageURL = AnimationSnapshotting.generateAnimatedSnapshot(
                of: animationInstance,
                using: view,
                animationDuration: animationDuration,
                includeReverseCycle: includeReverseCycle,
                fps: fps,
                bookendFrameDuration: bookendFrameDuration
            ),
            let testImage = try? Data(contentsOf: testImageURL)
        else {
            XCTFail("Failed to generate snapshot for view.", file: file, line: line)
            return
        }

        let testName = NSStringFromSelector(invocation!.selector)
        let fileManager = FileManager()
        let referenceImageURLs = suffixes.map {
            URL(fileURLWithPath: referenceFilePath(for: testName, identifier: identifier, suffix: $0 as! String))
        }

        guard
            let referenceImageURL = referenceImageURLs.first(where: { fileManager.fileExists(atPath: $0.path) }),
            let referenceImage = try? Data(contentsOf: referenceImageURL)
        else {
            XCTFail("Couldn't load reference image.", file: file, line: line)
            return
        }

        if testImage != referenceImage {
            XCTFail("Test image doesn't match reference image.", file: file, line: line)

            XCTContext.runActivity(named: identifier.isEmpty ? testName : identifier) { activity in
                let referenceAttachment = XCTAttachment(contentsOfFile: referenceImageURL)
                referenceAttachment.name = "Reference Image"
                activity.add(referenceAttachment)

                let failedAttachment = XCTAttachment(contentsOfFile: testImageURL)
                failedAttachment.name = "Failed Image"
                activity.add(failedAttachment)
            }
        }
    }

    private func referenceFilePath(
        for testName: String,
        identifier: String,
        suffix: String
    ) -> String {
        var filePath = getReferenceImageDirectory(withDefault: nil)

        filePath.append(suffix)

        if let folderName = folderName {
            filePath = (filePath as NSString).appendingPathComponent(folderName)
        }

        var fileName: String
        if identifier.isEmpty {
            fileName = testName
        } else {
            fileName = "\(testName)_\(identifier)"
        }

        if !fileNameOptions.isEmpty {
            fileName = FBFileNameIncludeNormalizedFileNameFromOption(fileName, fileNameOptions)
        }

        filePath = (filePath as NSString).appendingPathComponent(fileName)

        return (filePath as NSString).appendingPathExtension("png")!
    }

}
