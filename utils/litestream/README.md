# utils/litestream

A CUE library for embedding a [Litestream](https://litestream.io)
sidecar in another module's pod spec. Replicates a single SQLite
database to an S3-compatible store.

Published to the CUE Central Registry as
`github.com/luzilla/ory-talos-k8s/utils/litestream`.

## What this is

This is a **CUE library** which exports definitions you compose into your
own pod spec.

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
| `#Sidecar` | `corev1.#Container` with `restartPolicy: Always` — place in `initContainers` for the native-sidecar form (k8s 1.29+). Exposes the litestream `:9090` metrics port (named `metrics`) and probes `/metrics` for liveness and readiness. |
| `#Restore` | One-shot `corev1.#Container` that runs `litestream restore` with `-if-db-not-exists` and `-if-replica-exists`. Place in `initContainers` *before* any container that reads the DB. Idempotent: no-op on an existing volume, no-op on an empty replica. |
| `#ConfigVolume` | `corev1.#Volume` that mounts the rendered ConfigMap into the sidecar. |

## Limits

- AWS-compatible replicas only (S3, R2, MinIO via custom endpoint).
- One database per Litestream config.

## Dependencies

- `cue.dev/x/k8s.io/api/core/v1` (resolved via `cue mod tidy`)

## Publish

Tag with the prefix `utils/litestream/` and push:

```sh
make release TAG=v0.1.0
```

The [`.publish-utils-litestream.yml`](../../.github/workflows/publish-utils-litestream.yml) workflow publishes the module to the CUE Central Registry.
