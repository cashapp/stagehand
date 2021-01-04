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
import MobileCoreServices

@testable import Stagehand

extension FBSnapshotTestCase {

    // MARK: - Public Types

    /// Definition of the how the duration of the first and last frame of the APNG should be determined. The duration of
    /// intermediate frames is based on the rate at which the frames are captured (`fps`) so that the recording will
    /// play in real time with the animation.
    public enum BookendFrameDuration {

        /// The first and last frame should have the same duration as the intermediate frames (based on the `fps` of the
        /// recording). When snapshotting a looping animation, it is recommended to use `.matchIntermediateFrames` so
        /// the snapshot will not pause before/after each cycle.
        case matchIntermediateFrames

        /// Use custom durations for the first and last frame. Setting the bookend frames to a longer duration makes it
        /// easier to see where the animation begins and end.
        case custom(firstFrameDuration: TimeInterval, lastFrameDuration: TimeInterval)

        public static let `default`: BookendFrameDuration = .custom(firstFrameDuration: 1, lastFrameDuration: 1)

    }

    // MARK: - Public Static Properties

    /// The default frame rate (in frames per second) at which to record an animated PNG of an animation.
    public static let defaultAnimationSnapshotFPS: Double = 10

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
        fps: Double = defaultAnimationSnapshotFPS,
        bookendFrameDuration: BookendFrameDuration = .default,
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
        fps: Double = defaultAnimationSnapshotFPS,
        bookendFrameDuration: BookendFrameDuration = .default,
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
        fps: Double = defaultAnimationSnapshotFPS,
        bookendFrameDuration: BookendFrameDuration = .default,
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
        bookendFrameDuration: BookendFrameDuration,
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
        bookendFrameDuration: BookendFrameDuration,
        identifier: String,
        suffix: String,
        file: StaticString,
        line: UInt
    ) {
        guard let imageURL = generateAnimatedSnapshot(
            of: animationInstance,
            using: view,
            animationDuration: animationDuration,
            includeReverseCycle: includeReverseCycle,
            fps: fps,
            bookendFrameDuration: bookendFrameDuration,
            file: file,
            line: line
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
        bookendFrameDuration: BookendFrameDuration,
        identifier: String,
        suffixes: NSOrderedSet,
        file: StaticString,
        line: UInt
    ) {
        guard
            let testImageURL = generateAnimatedSnapshot(
                of: animationInstance,
                using: view,
                animationDuration: animationDuration,
                includeReverseCycle: includeReverseCycle,
                fps: fps,
                bookendFrameDuration: bookendFrameDuration,
                file: file,
                line: line
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

    private func generateAnimatedSnapshot(
        of animationInstance: AnimationInstance,
        using view: UIView,
        animationDuration: TimeInterval,
        includeReverseCycle: Bool,
        fps: Double,
        bookendFrameDuration: BookendFrameDuration,
        file: StaticString,
        line: UInt
    ) -> URL? {
        var frames: [UIImage] = []

        let forwardTimestamps = stride(from: 0, through: 1, by: (1 / (fps * animationDuration)))
        let priorForwardTimestamps = [0] + forwardTimestamps.dropLast()
        for (timestamp, priorTimestamp) in zip(forwardTimestamps, priorForwardTimestamps) {
            animationInstance.executeBlocks(
                from: priorTimestamp,
                timestamp == 0 ? .inclusive : .exclusive,
                to: timestamp
            )
            animationInstance.renderFrame(at: timestamp)

            let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
            let image = renderer.image { _ in
                view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
            }

            frames.append(image)
        }

        if includeReverseCycle {
            let reverseTimestamps = stride(from: 0, through: 1, by: (1 / (fps * animationDuration))).dropLast().reversed()
            let priorReverseTimestamps = [1] + reverseTimestamps.dropLast()
            for (timestamp, priorTimestamp) in zip(reverseTimestamps, priorReverseTimestamps) {
                animationInstance.executeBlocks(
                    from: priorTimestamp,
                    priorTimestamp == 1 ? .inclusive : .exclusive,
                    to: timestamp
                )
                animationInstance.renderFrame(at: timestamp)

                let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
                let image = renderer.image { _ in
                    view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
                }

                frames.append(image)
            }
        }

        return generateAnimatedPNG(
            from: frames,
            fps: fps,
            bookendFrameDuration: bookendFrameDuration
        )
    }

    /// Generates an animated PNG from the provided `images`. Returns the URL of the generated temporary file if
    /// successful, or `nil` otherwise.
    ///
    /// Based on <https://gist.github.com/westerlund/eae8ec71cdac88be7c3a>.
    private func generateAnimatedPNG(
        from images: [UIImage],
        fps: Double,
        bookendFrameDuration: BookendFrameDuration
    ) -> URL? {
        let fileProperties = [
            kCGImagePropertyPNGDictionary: [
                kCGImagePropertyAPNGLoopCount: 0,
            ],
        ] as CFDictionary

        let intermediateFrameDuration = (1 / fps)

        let frameProperties = [
            kCGImagePropertyPNGDictionary: [
                kCGImagePropertyAPNGUnclampedDelayTime: intermediateFrameDuration,
            ],
        ] as CFDictionary

        let firstFrameDuration: Double
        let lastFrameDuration: Double
        switch bookendFrameDuration {
        case .matchIntermediateFrames:
            firstFrameDuration = intermediateFrameDuration
            lastFrameDuration = intermediateFrameDuration

        case let .custom(firstFrameDuration: firstDuration, lastFrameDuration: lastDuration):
            firstFrameDuration = firstDuration
            lastFrameDuration = lastDuration
        }

        let firstFrameProperties = [
            kCGImagePropertyPNGDictionary: [
                kCGImagePropertyAPNGUnclampedDelayTime: firstFrameDuration,
            ],
        ] as CFDictionary

        let lastFrameProperties = [
            kCGImagePropertyPNGDictionary: [
                kCGImagePropertyAPNGUnclampedDelayTime: lastFrameDuration,
            ],
        ] as CFDictionary

        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")

        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            kUTTypePNG,
            images.count,
            nil
        ) else {
            return nil
        }

        CGImageDestinationSetProperties(destination, fileProperties)

        for (index, image) in images.enumerated() {
            guard let cgImage = image.cgImage else {
                return nil
            }

            if index == 0 {
                CGImageDestinationAddImage(destination, cgImage, firstFrameProperties)
            } else if index == images.count - 1 {
                CGImageDestinationAddImage(destination, cgImage, lastFrameProperties)
            } else {
                CGImageDestinationAddImage(destination, cgImage, frameProperties)
            }
        }

        guard CGImageDestinationFinalize(destination) else {
            return nil
        }

        return url
    }

}

// MARK: -

private final class NoOpDriver: Driver {

    // MARK: - Driver

    weak var animationInstance: DrivenAnimationInstance!

    func animationInstanceDidInitialize() {
        // No-op.
    }

    func animationInstanceDidCancel(behavior: AnimationInstance.CancelationBehavior) {
        // No-op.
    }

}
