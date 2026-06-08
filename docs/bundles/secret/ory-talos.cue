// Example bundle that loads config + jwks from local files via CUE @embed.
// Put real files alongside this one at ./config.yaml and ./jwks.json.
@extern(embed)

_configYAML: string @embed(file=config.yaml)
_jwksJSON:   string @embed(file=jwks.json)

bundle: {
	apiVersion: "v1alpha1"
	name:       "ory-talos"
	instances: {
		"ory-talos": {
			module: {
				url:     "oci://ghcr.io/luzilla/modules/ory-talos"
				version: "v0.1.0"
			}
			namespace: "ory-talos"
			values: {
				config: _configYAML
				jwks:   _jwksJSON
			}
		}
	}
}
