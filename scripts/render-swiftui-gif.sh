#!/usr/bin/env bash

set -euo pipefail

output="docs/assets/swiftui/appstate-3-swiftui-tour.gif"

ffmpeg -hide_banner -loglevel error -y \
    -framerate 1 \
    -pattern_type glob \
    -i 'docs/assets/swiftui/0*.png' \
    -vf "scale=414:-1:flags=lanczos,split[frames][palette];[palette]palettegen=max_colors=128[p];[frames][p]paletteuse=dither=bayer:bayer_scale=4" \
    -loop 0 \
    "${output}"

echo "Rendered ${output}"
