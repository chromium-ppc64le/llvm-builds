# Copyright 2019 Colin Samples
#
# SPDX-License-Identifier: Apache-2.0
#

.DEFAULT_GOAL := all

export NUM_THREADS ?= 32

project-id := 15464360

artifact-dir := target

llvm_rev := 1fdec59bffc11ae37eb51a1b9869f0696bfd5312
llvm-dist-dir := llvm-$(llvm_rev)-ppc64le
llvm-dist-file := $(llvm-dist-dir).tar.zst
llvm-dist-artifact := $(artifact-dir)/$(llvm-dist-file)

llvm_url := https://github.com/llvm/llvm-project/archive/$(llvm_rev).tar.gz

llvm-archive := $(llvm_rev).tar.gz
llvm-dir := $(CURDIR)/llvm-project-$(llvm_rev)
llvm-build-dir := $(CURDIR)/llvm-build
llvm-patched := llvm-patched.stamp
llvm-patch := 0001-Fix-C-compilation-of-altivec.h.patch
clang := $(llvm-build-dir)/bin/clang

export CCACHE_BASEDIR := $(CURDIR)
export CCACHE_DIR := $(CURDIR)/.ccache

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
	cd $(llvm-build-dir) && cmake $(llvm-dir)/llvm \
	    -G "Ninja" \
	    -DCMAKE_BUILD_TYPE=Release \
	    -DLLVM_ENABLE_LTO=full \
	    -DLLVM_ENABLE_LLD=ON \
	    -DLLVM_ENABLE_WARNINGS=OFF \
	    -DCMAKE_INSTALL_PREFIX=$(CURDIR)/$(artifact-dir)/$(llvm-dist-dir) \
	    -DLLVM_ENABLE_PROJECTS="clang;lld" \
	    -DLLVM_TARGETS_TO_BUILD="PowerPC" \
	    -DCMAKE_C_COMPILER=/usr/bin/clang \
	    -DCMAKE_CXX_COMPILER=/usr/bin/clang++ \
	    -DCMAKE_AR=/usr/bin/llvm-ar \
	    -DCMAKE_NM=/usr/bin/llvm-nm \
	    -DCMAKE_RANLIB=/usr/bin/llvm-ranlib \
	    -DCMAKE_C_COMPILER_LAUNCHER=/usr/bin/ccache \
	    -DCMAKE_CXX_COMPILER_LAUNCHER=/usr/bin/ccache \
	    -DLLVM_PARALLEL_LINK_JOBS=4

$(clang): $(llvm-build-dir)/CMakeCache.txt
	ninja -C $(llvm-build-dir) -j $(NUM_THREADS)

$(llvm-dist-artifact): $(clang) | $(artifact-dir)
	ninja -C $(llvm-build-dir) install
	cd $(artifact-dir) && \
	tar -I '/usr/bin/zstd --ultra -22 -T$(NUM_THREADS)' \
	    -cf $(llvm-dist-file) $(llvm-dist-dir)

.PHONY: all
all: $(llvm-dist-artifact)


# Local development targets
.PHONY: dev
dev:
	mkdir -p build-root
	git ls-files -z | xargs -0 -I{} cp {} build-root
	podman build -t llvm-build-image .
	podman run -it \
	    --name=llvm-builder \
	    --rm \
	    --volume=$(CURDIR)/build-root:/workdir:z \
	    --volume=$(CURDIR)/$(artifact-dir):/workdir/$(artifact-dir):z \
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

.PHONY: github-upload-release
github-upload-release:
	./create-github-release.pl $(llvm_rev) $(llvm-dist-artifact)

