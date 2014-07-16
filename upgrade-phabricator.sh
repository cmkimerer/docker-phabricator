#!/bin/bash

set -x

echo "Upgrading Phabricator..."

pushd /srv/phabricator/libphutil
git pull --rebase
popd

pushd /srv/phabricator/arcanist
git pull --rebase
popd

pushd /srv/phabricator/phabricator
git pull --rebase
popd

echo "Applying any pending DB schema upgrades..."
/srv/phabricator/phabricator/bin/storage upgrade --force

# The actual restart is handled by supervisord
echo "Restarting nginx if it was running"
/etc/init.d/nginx stop

# Check to make sure the notification services are running
/srv/phabricator/phabricator/bin/aphlict status
if [ $? -ne 0 ]; then
  /srv/phabricator/phabricator/bin/aphlict restart
fi