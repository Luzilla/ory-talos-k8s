package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#StatefulSet: appsv1.#StatefulSet & {
	#config:    #Config
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
				initContainers: [{
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
					volumeMounts: [
						{name: "data", mountPath: "/var/lib/talos"},
					]
					resources:       #config.initResources
					securityContext: #config.securityContext
				}]
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
						{name: "data", mountPath:   "/var/lib/talos"},
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
