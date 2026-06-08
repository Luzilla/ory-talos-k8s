SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c

MODULE_DIR    := ./modules/ory-talos
BUNDLE_FILE   := ./docs/bundles/ory-talos.cue
DEV_VALUES    := ./tests/dev-values.cue
INSTANCE_NAME := ory-talos
INSTANCE_NS   := ory-talos
DIST_DIR      := ./dist
MANIFESTS     := $(DIST_DIR)/manifests.yaml
GOLDEN        := ./tests/golden/manifests.yaml
KIND_CLUSTER  := talos-dev

.PHONY: all lint test build run-dev update-golden setup teardown clean help

.DEFAULT_GOAL := help

all: lint build test

help: ## Show help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

lint: ## "cue fmt --check + cue vet"
	cue fmt --check ./...
	cue vet ./...

build: $(MANIFESTS) ## render manifests to

$(MANIFESTS): $(shell find $(MODULE_DIR) -name '*.cue') $(DEV_VALUES)
	mkdir -p $(DIST_DIR)
	timoni build $(INSTANCE_NAME) $(MODULE_DIR) \
		-n $(INSTANCE_NS) \
		--values $(DEV_VALUES) \
		> $(MANIFESTS)

test: build ## mod vet + bundle vet + JSON Schema + golden diff + kubeconform
	timoni mod vet $(MODULE_DIR)
	timoni bundle vet -f $(BUNDLE_FILE)
	./scripts/validate-talos-config.sh $(MANIFESTS)
	./scripts/normalize-manifests.sh $(MANIFESTS) > /tmp/rendered.norm.yaml
	./scripts/normalize-manifests.sh $(GOLDEN)    > /tmp/golden.norm.yaml
	diff -u /tmp/golden.norm.yaml /tmp/rendered.norm.yaml
	kubeconform -strict -summary -schema-location default $(MANIFESTS)

update-golden: build ## re-generate from current templates
	./scripts/normalize-manifests.sh $(MANIFESTS) > $(GOLDEN)
	@echo "Regenerated $(GOLDEN). Review the diff and stage it."

run-dev: ## apply against current Kubernetes context
	kubectl get namespace $(INSTANCE_NS) >/dev/null 2>&1 || kubectl create namespace $(INSTANCE_NS)
	timoni apply $(INSTANCE_NAME) $(MODULE_DIR) \
		-n $(INSTANCE_NS) \
		--values $(DEV_VALUES)

setup: ## create kind cluster and switch context
	@if ! command -v kind >/dev/null 2>&1; then \
		echo "kind not found. Install: https://kind.sigs.k8s.io/docs/user/quick-start/#installation" >&2; \
		exit 1; \
	fi
	@if kind get clusters 2>/dev/null | grep -qx "$(KIND_CLUSTER)"; then \
		echo "kind cluster $(KIND_CLUSTER) already exists"; \
	else \
		kind create cluster --name $(KIND_CLUSTER); \
	fi
	kubectl config use-context kind-$(KIND_CLUSTER)

teardown: ## delete kind cluster
	kind delete cluster --name $(KIND_CLUSTER)

clean: ## delete build
	rm -rf $(DIST_DIR)
