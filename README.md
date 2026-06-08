# ory-talos timoni bundle

Timoni module + example bundle for deploying [Ory Talos](https://github.com/ory/talos)
community edition (OSS, SQLite-backed) on Kubernetes.

## Quick start

```bash
# 1. Pull the module + sample bundle
git clone https://github.com/luzilla/ory-talos-k8s
cd ory-talos-k8s

# 2. Edit bundles/ory-talos.cue: paste your real config.yaml and jwks.json.
#    (Recommended: use the @embed() workflow at the bottom of the file.)

# 3. Apply
timoni apply ory-talos oci://ghcr.io/luzilla/modules/ory-talos \
  -v v0.1.0 -n ory-talos \
  --values ./bundles/ory-talos.cue
```

> [!TIP]
> Use `timoni apply --dry-run --diff` to preview changes.

## What gets deployed

| Object | Name | Notes |
| --- | --- | --- |
| StatefulSet | `ory-talos` | 1 replica. db-init initContainer runs migrations on every start. |
| Service | `ory-talos` | ClusterIP, port `http: 4420`. |
| Service | `ory-talos-headless` | Required by the StatefulSet. |
| ConfigMap | `ory-talos-config` | `config.yaml`. |
| Secret | `ory-talos-jwks` | `jwks.json`. |
| PVC | `data-ory-talos-0` | Provisioned by `volumeClaimTemplates`. |

## Verifying the signature

Releases are signed with cosign keyless via GitHub Actions OIDC.

```bash
cosign verify ghcr.io/luzilla/modules/ory-talos:v0.1.0 \
  --certificate-identity-regexp '^https://github.com/luzilla/ory-talos-k8s/.*' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

> [!IMPORTANT]
> **Migrations run on every pod start.** This is a single-pod SQLite
> deployment; the `db-init` initContainer calls `talos migrate sql up` on
> every start. Ory SQL migrations are idempotent so the post-first-run
> calls are no-ops. If a node reboots mid-migration, WAL recovery is on
> you.

## Local development

```bash
make help       # list targets
make lint       # cue fmt --check + cue vet
make build      # render to dist/manifests.yaml
make test       # mod vet + bundle vet + JSON Schema + goldens + kubeconform
make run-dev    # timoni apply against current kube-context
```

## License

Apache License 2.0 — see [LICENSE](./LICENSE).
