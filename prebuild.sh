#!/bin/bash -xe
dnf module enable -y nodejs:18
echo install_weak_deps=False >> /etc/dnf/dnf.conf
build_dl "https://dl.fedoraproject.org/pub/epel/epel-release-latest-$DIST_VERSION.noarch.rpm"
rpm -Uvh "$CACHEDIR/epel-release-latest-$DIST_VERSION.noarch.rpm"
