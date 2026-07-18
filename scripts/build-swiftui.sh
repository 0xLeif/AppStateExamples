#!/usr/bin/env bash

set -euo pipefail

cd apps/SwiftUIDemo
xcodegen generate
xcodebuild build -quiet \
    -project SwiftUIDemo.xcodeproj \
    -scheme SwiftUIDemo-macOS \
    -destination 'platform=macOS' \
    -derivedDataPath .derivedData
xcodebuild build -quiet \
    -project SwiftUIDemo.xcodeproj \
    -scheme SwiftUIDemo-iOS \
    -destination 'generic/platform=iOS' \
    -derivedDataPath .derivedData \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO
