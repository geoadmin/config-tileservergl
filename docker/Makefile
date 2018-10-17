include ../lib-makefiles/docker.mk
SHELL:=/bin/bash

.PHONY: build-development
build-development:
	$(call dockerbuild,./tileserver_config/,config-tileserver-gl,staging)
	$(call dockerbuild,./nginx_config/,nginx-config-tileserver-gl,staging)
.PHONY: build-integration
build-integration:
	$(call dockerbuild,./tileserver_config/,config-tileserver-gl,integration)
	$(call dockerbuild,./nginx_config/,nginx-config-tileserver-gl,integration)
.PHONY: build-production
build-production:
	$(call dockerbuild,./tileserver_config/,config-tileserver-gl,production)
	$(call dockerbuild,./nginx_config/,nginx-config-tileserver-gl,production)
.PHONY: push-development
push-development:
	$(call dockerpush,config-tileserver-gl,staging)
	$(call dockerpush,nginx-config-tileserver-gl,staging)
.PHONY: push-integration
push-integration:
	$(call dockerpush,config-tileserver-gl,integration)
	$(call dockerpush,nginx-config-tileserver-gl,integration)
.PHONY: push-production
push-production:
	$(call dockerpush,config-tileserver-gl,production)
	$(call dockerpush,nginx-config-tileserver-gl,production)
