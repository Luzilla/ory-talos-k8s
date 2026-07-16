package litestream

import (
	corev1 "cue.dev/x/k8s.io/api/core/v1"
	"encoding/yaml"
)

// #ConfigMap renders the litestream.yml that the sidecar reads.
// metadata.namespace and metadata.labels are left open — the consumer
// fills them in to match its own object metadata.
#ConfigMap: corev1.#ConfigMap & {
	#config: #Config
	#names:  #Names

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      #names.configMap
		namespace: string
		labels: {[string]: string}
	}
	data: "litestream.yml": yaml.Marshal({
		logging: {
			level:  #config.logging.level
			type:   #config.logging.type
			stderr: #config.logging.stderr
			source: #config.logging.source
		}
		// Turn on the Prometheus metrics HTTP server. #Sidecar exposes
		// containerPort 9090 and probes /metrics; without this the port
		// would be closed and probes would fail.
		addr: ":9090"
		snapshot: {
			interval:  #config.replica.snapshotInterval
			retention: #config.replica.retention
		}
		dbs: [{
			path: #config.dbPath
			replica: {
				type:   #config.replica.type
				bucket: #config.replica.bucket
				path:   #config.replica.path
				region: #config.replica.region
				if #config.replica.endpoint != "" {
					endpoint: #config.replica.endpoint
				}
				"force-path-style": #config.replica.forcePathStyle
				"sync-interval":    #config.replica.syncInterval
			}
		}]
	})
}
