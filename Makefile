# Copyright 2019 Colin Samples
#
# SPDX-License-Identifier: Apache-2.0
#

.DEFAULT_GOAL := all

export NUM_THREADS ?= 16

project-id := 15464360

artifact-dir := target

llvm_rev := 8455294f2ac13d587b13d728038a9bffa7185f2b
llvm-dist-dir := llvm-$(llvm_rev)-ppc64le
llvm-dist-file := $(llvm-dist-dir).tar.gz
llvm-dist-artifact := $(artifact-dir)/$(llvm-dist-file)

llvm_url := https://github.com/llvm/llvm-project/archive/$(llvm_rev).tar.gz

llvm-archive := $(llvm_rev).tar.gz
llvm-dir := $(CURDIR)/llvm-project-$(llvm_rev)
llvm-build-dir := $(CURDIR)/llvm-build
llvm-patched := llvm-patched.stamp
llvm-patch := 0001-PowerPC-Do-not-emit-HW-loop-if-the-body-contains-cal.patch
clang := $(llvm-build-dir)/bin/clang

# LLVM build targets
$(artifact-dir) $(llvm-build-dir):
	mkdir -p $@

$(llvm-archive):
	wget -q $(llvm_url)

$(llvm-dir): | $(llvm-archive)
	tar xzf $|

$(llvm-patched): | $(llvm-dir)
	patch -d $| -p1 < $(llvm-patch)
	touch $@

$(llvm-build-dir)/CMakeCache.txt: $(llvm-patched) | $(llvm-build-dir) $(llvm-dir)
	cmake -S $(llvm-dir)/llvm -B $(llvm-build-dir) \
	    -G "Ninja" \
	    -DCMAKE_BUILD_TYPE=Release \
	    -DLLVM_ENABLE_WARNINGS=OFF \
	    -DCMAKE_INSTALL_PREFIX=$(llvm-dist-dir) \
	    -DLLVM_ENABLE_PROJECTS="clang;lld" \
	    -DLLVM_TARGETS_TO_BUILD="PowerPC"

$(clang): $(llvm-build-dir)/CMakeCache.txt
	ninja -C $(llvm-build-dir) -j $(NUM_THREADS)

$(llvm-dist-artifact): $(clang) | $(artifact-dir)
	ninja -C $(llvm-build-dir) install
	tar czf $@ $(llvm-dist-dir)

.PHONY: all
all: $(llvm-dist-artifact)


# Local development targets
.PHONY: dev
dev:
	mkdir -p build-root
	podman bud -t llvm-build-image .
	podman run -it \
	    --name=llvm-builder \
	    --rm \
	    --volume=$(CURDIR)/build-root:/workdir:z \
	    --volume=$(CURDIR)/$(artifact_dir):/workdir/$(artifact-dir):z \
	    llvm-build-image /usr/bin/bash

.PHONY: tag-release
tag-release:
	git tag -s v$(llvm_rev) -m "LLVM $(llvm_rev)"

include release-json-template.mk
.PHONY: gitlab-upload-release
gitlab-upload-release:
	curl --header 'Content-Type: application/json' \
	     --header "PRIVATE-TOKEN: $(GITLAB_API_TOKEN)" \
	     --data "$$release_json_template" \
	     --request POST https://gitlab.com/api/v4/projects/$(project-id)/releases

