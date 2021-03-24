# Copyright 2019 Colin Samples
#
# SPDX-License-Identifier: Apache-2.0
#

FROM docker.io/library/fedora:29

RUN dnf -y update && \
    dnf -y install \
        ccache \
        clang \
        cmake \
        git \
        lld \
        llvm \
        make \
        ninja-build \
        patch \
        perl-Data-Dumper \
        perl-Net-GitHub \
        wget \
        zstd \
    && dnf clean all

RUN mkdir -p /workdir
WORKDIR /workdir

CMD ["/usr/bin/bash"]

