#!/usr/bin/env bash
# Usage: scripts/cover.sh <image-url> <post-dir>
# Downloads an image into <post-dir>/cover.jpg, downscaled to max 2400px wide.
set -euo pipefail
[ $# -eq 2 ] || { echo "Usage: $0 <image-url> <post-dir>" >&2; exit 1; }
url=$1; dir=$2
[ -d "$dir" ] || { echo "Post directory not found: $dir" >&2; exit 1; }
out="$dir/cover.jpg"
curl -fsSL "$url" -o "$out"
mogrify -format jpg -resize '2400x>' -quality 85 "$out"
echo "Saved $out"
