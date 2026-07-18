// Golden fixture: base config from golden-values.cue plus a fully-populated
// litestream block with hardcoded fake creds/bucket so the render is
// deterministic and reproducible on every CI run.
package main

values: {
	config: {
		serve: http: {
			host: "0.0.0.0"
			port: 4420
			request_log: exclude_health_endpoints: true
			cors: {
				enabled: true
				allowed_origins: ["http://localhost:3001"]
				allowed_methods: ["GET", "POST", "PUT", "DELETE", "PATCH"]
				allowed_headers: ["Content-Type", "Authorization"]
				exposed_headers: ["Content-Type"]
				allow_credentials: true
				max_age:           86400
				debug:             false
			}
		}

		credentials: {
			issuer: "https://api.talos.local"
			api_keys: {
				default_ttl: "720h"
				max_ttl:     "8760h"
				prefix: {
					current: "talos"
					retired: []
				}
			}
			derived_tokens: {
				default_ttl: "1h"
				jwt: signing_keys: urls: [
					"base64://eyAgImtleXMiOiBbICAgIHsgICAgICAiYWxnIjogIkVkRFNBIiwgICAgICAiY3J2IjogIkVkMjU1MTkiLCAgICAgICJkIjogIjl3VTNfV3p0dmx3TXg0SGlfN2dsSVduY09XNlVIR2I5amxDdDZEZkVGa2MiLCAgICAgICJraWQiOiAiZG9ja2VyLWRldi0wMDEiLCAgICAgICJrdHkiOiAiT0tQIiwgICAgICAidXNlIjogInNpZyIsICAgICAgIngiOiAiNGtTQTdtNU5jYnFDUC1mZk9fNGhQM2tsNHB0NGctLTNRQ21zQmwzb05lVSIgICAgfSAgXX0=",
				]
				macaroon: prefix: {
					current: "mc"
					retired: []
				}
			}
		}

		db: dsn: "sqlite3:///var/lib/talos/talos.db?_journal_mode=WAL"

		log: {
			level:  "info"
			format: "json"
		}
	}

	hmac: "docker-compose-hmac-secret-minimum-32-chars-long"

	hmacRetired: [
		"previous-hmac-secret-minimum-32-chars-long",
		"older-hmac-secret-minimum-32-chars-long-a",
	]

	jwks: """
		{
		  "keys": [
		    {
		      "kty": "RSA",
		      "kid": "test-key-1",
		      "use": "sig",
		      "alg": "RS256",
		      "n": "0vx7agoebGcQSuuPiLJXZptN9nndrQmbXEps2aiAFbWhM78LhWx4cbbfAAtVT86zwu1RK7aPFFxuhDR1L6tSoc_BJECPebWKRXjBZCiFV4n3oknjhMstn64tZ_2W-5JsGY4Hc5n9yBXArwl93lqt7_RN5w6Cf0h4QyQ5v-65YGjQR0_FDW2QvzqY368QQMicAtaSqzs8KJZgnYb9c7d0zgdAZHzu6qMQvRL5hajrn1n91CbOpbISD08qNLyrdkt-bFTWhAI4vMQFh6WeZu0fM4lFd2NcRwr3XPksINHaQ-G_xBniIqbw0Ls1jF44-csFCur-kEgU8awapJzKnqDKgw",
		      "e": "AQAB"
		    }
		  ]
		}
		"""

	persistence: size: "1Gi"

	litestream: {
		enabled: true
		logging: {
			level: "warn"
			type:  "pretty"
		}
		replica: {
			bucket:         "talos-backups-dev"
			path:           "ory/talos"
			region:         "eu-central-1"
			endpoint:       "https://s3.example.org"
			forcePathStyle: true
		}
		credentials: {
			accessKeyId:     "AKIAEXAMPLE"
			secretAccessKey: "test-secret"
		}
	}
}
