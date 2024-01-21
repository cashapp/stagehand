Pod::Spec.new do |s|
  s.name             = 'Stagehand'
  s.version          = '5.0.0'
  s.summary          = 'Modern, type-safe API for building animations on iOS'
  s.homepage         = 'https://github.com/CashApp/Stagehand'
  s.license          = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  s.author           = 'Square'
  s.source           = { :git => 'https://github.com/CashApp/Stagehand.git', :tag => s.version.to_s }

  s.ios.deployment_target = '14.0'

  s.swift_version = '5.8'

  s.source_files = 'Sources/Stagehand/**/*'

  s.frameworks = 'CoreGraphics', 'UIKit'

  # In order for StagehandTesting to publish correctly, we need to allow Stagehand to be accessible
  # using `@testable import`. This allows StagehandTesting to build using a RELEASE config.
  s.pod_target_xcconfig = {
    'ENABLE_TESTABILITY' => 'YES'
  }
end
