include ../lib-makefiles/integrity.mk
include ../lib-makefiles/docker.mk
SHELL:=/bin/bash

.PHONY: build
build:
	$(call dockerbuild,./tileserver_config/,config-tileserver-gl,$(call commit_tags))
	$(call dockerbuild,./nginx_config/,config-tileservergl-nginx,$(call commit_tags))

.PHONY: push
push:
	$(call push,config-tileserver-gl,$(call commit_tags))
	$(call push,config-tileservergl-nginx,$(call commit_tags))
