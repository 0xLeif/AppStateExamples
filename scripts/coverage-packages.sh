#!/usr/bin/env bash

set -euo pipefail

package_thresholds=(
    "cli:95"
    "observability:85"
    "testing-showcase:85"
    "tui:95"
    "vapor-example:90"
    "wasm:100"
)

printf '%-22s %9s %9s %9s %10s\n' Package Lines Functions Regions Minimum
failed=0

for entry in "${package_thresholds[@]}"; do
    package="${entry%%:*}"
    minimum="${entry##*:}"
    directory="packages/${package}"
    result="$({
        cd "${directory}"
        swift test --enable-code-coverage >/dev/null
        report="$(swift test --show-codecov-path)"
        prefix="$(pwd)/Sources/"

        jq -r \
            --arg package "${package}" \
            --arg prefix "${prefix}" \
            '
                [.data[0].files[] | select(.filename | startswith($prefix)) | .summary]
                | reduce .[] as $summary (
                    {
                        lines: {count: 0, covered: 0},
                        functions: {count: 0, covered: 0},
                        regions: {count: 0, covered: 0}
                    };
                    .lines.count += $summary.lines.count
                    | .lines.covered += $summary.lines.covered
                    | .functions.count += $summary.functions.count
                    | .functions.covered += $summary.functions.covered
                    | .regions.count += $summary.regions.count
                    | .regions.covered += $summary.regions.covered
                )
                | [
                    $package,
                    ((.lines.covered * 100 / .lines.count) | tostring),
                    ((.functions.covered * 100 / .functions.count) | tostring),
                    ((.regions.covered * 100 / .regions.count) | tostring)
                ]
                | @tsv
            ' "${report}"
    })"

    IFS=$'\t' read -r name lines functions regions <<< "${result}"
    printf '%-22s %8.2f%% %8.2f%% %8.2f%% %9.2f%%\n' \
        "${name}" "${lines}" "${functions}" "${regions}" "${minimum}"

    if awk -v actual="${lines}" -v required="${minimum}" 'BEGIN { exit !(actual < required) }'; then
        printf 'Coverage failure: %s line coverage %.2f%% is below %.2f%%.\n' "${name}" "${lines}" "${minimum}" >&2
        failed=1
    fi
done

exit "${failed}"
