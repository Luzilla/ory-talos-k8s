// Package litestream is a CUE library — not a Timoni module.
// Consumers vendor it into their cue.mod/pkg/ and import the definitions
// to embed a Litestream sidecar in their own pod spec. The library never
// emits a Pod or workload object on its own.
package litestream

import corev1 "cue.dev/x/k8s.io/api/core/v1"

// #CPUQuantity matches strings like "100m" or "2000m" (milli-cpus).
// Inlined here to keep the library free of a timoni dependency.
#CPUQuantity: string & =~"^[1-9]\\d*m$"

// #MemoryQuantity matches strings like "128Mi" or "2Gi".
#MemoryQuantity: string & =~"^[1-9]\\d*(Mi|Gi)$"

// #ResourceRequirements is the subset of corev1.ResourceRequirements
// that consumers care about. Kept tight to encourage sensible defaults.
#ResourceRequirements: {
	requests?: {
		cpu?:    #CPUQuantity
		memory?: #MemoryQuantity
	}
	limits?: {
		cpu?:    #CPUQuantity
		memory?: #MemoryQuantity
	}
}

// #Config is the user-facing schema for a Litestream sidecar that
// replicates a single SQLite database to an S3-compatible store.
//
// All user-supplied fields are optional with empty defaults so the
// schema vets cleanly when the consumer has not wired anything in.
// Use the derived `valid` field, not `enabled`, to decide whether to
// render — `valid` is true only when every field needed for a working
// config is non-empty.
#Config: {
	// enabled is the user's intent. Combined with the field checks
	// below it produces `valid`, which is what consumers gate on.
	enabled: *false | bool

	image: {
		repository: *"litestream/litestream" | string
		tag:        *"0.3.13" | string
		// digest is the source of truth; tag is for log readability.
		// Default pins litestream/litestream:0.3.13 (multi-arch index).
		digest:     *"sha256:027eda2a89a86015b9797d2129d4dd447e8953097b4190e1d5a30b73e76d8d58" | string & =~"^(sha256:[0-9a-f]{64})?$"
		pullPolicy: *"IfNotPresent" | "Always" | "Never"
	}

	// Absolute path to the SQLite file inside the pod. Consumers derive
	// this from their own DSN — for ory-talos this is the path stripped
	// from "sqlite3://<path>?<query>". Empty disables rendering.
	dbPath: *"" | string & =~"^(/.*)?$"

	replica: {
		// Only S3-compatible stores are supported in v0.
		type:   *"s3" | "s3"
		bucket: *"" | string
		path:   *"" | string
		region: *"" | string
		// Optional custom endpoint for R2, MinIO, etc.
		endpoint: *"" | string
		// MinIO requires path-style URLs.
		forcePathStyle:   *false | bool
		retention:        *"72h" | string
		snapshotInterval: *"24h" | string
		syncInterval:     *"1s" | string
	}

	credentials: {
		accessKeyId:     *"" | string
		secretAccessKey: *"" | string
	}

	resources: #ResourceRequirements & {
		requests: {
			cpu:    *"50m" | #CPUQuantity
			memory: *"64Mi" | #MemoryQuantity
		}
		limits: {
			cpu:    *"200m" | #CPUQuantity
			memory: *"128Mi" | #MemoryQuantity
		}
	}

	securityContext: corev1.#SecurityContext & {
		allowPrivilegeEscalation: *false | true
		privileged:               *false | true
		capabilities: {
			drop: *["ALL"] | [...string]
			add: *[] | [...string]
		}
	}

	// valid is true only when the user opted in AND every field needed
	// for a working sidecar is filled in. Consumers gate rendering on
	// this — an enabled-but-incomplete config silently does not render.
	valid: bool & (
		enabled &&
		image.digest != "" &&
		dbPath != "" &&
		replica.bucket != "" &&
		replica.region != "" &&
		credentials.accessKeyId != "" &&
		credentials.secretAccessKey != "")
}

// #Names lets consumer and library agree on the ConfigMap and Secret
// names. The consumer picks a base (e.g. its instance name) and resolves
// the fields; both sides reference the same struct.
#Names: {
	configMap: *"" | string
	secret:    *"" | string
}
