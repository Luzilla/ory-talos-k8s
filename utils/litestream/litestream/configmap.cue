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
		// Turn on the Prometheus metrics HTTP server. #Sidecar exposes
		// containerPort 9090 and probes /metrics; without this the port
		// would be closed and probes would fail.
		addr: ":9090"
		dbs: [{
			path: #config.dbPath
			replicas: [{
				type:   #config.replica.type
				bucket: #config.replica.bucket
				path:   #config.replica.path
				region: #config.replica.region
				if #config.replica.endpoint != "" {
					endpoint: #config.replica.endpoint
				}
				"force-path-style":  #config.replica.forcePathStyle
				retention:           #config.replica.retention
				"snapshot-interval": #config.replica.snapshotInterval
				"sync-interval":     #config.replica.syncInterval
			}]
		}]
	})
}
