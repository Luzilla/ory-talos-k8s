package litestream

import corev1 "cue.dev/x/k8s.io/api/core/v1"

// #Secret holds the AWS-compatible credentials Litestream needs. The
// envFrom in #Sidecar picks AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
// from these stringData keys.
#Secret: corev1.#Secret & {
	#config: #Config
	#names:  #Names

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #names.secret
		namespace: string
		labels: {[string]: string}
	}
	type: "Opaque"
	stringData: {
		AWS_ACCESS_KEY_ID:     #config.credentials.accessKeyId
		AWS_SECRET_ACCESS_KEY: #config.credentials.secretAccessKey
	}
}
