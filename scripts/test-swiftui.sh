#!/usr/bin/env bash

set -euo pipefail

simulator_name="${SIMULATOR_NAME:-iPhone 17 Pro}"

cd apps/SwiftUIDemo
xcodegen generate
xcodebuild test -quiet \
    -project SwiftUIDemo.xcodeproj \
    -scheme SwiftUIDemo-macOS \
    -destination "platform=macOS" \
    -derivedDataPath .derivedData
xcodebuild test -quiet \
    -project SwiftUIDemo.xcodeproj \
    -scheme SwiftUIDemo-iOS \
    -destination "platform=iOS Simulator,name=${simulator_name},OS=latest" \
    -derivedDataPath .derivedData
