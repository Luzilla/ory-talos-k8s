// Tests for the litestream library — focused on the `valid` flag,
// which is the gate consumers use to decide whether to render the
// sidecar.
package litestream_test

import lib "github.com/luzilla/ory-talos-k8s/utils/litestream/litestream"

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
tcSecret: metadata: name:                   "foo-litestream-creds"
tcSecret: stringData: AWS_ACCESS_KEY_ID:     "AKIAEXAMPLE"
tcSecret: stringData: AWS_SECRET_ACCESS_KEY: "secret"
