Pod::Spec.new do |s|
  s.name             = 'StagehandTesting'
  s.version          = '4.0.0'
  s.summary          = 'Utilities for snapshot testing animations created using the Stagehand framework'
  s.homepage         = 'https://github.com/CashApp/Stagehand'
  s.license          = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  s.author           = 'Square'
  s.source           = { :git => 'https://github.com/CashApp/Stagehand.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'

  s.swift_version = '5.0.1'

  # The dependency on Stagehand is pinned to the same version as StagehandTesting. This is because
  # StagehandTesting depends on internal methods inside Stagehand, so the normal rules of semantic
  # versioning don't apply.
  s.dependency 'Stagehand', s.version.to_s

  s.default_subspec = 'SnapshotTesting'

  s.subspec 'iOSSnapshotTestCase' do |ss|
    ss.source_files = [
      'Sources/StagehandTesting/Core/**/*.swift',
      'Sources/StagehandTesting/iOSSnapshotTestCase/**/*.swift',
    ]

    ss.dependency 'iOSSnapshotTestCase', '~> 6.1'
  end

  s.subspec 'SnapshotTesting' do |ss|
    ss.source_files = [
      'Sources/StagehandTesting/Core/**/*.swift',
      'Sources/StagehandTesting/SnapshotTesting/**/*.swift',
    ]

    ss.dependency 'SnapshotTesting', '~> 1.7'
  end

  s.frameworks = 'XCTest'
  s.weak_framework = 'XCTest'
end
