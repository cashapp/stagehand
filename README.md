# Stagehand

[![CI Status](https://img.shields.io/travis/CashApp/Stagehand/master.svg?style=flat)](https://travis-ci.org/CashApp/Stagehand)
[![Version](https://img.shields.io/cocoapods/v/Stagehand.svg?style=flat)](https://cocoapods.org/pods/Stagehand)
[![License](https://img.shields.io/cocoapods/l/Stagehand.svg?style=flat)](https://cocoapods.org/pods/Stagehand)
[![Platform](https://img.shields.io/cocoapods/p/Stagehand.svg?style=flat)](https://cocoapods.org/pods/Stagehand)

Stagehand provides a modern, type-safe API for building animations on iOS. Stagehand is designed around a set of core ideas:

* Composition of Structures
* Separation of Construction and Execution
* Compiler Safety
* Testability

## Installation

### CocoaPods

To install Stagehand via [CocoaPods](https://cocoapods.org), simply add the following line to your `Podfile`:

```ruby
pod 'Stagehand'
```

To install StagehandTesting, the animation snapshot testing utilities, add the following line to your test target definition in your `Podfile`:

```ruby
pod 'StagehandTesting'
```

### Swift Package Manager

To install Stagehand via [Swift Package Manager](https://github.com/apple/swift-package-manager), add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/cashapp/stagehand", from: "2.0.4"),
],
```

## Getting Started with Stagehand

An animation begins with the construction of an `Animation`. An `Animation` is generic over a type of element and acts as a definition of how that element should be animated.

As an example, we can write an animation that highlights a view by fading its alpha to 0.8 and back:

```swift
var highlightAnimation = Animation<UIView>()
highlightAnimation.addKeyframe(for: \.alpha, at: 0, value: 1)
highlightAnimation.addKeyframe(for: \.alpha, at: 0.5, value: 0.8)
highlightAnimation.addKeyframe(for: \.alpha, at: 1, value: 1)
```

Let's say we've defined a view, which we'll call `BinaryView`, that has two subviews, `leftView` and `rightView`, and we want to highlight each of the subviews in sequence. We can define an animation for our `BinaryView` with two child animations:

```swift
var binaryAnimation = Animation<BinaryView>()
binaryAnimation.addChild(highlightAnimation, for: \.leftView, startingAt: 0, relativeDuration: 0.5)
binaryAnimation.addChild(highlightAnimation, for: \.rightView, startingAt: 0.5, relativeDuration: 0.5)
```

Once we've set up our view and we're ready to execute our animation, we can call the `perform` method to start animating:

```swift
let view = BinaryView()
// ...

binaryAnimation.perform(on: view)
```

## Running the Demo App

Stagehand ships with a demo app that shows examples of many of the features provided by Stagehand. To run the demo app, open the `Example` directory and run:

```bash
bundle install
bundle exec pod install
open Stagehand.xcworkspace
```

From here, you can run the demo app and see a variety of examples for how to use the framework. In that workspace, there is also a playground that includes documentation and tutorials for how each feature works.

## Contributing

We’re glad you’re interested in Stagehand, and we’d love to see where you take it. Please read our [contributing guidelines](CONTRIBUTING.md) prior to submitting a Pull Request.

## License

```
Copyright 2020 Square, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
