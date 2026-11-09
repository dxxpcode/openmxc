# OPENMXC

A minimal, native macOS web browser built with Swift, SwiftUI, AppKit and Apple WebKit.

## Requirements

- macOS 14.0 or later
- Xcode 26 or later

## Building

The Xcode project is generated from `project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
xcodegen generate
open openmxc.xcodeproj
```

Or build from the command line:

```sh
xcodebuild -project openmxc.xcodeproj -scheme openmxc -configuration Debug build
```

## Layout

- `project.yml` — project definition (source of truth)
- `openmxc/` — application sources
- `openmxcTests/` — unit tests
