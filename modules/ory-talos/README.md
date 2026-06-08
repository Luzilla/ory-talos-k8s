# ory-talos module

CUE module for timoni.sh that deploys [Ory Talos](https://github.com/ory/talos) OSS to Kubernetes.

See the top-level repo `README.md` for the bundle, usage, and CI details.

## Configuration

User-tunable values are in `templates/config.cue` (schema) and `values.cue`
(defaults). Required: `config` (talos `config.yaml` body) and `jwks`
(`jwks.json` body).

See [docs/bundles](https://github.com/Luzilla/ory-talos-k8s/tree/main/docs/bundles) for an example.
