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
#Config: {
	// enabled gates everything downstream. When false, consumers should
	// emit none of #ConfigMap / #Secret / #Sidecar / #ConfigVolume.
	enabled: *false | bool

	image: {
		repository: *"litestream/litestream" | string
		tag:        *"0.3.13" | string
		// digest is the source of truth; tag is for log readability.
		digest!:    string & =~"^sha256:[0-9a-f]{64}$"
		pullPolicy: *"IfNotPresent" | "Always" | "Never"
	}

	// Absolute path to the SQLite file inside the pod. Consumers derive
	// this from their own DSN — for ory-talos this is the path stripped
	// from "sqlite3://<path>?<query>".
	dbPath!: string & =~"^/"

	replica: {
		// Only S3-compatible stores are supported in v0.
		type:    *"s3" | "s3"
		bucket!: string
		path:    *"" | string
		region!: string
		// Optional custom endpoint for R2, MinIO, etc.
		endpoint: *"" | string
		// MinIO requires path-style URLs.
		forcePathStyle:   *false | bool
		retention:        *"72h" | string
		snapshotInterval: *"24h" | string
		syncInterval:     *"1s" | string
	}

	credentials: {
		accessKeyId!:     string
		secretAccessKey!: string
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
}

// #Names lets consumer and library agree on the ConfigMap and Secret
// names. The consumer picks a base (e.g. its instance name) and resolves
// the fields; both sides reference the same struct.
#Names: {
	configMap!: string
	secret!:    string
}
