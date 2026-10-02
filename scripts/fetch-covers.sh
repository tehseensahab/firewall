#!/usr/bin/env bash
# Downloads every cover listed in scripts/covers.tsv into its post bundle as cover.jpg.
# Columns (tab-separated): post-slug, images.unsplash.com photo id, unsplash page id, alt, photographer.
# Existing covers are kept; pass --force to re-download.
set -uo pipefail
cd "$(dirname "$0")/.."
force=${1:-}
fail=0
while IFS=$'\t' read -r slug photo page _alt _credit; do
  [ -n "$slug" ] || continue
  dir="content/posts/$slug"; out="$dir/cover.jpg"
  [ -d "$dir" ] || { echo "MISSING POST  $slug"; fail=1; continue; }
  [ -f "$out" ] && [ "$force" != "--force" ] && continue
  tmp=$(mktemp)
  ok=0
  for url in \
    "https://images.unsplash.com/photo-$photo?w=1600&q=80&fm=jpg&fit=max" \
    "https://unsplash.com/photos/$page/download?force=true&w=1600"; do
    if curl -fsSL --retry 2 -m 60 -A "Mozilla/5.0" "$url" -o "$tmp" \
       && file -b --mime-type "$tmp" | grep -q '^image/jpeg$' \
       && [ "$(stat -c%s "$tmp")" -gt 20000 ]; then ok=1; break; fi
  done
  if [ $ok -eq 1 ]; then mv "$tmp" "$out"; chmod 644 "$out"; echo "ok       $slug"
  else rm -f "$tmp"; echo "FAILED   $slug ($photo / $page)"; fail=1; fi
done < scripts/covers.tsv
exit $fail
