
#!/bin/bash

set -e
set -x

/srv/phabricator/configure-instance.sh
/srv/phabricator/upgrade-phabricator.sh