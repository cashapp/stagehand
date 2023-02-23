#!/usr/bin/env swift

import Foundation

enum TaskError: Error {
    case code(Int32)
}

guard CommandLine.arguments.count > 2 else {
	print("Usage: rename-snapshots.swift <old_version> <new_version>")
	throw TaskError.code(1)
}

let rawFromVersion = CommandLine.arguments[1]
let rawToVersion = CommandLine.arguments[2]

let fromVersionA = rawFromVersion.replacingOccurrences(of: ".", with: "_")
let fromVersionB = rawFromVersion.replacingOccurrences(of: ".", with: "-")
let toVersionA = rawToVersion.replacingOccurrences(of: ".", with: "_")
let toVersionB = rawToVersion.replacingOccurrences(of: ".", with: "-")

let fileManager = FileManager.default
let currentDirectoryPath: NSString = fileManager.currentDirectoryPath as NSString

let referenceImageDirectoryPaths = [
    currentDirectoryPath.appendingPathComponent("Example/Unit Tests/__Snapshots__"),
    currentDirectoryPath.appendingPathComponent("Example/Unit Tests/ReferenceImages"),
]

for referenceImageDirectoryPath in referenceImageDirectoryPaths {
    guard let enumerator = fileManager.enumerator(atPath: referenceImageDirectoryPath) else {
        print("Invalid reference image directory path: \(referenceImageDirectoryPath)")
        throw TaskError.code(1)
    }

    while let filePath = enumerator.nextObject() as? String {
        guard filePath.hasSuffix(".png") else { continue }

        let fullPath = (referenceImageDirectoryPath as NSString).appendingPathComponent(filePath) as String

        let newPath = fullPath
            .replacingOccurrences(of: fromVersionA, with: toVersionA)
            .replacingOccurrences(of: fromVersionB, with: toVersionB)

        try fileManager.moveItem(
            atPath: fullPath,
            toPath: newPath
        )
    }
}
