package templates

import (
	"strings"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Hashed name means an HMAC rotation produces a new Secret and triggers
// a rolling restart of the StatefulSet that mounts it via envFrom.
// SECRETS_HMAC_RETIRED is only set when the list is non-empty, so
// deployments without retired keys produce byte-identical Secret data.
#HmacSecret: timoniv1.#ImmutableConfig & {
	#config: #Config
	#Kind:   timoniv1.#SecretKind
	#Meta:   #config.metadata
	#Suffix: "-hmac"
	#Data: {
		SECRETS_HMAC_CURRENT: #config.hmac
		if len(#config.hmacRetired) > 0 {
			SECRETS_HMAC_RETIRED: strings.Join(#config.hmacRetired, ",")
		}
	}
}

// Hashed name means jwks rotations produce a new Secret and trigger a
// rolling restart of the StatefulSet that mounts it.
#JwksSecret: timoniv1.#ImmutableConfig & {
	#config: #Config
	#Kind:   timoniv1.#SecretKind
	#Meta:   #config.metadata
	#Suffix: "-jwks"
	#Data: "jwks.json": #config.jwks
}
