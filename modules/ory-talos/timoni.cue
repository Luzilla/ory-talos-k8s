package main

import (
	templates "github.com/luzilla/ory-talos/templates"
)

// The user-supplied values are validated against the schema in
// templates/config.cue and merged with the defaults in values.cue.
values: templates.#Config

timoni: {
	apiVersion: "v1alpha1"

	instance: templates.#Instance & {
		config: values
		config: {
			metadata: {
				name:      string @tag(name)
				namespace: string @tag(namespace)
			}
			moduleVersion: string @tag(mv, var=moduleVersion)
			kubeVersion:   string @tag(kv, var=kubeVersion)
		}
	}

	apply: app: [for obj in instance.objects {obj}]
}
