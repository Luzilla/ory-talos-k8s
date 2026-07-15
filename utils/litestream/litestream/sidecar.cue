package litestream

import corev1 "cue.dev/x/k8s.io/api/core/v1"

// #Sidecar is a native sidecar container (k8s 1.29+). Consumers place
// it in initContainers; the restartPolicy: Always marker makes the
// kubelet start it before the main containers and keep it running.
//
// #dataMount is the consumer's data volume mount — the same PVC mount
// that exposes the SQLite file to the main container.
#Sidecar: corev1.#Container & {
	#config: #Config
	#names:  #Names
	#dataMount: corev1.#VolumeMount & {
		readOnly?: false
	}

	name:            "litestream"
	image:           "\(#config.image.repository):\(#config.image.tag)@\(#config.image.digest)"
	imagePullPolicy: #config.image.pullPolicy
	restartPolicy:   "Always"
	args: ["replicate", "-config", "/etc/litestream/litestream.yml"]
	envFrom: [{secretRef: name: #names.secret}]
	volumeMounts: [
		#dataMount,
		{name: "litestream-config", mountPath: "/etc/litestream", readOnly: true},
	]
	resources:       #config.resources
	securityContext: #config.securityContext
}

// #ConfigVolume is the pod-level volume entry that mounts the Litestream
// ConfigMap into the sidecar.
#ConfigVolume: corev1.#Volume & {
	#names: #Names
	name:   "litestream-config"
	configMap: name: #names.configMap
}
