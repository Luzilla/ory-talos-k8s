package templates

import (
	corev1 "k8s.io/api/core/v1"
	"encoding/yaml"
)

#ConfigMap: corev1.#ConfigMap & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-config"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	data: "config.yaml": yaml.Marshal(#config.config)
}
