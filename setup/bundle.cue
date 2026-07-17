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
				}
				hmac: "REPLACE-ME-with-32-char-hmac-secret-min"
			}
		}
	}
}
