#!/bin/bash -xe

if (( DIST_VERSION < 10 )); then
  dnf module enable -y nodejs:18
fi

echo install_weak_deps=False >> /etc/dnf/dnf.conf
build_dl "https://dl.fedoraproject.org/pub/epel/epel-release-latest-$DIST_VERSION.noarch.rpm"
rpm -Uvh "$CACHEDIR/epel-release-latest-$DIST_VERSION.noarch.rpm"
