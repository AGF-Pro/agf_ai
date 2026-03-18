#!/bin/bash
set -e

echo ">>> Fixing permissions on mounted volume..."
mkdir -p /opt/vespa/var/tmp \
         /opt/vespa/var/db \
         /opt/vespa/var/zookeeper \
         /opt/vespa/logs

chown -R vespa:vespa /opt/vespa/var /opt/vespa/logs
chmod -R 777 /opt/vespa/var
chmod -R 755 /opt/vespa/logs

echo ">>> Starting Vespa..."
exec su -s /bin/bash vespa -c "/opt/vespa/bin/vespa-start-configserver"