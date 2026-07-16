// Tests for the litestream library — focused on the `valid` flag,
// which is the gate consumers use to decide whether to render the
// sidecar.
package litestream_test

import (
	lib "github.com/luzilla/ory-talos-k8s/utils/litestream/litestream"
	"strings"
)

// Empty: defaults only. enabled=false → valid=false.
tcEmpty: lib.#Config & {}
tcEmpty: valid: false

// Enabled but nothing filled in → valid=false (silent skip).
tcEnabledOnly: lib.#Config & {
	enabled: true
}
tcEnabledOnly: valid: false

// Each field individually missing → valid=false.

tcMissingBucket: lib.#Config & {
	enabled: true
	dbPath:  "/var/lib/foo/db.sqlite"
	replica: region: "eu-central-1"
	credentials: {
		accessKeyId:     "AKIAEXAMPLE"
		secretAccessKey: "secret"
	}
}
tcMissingBucket: valid: false

tcMissingRegion: lib.#Config & {
	enabled: true
	dbPath:  "/var/lib/foo/db.sqlite"
	replica: bucket: "my-bucket"
	credentials: {
		accessKeyId:     "AKIAEXAMPLE"
		secretAccessKey: "secret"
	}
}
tcMissingRegion: valid: false

tcMissingDbPath: lib.#Config & {
	enabled: true
	replica: {
		bucket: "my-bucket"
		region: "eu-central-1"
	}
	credentials: {
		accessKeyId:     "AKIAEXAMPLE"
		secretAccessKey: "secret"
	}
}
tcMissingDbPath: valid: false

tcMissingAccessKey: lib.#Config & {
	enabled: true
	dbPath:  "/var/lib/foo/db.sqlite"
	replica: {
		bucket: "my-bucket"
		region: "eu-central-1"
	}
	credentials: secretAccessKey: "secret"
}
tcMissingAccessKey: valid: false

tcMissingSecretKey: lib.#Config & {
	enabled: true
	dbPath:  "/var/lib/foo/db.sqlite"
	replica: {
		bucket: "my-bucket"
		region: "eu-central-1"
	}
	credentials: accessKeyId: "AKIAEXAMPLE"
}
tcMissingSecretKey: valid: false

// All fields set but enabled=false → valid=false.
tcDisabledButComplete: lib.#Config & {
	dbPath: "/var/lib/foo/db.sqlite"
	replica: {
		bucket: "my-bucket"
		region: "eu-central-1"
	}
	credentials: {
		accessKeyId:     "AKIAEXAMPLE"
		secretAccessKey: "secret"
	}
}
tcDisabledButComplete: valid: false

// Fully configured and enabled → valid=true.
tcFull: lib.#Config & {
	enabled: true
	dbPath:  "/var/lib/foo/db.sqlite"
	replica: {
		bucket: "my-bucket"
		region: "eu-central-1"
	}
	credentials: {
		accessKeyId:     "AKIAEXAMPLE"
		secretAccessKey: "secret"
	}
}
tcFull: valid: true

// Render checks: ConfigMap data is non-empty, Secret carries the
// expected env-var keys for the sidecar's envFrom.
tcConfigMap: lib.#ConfigMap & {
	#config: tcFull
	#names: {
		configMap: "foo-litestream-config"
		secret:    "foo-litestream-creds"
	}
	metadata: {
		namespace: "default"
		labels: app: "foo"
	}
}
tcConfigMap: metadata: name:         "foo-litestream-config"
tcConfigMap: data: "litestream.yml": !=""
// The rendered config must enable the metrics HTTP server on :9090
// so #Sidecar's probes can reach it.
tcConfigMapHasAddr: strings.Contains(tcConfigMap.data."litestream.yml", "addr: :9090") & true

tcSecret: lib.#Secret & {
	#config: tcFull
	#names: {
		configMap: "foo-litestream-config"
		secret:    "foo-litestream-creds"
	}
	metadata: {
		namespace: "default"
		labels: app: "foo"
	}
}
tcSecret: metadata: name:                    "foo-litestream-creds"
tcSecret: stringData: AWS_ACCESS_KEY_ID:     "AKIAEXAMPLE"
tcSecret: stringData: AWS_SECRET_ACCESS_KEY: "secret"

// #Restore renders a one-shot init container that runs `litestream
// restore` with idempotent guards and the user's dbPath.
tcRestore: lib.#Restore & {
	#config: tcFull
	#names: {
		configMap: "foo-litestream-config"
		secret:    "foo-litestream-creds"
	}
	#dataMount: {
		name:      "data"
		mountPath: "/var/lib/foo"
	}
}
tcRestore: name: "litestream-restore"
tcRestore: args: [
	"restore",
	"-config", "/etc/litestream/litestream.yml",
	"-if-db-not-exists",
	"-if-replica-exists",
	"/var/lib/foo/db.sqlite",
]

// #Sidecar exposes the litestream :9090 metrics port by name and
// probes it for liveness and readiness. If any of these drift, the
// downstream Service/ServiceMonitor wiring breaks silently — pin
// them here.
tcSidecar: lib.#Sidecar & {
	#config: tcFull
	#names: {
		configMap: "foo-litestream-config"
		secret:    "foo-litestream-creds"
	}
	#dataMount: {
		name:      "data"
		mountPath: "/var/lib/foo"
	}
}
tcSidecar: name: "litestream"
tcSidecar: ports: [{name: "metrics", containerPort: 9090, protocol: "TCP"}]
tcSidecar: livenessProbe: httpGet: {path: "/metrics", port: "metrics"}
tcSidecar: readinessProbe: httpGet: {path: "/metrics", port: "metrics"}
