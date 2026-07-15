// Inline example bundle for the ory-talos timoni module.
// config + jwks are pasted directly. Fine for throwaway / local dev.
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
				config: {
					log: {
						level:  "info"
						format: "json"
					}
					serve: http: {
						host: "0.0.0.0"
						port: 4420
					}
					db: dsn: "sqlite3:///var/lib/talos/talos.db?_journal_mode=WAL"
					credentials: {
						issuer: "https://api.talos.local"
						api_keys: {
							default_ttl: "720h"
							max_ttl:     "8760h"
							prefix: current: "talos"
						}
					}
					secrets: hmac: current: "REPLACE-ME-with-32-char-hmac-secret-min"
				}
				jwks: """
					{"keys":[{"kty":"oct","kid":"replace-me","alg":"HS256","k":"replace-me"}]}
					"""

				// Uncomment to enable the Litestream sidecar. The library's
				// `valid` gate requires enabled + bucket + region + creds,
				// so all four must be present or nothing renders.
				// endpoint is optional — leave empty for AWS S3, or set it
				// for R2 / MinIO / another S3-compatible store. MinIO also
				// needs forcePathStyle: true.
				// litestream: {
				//   enabled: true
				//   replica: {
				//     bucket:         "talos-backups-dev"
				//     region:         "whatever"
				//     endpoint:       "https://s3.example.org"
				//     forcePathStyle: true
				//   }
				//   credentials: {
				//     accessKeyId:     "REPLACE-ME"
				//     secretAccessKey: "REPLACE-ME"
				//   }
				// }
			}
		}
	}
}
