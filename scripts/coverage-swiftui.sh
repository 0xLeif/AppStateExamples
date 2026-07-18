#!/usr/bin/env bash

set -euo pipefail

simulator_name="${SIMULATOR_NAME:-iPhone 17 Pro}"
result_path="${COVERAGE_RESULT_PATH:-TestResults/coverage-$(date +%Y%m%d-%H%M%S).xcresult}"
minimum="${SWIFTUI_COVERAGE_MINIMUM:-95}"

cd apps/SwiftUIDemo
xcodegen generate
mkdir -p TestResults

xcodebuild test -quiet \
    -project SwiftUIDemo.xcodeproj \
    -scheme SwiftUIDemo-iOS \
    -destination "platform=iOS Simulator,name=${simulator_name},OS=latest" \
    -derivedDataPath .derivedData \
    -resultBundlePath "${result_path}" \
    -enableCodeCoverage YES

xcrun xccov view --report --only-targets "${result_path}"

coverage_json="$(xcrun xccov view --report --json "${result_path}")"
line_coverage="$(jq -r '
    .targets[]
    | select(.name == "SwiftUIDemo.app")
    | .lineCoverage * 100
' <<< "${coverage_json}")"

if [[ -z "${line_coverage}" ]]; then
    printf 'Coverage failure: SwiftUIDemo.app was not present in %s.\n' "${result_path}" >&2
    exit 1
fi

printf 'SwiftUIDemo.app line coverage: %.2f%% (minimum %.2f%%)\n' "${line_coverage}" "${minimum}"
if awk -v actual="${line_coverage}" -v required="${minimum}" 'BEGIN { exit !(actual < required) }'; then
    printf 'Coverage failure: SwiftUIDemo.app line coverage %.2f%% is below %.2f%%.\n' \
        "${line_coverage}" "${minimum}" >&2
    exit 1
fi
