# Copyright 2019 Colin Samples
#
# SPDX-License-Identifier: Apache-2.0
#

FROM fedora:latest

RUN dnf -y update && \
    dnf -y install \
        cmake \
        gcc \
        gcc-g++ \
        git \
        make \
        ninja-build \
        patch \
        wget \
    && dnf clean all

RUN mkdir -p /workdir
WORKDIR /workdir

COPY . /workdir

CMD ["/usr/bin/make"]

