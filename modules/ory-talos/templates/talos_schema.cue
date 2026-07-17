// Ory Talos Configuration
//
// Configuration schema for Ory Talos (OSS).
package templates

import (
	"strings"
	"net"
	"list"
)

#TalosConfig: {
	@jsonschema(id="https://github.com/ory/talos/config.schema.json")
	close({
		// Server configuration for HTTP and metrics endpoints
		serve?: close({
			// HTTP server configuration. Host and port require restart; CORS,
			// client IP source, and request logging are hot-reloadable.
			http?: close({
				request_log?: close({
					// Exclude health endpoints from request logging
					//
					// Exclude /health/alive and /health/ready endpoints from request
					// logs
					exclude_health_endpoints?: bool
				})

				// Host
				//
				// The host (interface) that the endpoint listens on. Immutable:
				// requires server restart to change.
				host?: string

				// Port
				//
				// The port that the endpoint listens on. Immutable: requires
				// server restart to change.
				port?: int & >=1 & <=65535

				// Cross Origin Resource Sharing (CORS)
				//
				// Configure [Cross Origin Resource Sharing
				// (CORS)](http://www.w3.org/TR/cors/) using the following
				// options.
				cors?: _#defs."/properties/serve/properties/http/properties/cors"

				// Client IP Source
				//
				// Determines which HTTP header or connection property is used to
				// resolve the client IP for IP restriction checks. Must match
				// your infrastructure topology. Default (unspecified) uses the
				// TCP remote address. Hot-reloadable: read dynamically per
				// request.
				client_ip_source?: "CLIENT_IP_SOURCE_UNSPECIFIED" | "CLIENT_IP_SOURCE_REMOTE_ADDR" | "CLIENT_IP_SOURCE_CF_CONNECTING_IP" | "CLIENT_IP_SOURCE_X_FORWARDED_FOR" | "CLIENT_IP_SOURCE_X_REAL_IP" | "CLIENT_IP_SOURCE_TRUE_CLIENT_IP"

				// Trust X-Forwarded-Host
				//
				// Trust the X-Forwarded-Host header for tenant routing. Only
				// enable when Talos runs behind a reverse proxy that strips or
				// overwrites this header from untrusted clients.
				trust_forwarded_host?: bool
			})
		})

		// Credential configuration for API keys and derived tokens (JWT,
		// macaroon)
		credentials!: close({
			// Token issuer (iss claim) for derived tokens. REQUIRED. Should
			// be a stable URL identifying this deployment (e.g.,
			// https://api.example.com).
			issuer!: strings.MinRunes(1)

			// Retired issuer URLs accepted during token verification. Tokens
			// signed with these issuers remain valid but new tokens use the
			// current issuer.
			issuer_retired?: [...strings.MinRunes(1)]

			// Maximum clock skew tolerance for timestamp and token
			// validation. Accepts Go duration format (e.g., 5m, 30s).
			// Maximum 600s (10m). Defaults to 5m.
			clock_skew?: string

			// API key configuration
			api_keys?: close({
				// Default API key TTL (duration string). When not set, keys have
				// no expiry by default.
				default_ttl?: =~"^(\\d+(\\.\\d+)?(ns|us|µs|ms|s|m|h))+$"

				// Maximum age for API keys with timestamps. Keys older than this
				// are rejected. Format: Go duration (e.g., '24h', '168h',
				// '8760h')
				max_ttl?: =~"^(\\d+(\\.\\d+)?(ns|us|µs|ms|s|m|h))+$"

				// API key prefix configuration for key generation and
				// verification
				prefix?: close({
					// Current prefix used for new API key generation. Must be 1-16
					// alphanumeric characters or underscores.
					current?: =~"^[a-zA-Z0-9_]{1,16}$"

					// Retired prefixes accepted during verification for migration
					// purposes. Keys with these prefixes will still verify but new
					// keys use 'current'.
					retired?: [...=~"^[a-zA-Z0-9_]{1,16}$"]

					// Current prefix used for new PUBLIC API key generation. Must be
					// 1-16 alphanumeric characters or underscores. If not
					// configured, issuing public keys returns an error.
					public_current?: =~"^[a-zA-Z0-9_]{1,16}$"

					// Retired public prefixes accepted during verification for
					// migration purposes.
					public_retired?: [...=~"^[a-zA-Z0-9_]{1,16}$"]
				})
			})

			// Derived token configuration for JWT and macaroon tokens
			derived_tokens?: close({
				// Default derived token TTL applied to both JWT and macaroon
				// tokens when no explicit TTL is provided in the request
				// (duration string)
				default_ttl?: =~"^(\\d+(\\.\\d+)?(ns|us|µs|ms|s|m|h))+$"

				// JWT token configuration
				jwt?: close({
					// Optional JWK 'kid' hint used to select the active signing key.
					// When set, derived JWTs are signed with the key whose 'kid'
					// matches and signing fails if no such key exists. When unset,
					// the first key with use="sig" is selected, falling back to the
					// first key in the set.
					signing_key_id?: string

					// Signing keys configuration for JWT token generation
					signing_keys?: close({
						// List of JWKS resources. Only base64:// literals are accepted
						// (e.g. "base64://<base64-encoded-jwks>"). Other schemes
						// (file://, https://, http://) are rejected by the Ory Network
						// platform.
						urls?: [...net.AbsURL & =~"^base64://"]
					})
				})

				// Macaroon token configuration
				macaroon?: close({
					// Macaroon token prefix configuration for generation and
					// verification
					prefix?: close({
						// Current prefix used for new macaroon token generation. Must be
						// 1-8 alphanumeric characters or underscores.
						current?: =~"^[a-zA-Z0-9_]{1,8}$"

						// Retired prefixes accepted during macaroon verification for
						// rotation purposes.
						retired?: [...=~"^[a-zA-Z0-9_]{1,8}$"]
					})
				})
			})
		})

		// Database configuration. Immutable: connection pool is created
		// at startup and cannot be hot-reloaded. Driver type is
		// determined from DSN scheme (sqlite://, postgres://,
		// cockroach://). Connection pool settings are configured via DSN
		// query parameters: max_conns=N, max_idle_conns=N,
		// max_conn_lifetime=5m, max_conn_idle_time=1m. For pgxpool
		// (postgres/cockroach): pool_max_conns, pool_min_conns,
		// pool_max_conn_lifetime, pool_max_conn_idle_time.
		db?: close({
			// Database connection string with scheme and optional query
			// parameters. Immutable: requires server restart to change.
			// Examples: sqlite3://./data.db
			dsn?: strings.MinRunes(1)
		})

		// Configuration for batched last_used_at timestamp updates.
		// Controls how verification events are collected, deduplicated,
		// and flushed as batch UPDATEs. Immutable: requires server
		// restart to change.
		last_used?: close({
			// Buffer size for the async last-used update queue. When full,
			// new updates are dropped (callers debounce to once per day per
			// key). Immutable: requires server restart to change.
			queue_size?: int & >=256 & <=1000000

			// Number of updates per shard that triggers a batch flush.
			// Immutable: requires server restart to change.
			flush_size?: int & >=1 & <=10000

			// Maximum time between batch flushes (Go duration string, e.g.
			// '30s', '1m'). Immutable: requires server restart to change.
			flush_interval?: string

			// Number of goroutines processing last-used batches. Immutable:
			// requires server restart to change.
			num_workers?: int & >=1 & <=64
		})

		// Logging configuration. Immutable: logger is created at startup
		// and requires server restart to change.
		log?: close({
			// Log level. Immutable: requires server restart to change. Stack
			// traces are omitted when level=warn, level=error to avoid
			// leaking sensitive details.
			level?: "debug" | "info" | "warn" | "error"

			// Log format. Immutable: requires server restart to change.
			format?: "json" | "text"
		})

		// `secrets` is intentionally omitted from this schema. Talos loads
		// secrets from env vars (SECRETS_HMAC_CURRENT,
		// SECRETS_HMAC_RETIRED); the module renders those from a k8s
		// Secret so nothing sensitive lands in the ConfigMap. Putting
		// `secrets` into `values.config` here is a CUE error, which is
		// what we want.

		// Resource caps for the current subscription tier. Caps are
		// emitted by the platform configuration pipeline based on the
		// project's plan; metered tiers omit the corresponding field.
		// Hot-reloadable.
		quota?: close({
			// Maximum number of non-revoked API keys (issued + imported) the
			// tenant may hold. Omitted when the plan meters API keys without
			// a cap. Enforced at issuance and import time; revoked keys do
			// not count. Enforcement is best-effort: the active-key count is
			// read outside the insert transaction, so concurrent issuance
			// may briefly exceed the cap by up to N-1 keys, where N is the
			// burst concurrency. Subsequent requests that observe the
			// over-cap state are rejected, so the breach is transient. Use
			// metered billing instead when a hard limit is required.
			api_keys_max?: int & >=0
		})
	})

	// Cross Origin Resource Sharing (CORS)
	//
	// Configure [Cross Origin Resource Sharing
	// (CORS)](http://www.w3.org/TR/cors/) using the following
	// options.
	_#defs: "/properties/serve/properties/http/properties/cors": {
		@jsonschema(id="https://raw.githubusercontent.com/ory/x/master/.schemas/corsx/viper.schema.json")
		close({
			// Enable CORS
			//
			// If set to true, CORS will be enabled and preflight-requests
			// (OPTION) will be answered.
			enabled?: bool

			// Allowed Origins
			//
			// A list of origins a cross-domain request can be executed from.
			// If the special * value is present in the list, all origins
			// will be allowed. An origin may contain a wildcard (*) to
			// replace 0 or more characters (i.e.: http://*.domain.com).
			// Usage of wildcards implies a small performance penality. Only
			// one wildcard can be used per origin.
			allowed_origins?: list.UniqueItems() & [...strings.MinRunes(1)]

			// Allowed HTTP Methods
			//
			// A list of methods the client is allowed to use with
			// cross-domain requests.
			allowed_methods?: list.UniqueItems() & [..."GET" | "HEAD" | "POST" | "PUT" | "DELETE" | "CONNECT" | "TRACE" | "PATCH"]

			// Allowed Request HTTP Headers
			//
			// A list of non simple headers the client is allowed to use with
			// cross-domain requests.
			allowed_headers?: list.UniqueItems() & [...string]

			// Allowed Response HTTP Headers
			//
			// Indicates which headers are safe to expose to the API of a CORS
			// API specification
			exposed_headers?: list.UniqueItems() & [...string]

			// Allow HTTP Credentials
			//
			// Indicates whether the request can include user credentials like
			// cookies, HTTP authentication or client side SSL certificates.
			allow_credentials?: bool

			// Maximum Age
			//
			// Indicates how long (in seconds) the results of a preflight
			// request can be cached. The default is 0 which stands for no
			// max age.
			max_age?: number

			// Enable Debugging
			//
			// Set to true to debug server side CORS issues.
			debug?: bool
		})
	}
}
