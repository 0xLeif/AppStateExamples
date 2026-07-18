#!/usr/bin/env bash

set -euo pipefail

packages=(
    cli
    observability
    testing-showcase
    tui
    vapor-example
    wasm
)

for package in "${packages[@]}"; do
    echo "Testing packages/${package}"
    (
        cd "packages/${package}"
        swift test
    )
done
