package litestream

import corev1 "cue.dev/x/k8s.io/api/core/v1"

// #Restore is a one-shot init container that rehydrates the SQLite
// database from the replica *before* the main containers (or any
// migration init containers) start. Consumers place it in
// initContainers, *before* any container that reads the DB.
//
// The command is idempotent:
//   -if-db-not-exists   skip when the volume already holds the DB
//   -if-replica-exists  skip when the replica in S3 is empty (first launch)
// So it is safe to run on every pod start.
//
// #dataMount is the consumer's data volume mount — the same PVC mount
// that exposes the SQLite file to the main container. #Restore writes
// the restored DB back into that mount at #config.dbPath.
#Restore: corev1.#Container & {
	#config: #Config
	#names:  #Names
	#dataMount: corev1.#VolumeMount & {
		readOnly?: false
	}

	name:            "litestream-restore"
	image:           "\(#config.image.repository):\(#config.image.tag)@\(#config.image.digest)"
	imagePullPolicy: #config.image.pullPolicy
	args: [
		"restore",
		"-config", "/etc/litestream/litestream.yml",
		"-if-db-not-exists",
		"-if-replica-exists",
		#config.dbPath,
	]
	envFrom: [{secretRef: name: #names.secret}]
	volumeMounts: [
		#dataMount,
		{name: "litestream-config", mountPath: "/etc/litestream", readOnly: true},
	]
	resources:       #config.resources
	securityContext: #config.securityContext
}
