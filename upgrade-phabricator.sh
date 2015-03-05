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

echo "Restarting nginx"
supervisorctl restart nginx

# Check to make sure the notification services are running
echo "Restarting aphlict"
sudo -u phab-daemon /srv/phabricator/phabricator/bin/aphlict restart

# Restarts the processes belonging to the group "phd"
echo "Restarting phd daemons"
/srv/phabricator/phabricator/bin/phd restart
