package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	ls "github.com/luzilla/ory-talos-k8s/utils/litestream/litestream"
)

#StatefulSet: appsv1.#StatefulSet & {
	#config:  #Config
	#lsNames: ls.#Names

	// Bind the outer #config to a local name so nested `#config:` fields
	// (e.g. inside ls.#Sidecar) can reach it without shadowing.
	let cfg = #config

	// Data-volume mount shared by db-init, backend, and the litestream
	// sidecar. Declared once so all three containers agree on the path.
	_dataMount: corev1.#VolumeMount & {
		name:      "data"
		mountPath: "/var/lib/talos"
	}

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#StatefulSetSpec & {
		replicas:    1
		serviceName: "\(#config.metadata.name)-headless"
		selector: matchLabels: #config.selector.labels
		template: {
			metadata: {
				labels: #config.selector.labels
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				automountServiceAccountToken: false
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				if #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}
				initContainers: [
					// Restore runs BEFORE db-init so migrations see a
					// rehydrated database on a fresh pod. Idempotent
					// (-if-db-not-exists / -if-replica-exists) so a warm
					// pod or empty replica is a no-op.
					if cfg.litestream.valid {
						ls.#Restore & {
							#config:    cfg.litestream
							#names:     #lsNames
							#dataMount: _dataMount
						}
					},
					{
						name:            "db-init"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						command: ["talos"]
						args: [
							"migrate", "up",
						]
						env: [
							{name: "DB_DSN", value: #config.config.db.dsn},
						]
						volumeMounts: [_dataMount]
						resources:       #config.initResources
						securityContext: #config.securityContext
					},
					if cfg.litestream.valid {
						ls.#Sidecar & {
							#config:    cfg.litestream
							#names:     #lsNames
							#dataMount: _dataMount
						}
					},
				]
				containers: [{
					name:            "backend"
					image:           #config.image.reference
					imagePullPolicy: #config.image.pullPolicy
					args: ["serve", "--config", "/etc/talos/config.yaml"]
					ports: [
						{name: "http", containerPort: 4420, protocol: "TCP"},
					]
					livenessProbe: {
						httpGet: {path: "/health/alive", port: "http"}
						initialDelaySeconds: 10
						periodSeconds:       10
						timeoutSeconds:      5
						failureThreshold:    5
					}
					readinessProbe: {
						httpGet: {path: "/health/ready", port: "http"}
						initialDelaySeconds: 10
						periodSeconds:       10
						timeoutSeconds:      5
						failureThreshold:    5
					}
					volumeMounts: [
						{name: "config", mountPath: "/etc/talos/config.yaml", subPath: "config.yaml", readOnly: true},
						{name: "jwks", mountPath:   "/etc/talos/jwks.json", subPath:   "jwks.json", readOnly: true},
						_dataMount,
					]
					resources:       #config.resources
					securityContext: #config.securityContext
				}]
				volumes: [
					{
						name: "config"
						configMap: name: "\(#config.metadata.name)-config"
					},
					{
						name: "jwks"
						secret: secretName: "\(#config.metadata.name)-jwks"
					},
					if cfg.litestream.valid {
						ls.#ConfigVolume & {#names: #lsNames}
					},
				]
			}
		}
		volumeClaimTemplates: [{
			metadata: {
				name:   "data"
				labels: #config.metadata.labels
			}
			spec: corev1.#PersistentVolumeClaimSpec & {
				accessModes: #config.persistence.accessModes
				if #config.persistence.storageClassName != "" {
					storageClassName: #config.persistence.storageClassName
				}
				resources: requests: storage: #config.persistence.size
			}
		}]
	}
}
