# utils/litestream

A CUE library for embedding a [Litestream](https://litestream.io) sidecar in
another module's pod spec. Replicates a single SQLite file to an
S3-compatible store.

Published to the CUE Central Registry as
`github.com/luzilla/ory-talos-k8s/utils/litestream`.

## What this is — and isn't

This is a **CUE library**, not a workload module. It deploys nothing on
its own — it exports definitions you compose into your own pod spec.

The reason: Litestream needs filesystem access to the SQLite file, so it
must run in the same pod as the database writer. A standalone module
cannot achieve that.

## Install

```sh
cue mod get github.com/luzilla/ory-talos-k8s/utils/litestream@v0
```

## Import

```cue
import litestream "github.com/luzilla/ory-talos-k8s/utils/litestream/litestream"
```

## Definitions

| Definition | What it is |
|---|---|
| `#Config` | User-facing schema (image, dbPath, replica, credentials, resources, securityContext). |
| `#Names` | Shared naming contract (`configMap`, `secret`) so consumer and library agree on resource names. |
| `#ConfigMap` | Renders the Litestream `litestream.yml` ConfigMap. |
| `#Secret` | Renders an Opaque Secret with `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`. |
| `#Sidecar` | `corev1.#Container` with `restartPolicy: Always` — place in `initContainers` for the native-sidecar form (k8s 1.29+). |
| `#ConfigVolume` | `corev1.#Volume` that mounts the rendered ConfigMap into the sidecar. |

## Limits

- AWS-compatible replicas only (S3, R2, MinIO via custom endpoint).
- One database per Litestream config — multi-DB pods can call the library
  multiple times with different names.
- No `#Restore` initContainer yet — a fresh pod will not automatically
  rehydrate from S3. Add that yourself if you need it.

## Dependencies

- `cue.dev/x/k8s.io/api/core/v1` (resolved via `cue mod tidy`)

## Publish

Tag with the prefix `utils/litestream/` and push:

```sh
git tag utils/litestream/v0.1.0
git push origin utils/litestream/v0.1.0
```

The `.github/workflows/publish-utils-litestream.yml` workflow runs
`cue mod tidy && cue vet && cue mod publish` against the CUE Central
Registry, authenticated via GitHub OIDC (no PAT required).
