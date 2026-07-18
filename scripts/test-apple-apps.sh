#!/usr/bin/env bash

set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
simulator_name="${SIMULATOR_NAME:-iPhone 17 Pro}"
run_stamp="$(date +%Y%m%d-%H%M%S)-$$"

enforce_coverage() {
    local result_path="$1"
    local target_name="$2"
    local minimum="$3"
    local coverage_json
    local line_coverage

    xcrun xccov view --report --only-targets "${result_path}"
    coverage_json="$(xcrun xccov view --report --json "${result_path}")"
    line_coverage="$(jq -r --arg target "${target_name}" '
        .targets[] | select(.name == $target) | .lineCoverage * 100
    ' <<< "${coverage_json}")"

    printf '%s line coverage: %.2f%% (minimum %.2f%%)\n' "${target_name}" "${line_coverage}" "${minimum}"
    if awk -v actual="${line_coverage}" -v required="${minimum}" 'BEGIN { exit !(actual < required) }'; then
        printf 'Coverage failure: %s line coverage %.2f%% is below %.2f%%.\n' \
            "${target_name}" "${line_coverage}" "${minimum}" >&2
        exit 1
    fi
}

run_menu_bar() (
    cd "${root_dir}/apps/MenuBarDemo"
    local result_path="TestResults/coverage-${run_stamp}.xcresult"
    xcodegen generate
    mkdir -p TestResults
    xcodebuild test -quiet \
        -project MenuBarDemo.xcodeproj \
        -scheme MenuBarDemo \
        -destination "platform=macOS" \
        -derivedDataPath .derivedData \
        -resultBundlePath "${result_path}" \
        -enableCodeCoverage YES
    enforce_coverage "${result_path}" "MenuBarDemo.app" "${MENUBAR_COVERAGE_MINIMUM:-85}"
)

run_pomodoro() (
    cd "${root_dir}/apps/Pomodoro"
    local result_path="TestResults/coverage-${run_stamp}.xcresult"
    xcodegen generate
    mkdir -p TestResults
    xcodebuild test -quiet \
        -project Pomodoro.xcodeproj \
        -scheme Pomodoro-iOS \
        -destination "platform=iOS Simulator,name=${simulator_name},OS=latest" \
        -derivedDataPath .derivedData \
        -resultBundlePath "${result_path}" \
        -enableCodeCoverage YES
    enforce_coverage "${result_path}" "Pomodoro.app" "${POMODORO_COVERAGE_MINIMUM:-95}"
)

run_widget() (
    cd "${root_dir}/apps/WidgetDemo"
    local result_path="TestResults/coverage-${run_stamp}.xcresult"
    xcodegen generate
    mkdir -p TestResults
    xcodebuild test -quiet \
        -project WidgetDemo.xcodeproj \
        -scheme WidgetDemo \
        -destination "platform=iOS Simulator,name=${simulator_name},OS=latest" \
        -derivedDataPath .derivedData \
        -resultBundlePath "${result_path}" \
        -enableCodeCoverage YES
    enforce_coverage "${result_path}" "WidgetDemo.app" "${WIDGET_APP_COVERAGE_MINIMUM:-95}"
    enforce_coverage "${result_path}" "WidgetDemoCore.framework" "${WIDGET_CORE_COVERAGE_MINIMUM:-95}"
)

run_menu_bar
run_pomodoro
run_widget
