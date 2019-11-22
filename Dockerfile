# Copyright 2019 Colin Samples
#
# SPDX-License-Identifier: Apache-2.0
#

FROM fedora:latest

RUN dnf -y update && \
    dnf -y install \
        ccache \
        cmake \
        gcc \
        gcc-g++ \
        git \
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

COPY . /workdir

CMD ["/usr/bin/make"]

