package templates

import (
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Hashed name means jwks rotations produce a new Secret and trigger a
// rolling restart of the StatefulSet that mounts it.
#Secret: timoniv1.#ImmutableConfig & {
	#config: #Config
	#Kind:   timoniv1.#SecretKind
	#Meta:   #config.metadata
	#Suffix: "-jwks"
	#Data: "jwks.json": #config.jwks
}
