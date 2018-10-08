include ../lib-makefiles/docker.mk
SHELL:=/bin/bash

.PHONY: build-development
build-development:
	$(call dockerbuild,.,config-tileserver-gl,staging)

.PHONY: build-integration
build-integration:
	$(call dockerbuild,.,config-tileserver-gl,production)
.PHONY: build-production
build-production:
	$(call dockerbuild,.,config-tileserver-gl,production)
.PHONY: push-development
push-development:
	$(call dockerpush,config-tileserver-gl,staging)

.PHONY: push-integration
push-development:
	$(call dockerpush,config-tileserver-gl,integration)

.PHONY: push-production
push-development:
	$(call dockerpush,config-tileserver-gl,production)
