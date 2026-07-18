package templates

import (
	timoniv1 "timoni.sh/core/v1alpha1"
	"encoding/yaml"
)

// Hashed name means every config change produces a new object and
// triggers a rolling restart of the StatefulSet that mounts it.
#ConfigMap: timoniv1.#ImmutableConfig & {
	#config: #Config
	#Kind:   timoniv1.#ConfigMapKind
	#Meta:   #config.metadata
	#Suffix: "-config"
	#Data: "config.yaml": yaml.Marshal(#config.config)
}
