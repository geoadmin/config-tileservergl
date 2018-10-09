include ../lib-makefiles/docker.mk
SHELL:=/bin/bash

.PHONY: build-development
build-tileserver-development:
	$(call dockerbuild,./tileserver_config/,config-tileserver-gl,staging)

.PHONY: build-integration
build-tileserver-integration:
	$(call dockerbuild,./tileserver_config/,config-tileserver-gl,production)
.PHONY: build-production
build-tileserver-production:
	$(call dockerbuild,./tileserver_config/,config-tileserver-gl,production)
.PHONY: push-development
push-development:
	$(call dockerpush,config-tileserver-gl,staging)

.PHONY: push-integration
push-development:
	$(call dockerpush,config-tileserver-gl,integration)

.PHONY: push-production
push-development:
	$(call dockerpush,config-tileserver-gl,production)
