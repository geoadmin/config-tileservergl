include ../lib-makefiles/integrity.mk
include ../lib-makefiles/docker.mk
SHELL:=/bin/bash

.PHONY: build
build:
	$(call dockerbuild,./tileserver_config/,config-tileserver-gl,$(call commit_tags))
	$(call dockerbuild,./nginx_config/,nginx-config-tileserver-gl,$(call commit_tags))
.PHONY: push
push:
	$(call dockerpush,config-tileserver-gl,$(call commit_tags))
	$(call dockerpush,nginx-config-tileserver-gl,$(call commit_tags))
