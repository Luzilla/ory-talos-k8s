#!/usr/bin/env bash
# Validate the rendered talos config.yaml inside a manifests file against
# upstream's published JSON Schema.
#
# Usage: validate-talos-config.sh <manifests.yaml>
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <manifests-file>" >&2
  exit 2
fi
MANIFESTS="$1"

# Pinned to the same image tag the module uses. Bump together with the
# image digest in values.cue.
TALOS_REF="${TALOS_REF:-v26.2.0}"
SCHEMA_URL="https://raw.githubusercontent.com/ory/talos/${TALOS_REF}/spec/config.schema.json"

SCHEMA="${TMPDIR:-/tmp}/talos-config.schema.json"
CONFIG="${TMPDIR:-/tmp}/talos-config.json"

curl -fsSL "$SCHEMA_URL" -o "$SCHEMA"

# Extract the ConfigMap-rendered config.yaml string, then convert YAML -> JSON.
# Selects by data key, not by name — object names carry a content hash now
# (see timoniv1.#ImmutableConfig), so name-based selection is unreliable.
yq eval-all '
  select(.kind == "ConfigMap" and .data["config.yaml"] != null).data["config.yaml"]
' "$MANIFESTS" | yq -p=yaml -o=json > "$CONFIG"

if ! command -v npx >/dev/null 2>&1; then
  echo "npx not found — install Node.js (>= 18) to run ajv-cli" >&2
  exit 1
fi

npx --yes ajv-cli@5 validate \
  -s "$SCHEMA" \
  -d "$CONFIG" \
  --strict=false --all-errors
