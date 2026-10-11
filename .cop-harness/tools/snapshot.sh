#!/usr/bin/env bash
# Records what every custom cop reports on the fixture corpus, as a stable text snapshot.
set -o errexit -o nounset
out="$1"
cd "$(dirname "$0")/../corpus"
: > "$out"
for cop in Local/BeginBlockAssignment Local/NoConditionalAssignment Local/NoModifierIf \
           Local/NoReturn Local/UseTap Local/CommentStructure Local/SingleLineMethodsForEvents \
           AsyncMatrix/AbstractModuleVersionOrder AsyncMatrix/AbstractModuleNoChangesComment \
           AsyncMatrix/EachFileHasMatchingTest; do
  echo "########## $cop" >> "$out"
  bundle exec rubocop --cache false --only "$cop" --format emacs . 2>&1 \
    | sed -E "s|^.*/corpus/||" \
    | grep -E ':[0-9]+:[0-9]+: [A-Z]:' \
    | sort >> "$out" || true
done
