#!/usr/bin/env bash

set -euo pipefail

build() {
    local directory="$1"
    local project="$2"
    local scheme="$3"
    local destination="$4"

    (
        cd "${directory}"
        xcodegen generate
        xcodebuild build -quiet \
            -project "${project}" \
            -scheme "${scheme}" \
            -destination "${destination}" \
            -derivedDataPath .derivedData \
            CODE_SIGNING_ALLOWED=NO \
            CODE_SIGNING_REQUIRED=NO
    )
}

build apps/MenuBarDemo MenuBarDemo.xcodeproj MenuBarDemo 'platform=macOS'
build apps/Pomodoro Pomodoro.xcodeproj Pomodoro-macOS 'platform=macOS'
build apps/Pomodoro Pomodoro.xcodeproj Pomodoro-iOS 'generic/platform=iOS'
build apps/WidgetDemo WidgetDemo.xcodeproj WidgetDemo 'generic/platform=iOS'
