package litestream

import (
	timoniv1 "timoni.sh/core/v1alpha1"
	"encoding/yaml"
)

// #ConfigMap renders the litestream.yml that the sidecar reads.
// Uses timoni's #ImmutableConfig so the object name carries a hash of
// the data — any config change produces a new name, which forces a
// rolling restart of the pod that mounts it. Consumer supplies a base
// name via #Meta.name and reads the hashed name off .metadata.name.
#ConfigMap: timoniv1.#ImmutableConfig & {
	#config: #Config
	#Kind:   timoniv1.#ConfigMapKind
	#Meta:   timoniv1.#Metadata
	#Suffix: "-litestream-config"
	#Data: "litestream.yml": yaml.Marshal({
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
