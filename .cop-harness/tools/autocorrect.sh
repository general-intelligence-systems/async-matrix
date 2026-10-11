#!/usr/bin/env bash
# Corrects a throwaway copy of the corpus with a given set of cops, and prints every corrected file,
# so that a rewritten corrector can be compared against the one it replaces.
set -o errexit -o nounset
which="$1"   # "old" or "new"
out="$2"
here="$(cd "$(dirname "$0")/.." && pwd)"

work="$here/work-$which"
rm -rf "$work"
cp -r "$here/corpus" "$work"

if [ "$which" = "old" ]; then
  sed -E 's|- \.\./\.\./cops/|- ../oldcops/|' "$here/corpus/.rubocop.yml" > "$work/.rubocop.yml"
fi

cd "$work"
bundle exec rubocop --cache false --autocorrect-all >/dev/null 2>&1 || true

: > "$out"
for f in $(find lib test -name '*.rb' | sort); do
  echo "########## $f" >> "$out"
  cat "$f" >> "$out"
done
