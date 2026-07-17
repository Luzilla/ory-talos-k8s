package litestream

import timoniv1 "timoni.sh/core/v1alpha1"

// #Secret holds the AWS-compatible credentials Litestream needs. The
// envFrom in #Sidecar picks AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
// from these stringData keys.
//
// Uses timoni's #ImmutableConfig so a credential rotation produces a
// new object name and forces a rolling restart of the pod.
#Secret: timoniv1.#ImmutableConfig & {
	#config: #Config
	#Kind:   timoniv1.#SecretKind
	#Meta:   timoniv1.#Metadata
	#Suffix: "-litestream-creds"
	#Data: {
		AWS_ACCESS_KEY_ID:     #config.credentials.accessKeyId
		AWS_SECRET_ACCESS_KEY: #config.credentials.secretAccessKey
	}
}
