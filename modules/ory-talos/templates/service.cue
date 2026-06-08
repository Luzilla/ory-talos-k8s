package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#Service: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		type:     corev1.#ServiceTypeClusterIP
		selector: #config.selector.labels
		ports: [
			{
				name:       "http"
				port:       4420
				targetPort: 4420
				protocol:   "TCP"
			},
		]
	}
}

#ServiceHeadless: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-headless"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		clusterIP: "None"
		selector:  #config.selector.labels
		ports: [
			{
				name:       "http"
				port:       4420
				targetPort: 4420
				protocol:   "TCP"
			},
		]
	}
}
