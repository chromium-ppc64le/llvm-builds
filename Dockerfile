# Copyright 2019 Colin Samples
#
# SPDX-License-Identifier: Apache-2.0
#

FROM quay.io/centos/centos:centos8

RUN dnf -y install epel-release && \
    dnf -y install dnf-plugins-core && \
    dnf config-manager --set-enabled powertools
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
        wget \
        python2 \
        zstd \
    && dnf clean all

RUN mkdir -p /workdir
WORKDIR /workdir

CMD ["/usr/bin/bash"]

