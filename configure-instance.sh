#!/bin/bash

set -e
set -x

pushd /srv/phabricator/phabricator

if [ -e /config/script.pre ]; then
    echo "Applying pre-configuration script..."
    /config/script.pre
else
    echo "+++++ MISSING CONFIGURATION +++++"
    echo ""
    echo "You must specify a preconfiguration script for "
    echo "this Docker image.  To do so: "
    echo ""
    echo "  1) Create a 'script.pre' file in a directory "
    echo "     called 'config', somewhere on the host. "
    echo ""
    echo "  2) Run this Docker instance again with "
    echo "     -v path/to/config:/config passed as an "
    echo "     argument."
    echo ""
    echo "+++++ BOOT FAILED! +++++"
    exit 1
fi

./bin/config set phd.user phab-daemon
./bin/config set diffusion.ssh-user git

popd

pushd /srv/phabricator/phabricator

if [ -e /config/script.post ]; then
    echo "Applying post-configuration script..."
    /config/script.post
fi

if [ -e /config/cert.pem ]; then
    if [ -e /config/cert.key ]; then
        echo "Enabling SSL due to presence of certificates!"
        cp /etc/nginx/nginx-ssl.conf.org /etc/nginx/nginx.conf
    fi
else
  cp /etc/nginx/nginx.conf.org /etc/nginx.conf
fi

popd
