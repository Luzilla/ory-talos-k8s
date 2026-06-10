module: "github.com/luzilla/ory-talos-k8s/utils/litestream@v0"
language: {
	version: "v0.15.0"
}
source: {
	kind: "git"
}
deps: {
	"cue.dev/x/k8s.io@v0": {
		v:       "v0.7.0"
		default: true
	}
}
