#!/bin/bash
# Copyright 2018 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -ex

ARCH="amd64"
DISTRO="stretch"

install_deps() {
    # Xenial is required for binnmu support in pbuilder.
    sudo tee -a /etc/apt/sources.list.d/ubuntu-xenial.list <<EOF
deb http://archive.ubuntu.com/ubuntu xenial main
EOF
    sudo tee -a /etc/apt/preferences.d/pbuilder.pref <<EOF
Package: *
Pin: release n=xenial
Pin-Priority: -10

Package: debootstrap
Pin: release n=xenial
Pin-Priority: 991

Package: devscripts
Pin: release n=xenial
Pin-Priority: 991

Package: dpkg-dev
Pin: release n=xenial
Pin-Priority: 991

Package: libdpkg-perl
Pin: release n=xenial
Pin-Priority: 991

Package: pbuilder
Pin: release n=xenial
Pin-Priority: 991
EOF

    sudo apt-get -q update
    sudo apt-get install -q -y debian-archive-keyring \
                               devscripts \
                               dpkg-dev \
                               pbuilder
}

main() {
    if [ -z "${KOKORO_ARTIFACTS_DIR}" ]; then
        echo "This script must be run in kokoro"
        exit 1
    fi

    local src_root="${KOKORO_ARTIFACTS_DIR}"/git/adapta-gtk-theme
    local result_dir="${src_root}"/results
    mkdir -p "${result_dir}"

    install_deps

    sudo pbuilder --create \
        --distribution "${DISTRO}" \
        --mirror http://deb.debian.org/debian \
        --debootstrapopts "--keyring=/usr/share/keyrings/debian-archive-keyring.gpg" \
        --basetgz /var/cache/pbuilder/"${DISTRO}"-"${ARCH}"-base.tgz

    sudo pbuilder --build \
        --distribution "${DISTRO}" \
        --basetgz /var/cache/pbuilder/"${DISTRO}"-"${ARCH}"-base.tgz \
        --hookdir "${src_root}"/pbuilder_hooks \
        --buildresult "${result_dir}" \
        "${src_root}"/adapta-gtk-theme*.dsc
}

main "$@"
