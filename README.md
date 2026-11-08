# OPENMXC

A minimal, native macOS web browser built with Swift, SwiftUI, AppKit and Apple WebKit.

## Requirements

- macOS 14.0 or later
- Xcode 26 or later

## Building

The Xcode project is generated from `project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
xcodegen generate
open OpenMxc.xcodeproj
```

Or build from the command line:

```sh
xcodebuild -project OpenMxc.xcodeproj -scheme OpenMxc -configuration Debug build
```

## Layout

- `project.yml` — project definition (source of truth)
- `OpenMxc/` — application sources
- `OpenMxcTests/` — unit tests
