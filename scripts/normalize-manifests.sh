#!/usr/bin/env bash
# Strip volatile labels/annotations from a rendered manifest so golden
# diffs are stable across timoni / module-version bumps.
#
# Usage: normalize-manifests.sh <path>
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <manifest-file>" >&2
  exit 2
fi

yq eval '
  del(.metadata.labels."app.kubernetes.io/version") |
  del(.metadata.labels."app.kubernetes.io/managed-by") |
  del(.metadata.annotations."instance.timoni.sh/name") |
  del(.metadata.annotations."instance.timoni.sh/namespace") |
  del(.spec.template.metadata.labels."app.kubernetes.io/version") |
  del(.spec.selector.matchLabels."app.kubernetes.io/version")
' "$1"
