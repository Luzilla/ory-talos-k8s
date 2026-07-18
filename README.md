# ory-talos timoni bundle

Timoni module + example bundle for deploying [Ory Talos](https://github.com/ory/talos)
community edition (OSS, SQLite-backed) on Kubernetes.

## Quick start

The module is published to GHCR. Point `timoni` straight at it — no
clone required.

```bash
timoni apply ory-talos oci://ghcr.io/luzilla/modules/ory-talos \
  -v 0.2.0 -n ory-talos \
  --values ./values.cue
```

Your `values.cue` needs, at minimum:

- `config.credentials.issuer` — the `iss` claim stamped into derived
  tokens. A stable URL that identifies this instance; internal DNS is
  fine (e.g. `https://talos.svc.cluster.local`). Only needs to be
  publicly reachable if external verifiers will fetch JWKS from it.
- `config.db.dsn` — the SQLite DSN.
- `hmac` — a >=32 char secret.

See [`setup/bundle.cue`](./setup/bundle.cue) for a working example and
[`setup/bundle-litestream.cue`](./setup/bundle-litestream.cue) for the
litestream sidecar variant.

> [!TIP]
> Use `timoni apply --dry-run --diff` to preview changes.

## What gets deployed

| Object | Name | Notes |
| --- | --- | --- |
| StatefulSet | `ory-talos` | 1 replica. db-init initContainer runs migrations on every start. |
| Service | `ory-talos` | ClusterIP, port `http: 4420`. |
| Service | `ory-talos-headless` | Required by the StatefulSet. |
| ConfigMap | `ory-talos-config-<hash>` | `config.yaml`. Hashed name forces a rolling restart on change. |
| Secret | `ory-talos-hmac-<hash>` | `SECRETS_HMAC_CURRENT` and, when set, `SECRETS_HMAC_RETIRED`. Injected via `envFrom`. |
| Secret | `ory-talos-jwks-<hash>` | `jwks.json`. Only rendered when `values.jwks` is set (optional; needed for derived tokens). |
| PVC | `data-ory-talos-0` | Provisioned by `volumeClaimTemplates`. |

## Verifying the signature

Releases are signed with cosign keyless via GitHub Actions OIDC.

```bash
cosign verify ghcr.io/luzilla/modules/ory-talos:0.2.0 \
  --certificate-identity-regexp '^https://github.com/luzilla/ory-talos-k8s/.*' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

> [!IMPORTANT]
> **Migrations run on every pod start.** This is a single-pod SQLite
> deployment; the `db-init` initContainer calls `talos migrate up` on
> every start. Ory SQL migrations are idempotent so the post-first-run
> calls are no-ops. If a node reboots mid-migration, WAL recovery is on
> you.

## Local development

```bash
make help                 # list targets
make lint                 # cue fmt --check + cue vet
make build                # render to dist/manifests.yaml
make test                 # mod vet + bundle vet + JSON Schema + goldens + kubeconform
make run-dev              # timoni apply against current kube-context
make run-dev-litestream   # same, with the litestream sidecar (needs ACCESS_KEY_ID + SECRET_ACCESS_KEY)
```

## License

Apache License 2.0 — see [LICENSE](./LICENSE).
