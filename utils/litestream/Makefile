.PHONY: lint test release yank help

prefix:=utils/litestream

.DEFAULT_GOAL := help

help: ## Show help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-12s\033[0m %s\n", $$1, $$2}'

lint: ## cue fmt --check + cue vet on the library
	cue fmt --check ./litestream
	cue vet ./litestream

test: lint ## run assertion-style tests in ./tests
	cue vet ./tests

release: ## tag and push utils/litestream/$(TAG)
	git tag -a $(prefix)/$(TAG)
	git push origin $(prefix)/$(TAG)

yank: ## delete tag utils/litestream/$(TAG) locally and on origin
	git tag -d $(prefix)/$(TAG)
	git push --delete origin $(prefix)/$(TAG)