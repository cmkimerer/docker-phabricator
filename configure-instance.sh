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
./bin/config set storage.local-disk.path "/var/localstorage"

# Set the name of the host running MySQL:
./bin/config set mysql.host "db"
./bin/config set mysql.port "3306"

# Wait for the db to start listening for up to 5 minutes before proceeding
/srv/wait-for-it/wait-for-it.sh db:3306 -t 600

popd

pushd /srv/phabricator/phabricator

if [ -e /config/authorized_keys ]; then
    echo "Copying authorized_keys file into place"
    mkdir -p /root/.ssh/
    cp /config/authorized_keys /root/.ssh/
    chmod 600 /root/.ssh/authorized_keys
fi

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
    cp /etc/nginx/nginx.conf.org /etc/nginx/nginx.conf
fi

# Start everything here so we don't get error messages during the upgrade
sudo -u phab-daemon bin/phd start || true
sudo -u phab-daemon mkdir -p /var/tmp/aphlict/pid
sudo -u phab-daemon bin/aphlict start || true

popd


