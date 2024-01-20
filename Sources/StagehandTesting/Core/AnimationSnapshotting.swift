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

import Foundation
import MobileCoreServices
import UIKit

@testable import Stagehand

public enum AnimationSnapshotting {

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

    // MARK: - Internal Static Methods

    internal static func generateAnimatedSnapshot(
        of animationInstance: AnimationInstance,
        using view: UIView,
        animationDuration: TimeInterval,
        includeReverseCycle: Bool,
        fps: Double,
        bookendFrameDuration: AnimationSnapshotting.BookendFrameDuration
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

    // MARK: - Private Static Methods

    /// Generates an animated PNG from the provided `images`. Returns the URL of the generated temporary file if
    /// successful, or `nil` otherwise.
    ///
    /// Based on <https://gist.github.com/westerlund/eae8ec71cdac88be7c3a>.
    private static func generateAnimatedPNG(
        from images: [UIImage],
        fps: Double,
        bookendFrameDuration: AnimationSnapshotting.BookendFrameDuration
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
