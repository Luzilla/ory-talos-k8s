package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
	ls "github.com/luzilla/ory-talos-k8s/utils/litestream/litestream"
	"strings"
)

// #Config defines the configuration values of the ory-talos module.
#Config: {
	kubeVersion!: string
	// Litestream's sidecar uses initContainers + restartPolicy: Always
	// (native sidecars, k8s 1.29+). When enabled, raise the floor; on
	// older clusters restartPolicy is ignored and the sidecar would
	// exit after replicate returns.
	clusterVersion: timoniv1.#SemVer & {
		#Version: kubeVersion
		if litestream.enabled {
			#Minimum: "1.29.0"
		}
		if !litestream.enabled {
			#Minimum: "1.20.0"
		}
	}

	moduleVersion!: string

	metadata: timoniv1.#Metadata & {#Version: moduleVersion}
	metadata: labels:        timoniv1.#Labels
	metadata: annotations?:  timoniv1.#Annotations

	selector: timoniv1.#Selector & {#Name: metadata.name}

	// tag: v26.2.0 — kept for log lines / readability only. The digest is
	// the source of truth. Bump BOTH when upgrading.
	image!: timoniv1.#Image

	// Structured talos config. Validated against the upstream JSON schema
	// (see talos_schema.cue). The init container's DB_DSN env is sourced
	// from config.db.dsn so there is one source of truth.
	config!: #TalosConfig

	// Body of jwks.json. Required.
	jwks!: string

	persistence: {
		size:             *"1Gi" | string
		storageClassName: *""    | string
		accessModes:      *["ReadWriteOnce"] | [...string]
	}

	resources: timoniv1.#ResourceRequirements & {
		requests: {
			cpu:    *"100m" | timoniv1.#CPUQuantity
			memory: *"128Mi" | timoniv1.#MemoryQuantity
		}
		limits: {
			cpu:    *"500m" | timoniv1.#CPUQuantity
			memory: *"512Mi" | timoniv1.#MemoryQuantity
		}
	}

	// Resources for the db-init container. Migrations are short-lived but
	// can be I/O heavy on first run; keep defaults modest.
	initResources: timoniv1.#ResourceRequirements & {
		requests: {
			cpu:    *"50m" | timoniv1.#CPUQuantity
			memory: *"64Mi" | timoniv1.#MemoryQuantity
		}
		limits: {
			cpu:    *"250m" | timoniv1.#CPUQuantity
			memory: *"256Mi" | timoniv1.#MemoryQuantity
		}
	}

	securityContext: corev1.#SecurityContext & {
		allowPrivilegeEscalation: *false | true
		privileged:               *false | true
		capabilities: {
			drop: *["ALL"] | [...string]
			add:  *["NET_BIND_SERVICE"] | [...string]
		}
	}

	podAnnotations?: {[string]: string}

	imagePullSecrets?: [...timoniv1.#ObjectReference]

	// Optional Litestream sidecar. Defaults to disabled. When the user
	// opts in and fills in bucket/region/credentials, the library's
	// `valid` gate flips to true and the module renders the ConfigMap,
	// Secret, sidecar container, and config volume.
	//
	// dbPath is derived from config.db.dsn — the DSN is the single source
	// of truth for where Talos writes its SQLite file.
	litestream: ls.#Config & {
		dbPath: strings.Split(strings.TrimPrefix(config.db.dsn, "sqlite3://"), "?")[0]
	}
}

// #Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	// Shared naming contract between StatefulSet, ConfigMap, and Secret
	// for the Litestream sidecar. Kept here so both sides agree on the
	// same strings.
	_lsNames: ls.#Names & {
		configMap: "\(config.metadata.name)-litestream-config"
		secret:    "\(config.metadata.name)-litestream-creds"
	}

	objects: {
		cm:   #ConfigMap & {#config:      config}
		sec:  #Secret & {#config:         config}
		svc:  #Service & {#config:        config}
		svch: #ServiceHeadless & {#config: config}
		sts:  #StatefulSet & {#config:    config, #lsNames: _lsNames}

		if config.litestream.valid {
			lsCm: ls.#ConfigMap & {
				#config: config.litestream
				#names:  _lsNames
				metadata: {
					namespace: config.metadata.namespace
					labels:    config.metadata.labels
				}
			}
			lsSec: ls.#Secret & {
				#config: config.litestream
				#names:  _lsNames
				metadata: {
					namespace: config.metadata.namespace
					labels:    config.metadata.labels
				}
			}
		}
	}
}
