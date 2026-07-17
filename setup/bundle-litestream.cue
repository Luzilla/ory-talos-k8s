// Dev bundle for `make run-dev-litestream`. Enables litestream and
// pulls credentials from the environment via timoni runtime tags.
//
// Apply with:
//   make run-dev-litestream
//
// Required env vars (see ../.envrc-dist):
//   ACCESS_KEY_ID
//   SECRET_ACCESS_KEY

bundle: {
	apiVersion: "v1alpha1"
	name:       "ory-talos"
	instances: {
		"ory-talos": {
			module: url: "file://../modules/ory-talos"
			namespace: "ory-talos"
			values: {
				config: {
					log: {
						level:  "warn"
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
				}
				hmac: "docker-compose-hmac-secret-minimum-32-chars-long"

				litestream: {
					enabled: true
					logging: {
						level: "warn"
						type:  "json"
					}
					replica: {
						bucket:         "ory-talos"
						path:           "dev/talos"
						region:         "us-east-1"
						endpoint:       "https://s3.storage.planetary-networks.de/"
						forcePathStyle: true
					}
					credentials: {
						accessKeyId:     string @timoni(runtime:string:ACCESS_KEY_ID)
						secretAccessKey: string @timoni(runtime:string:SECRET_ACCESS_KEY)
					}
				}
			}
		}
	}
}
