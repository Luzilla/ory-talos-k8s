.PHONY: release yank

prefix:=utils/litestream

release:
	git tag -a $(prefix)/$(TAG)
	git push origin $(prefix)/$(TAG)

yank:
	git tag -d $(prefix)/$(TAG)
	git push --delete origin $(prefix)/$(TAG)