#!/bin/bash
set -e

# Attempt to raise the process/thread limits before Vespa starts.
# Vespa needs ~300-500 threads at startup; Railway defaults pids.max to ~1000
# but ulimit -u (user process limit) can be lower inside the container.
ulimit -u unlimited 2>/dev/null || ulimit -u 65535 2>/dev/null || true
echo "max" > /sys/fs/cgroup/pids/pids.max 2>/dev/null || true
echo ">>> pids.max: $(cat /sys/fs/cgroup/pids/pids.max 2>/dev/null || echo 'unreadable')"
echo ">>> ulimit -u: $(ulimit -u)"

# Railway mounts volumes as root:root at runtime.
# Fix ownership so the vespa user (uid 1000) can write into the volume.
# This runs as root (before the vespa user takes over in start-container.sh).
echo ">>> Fixing permissions on Railway volume mount..."
mkdir -p /opt/vespa/var/tmp \
         /opt/vespa/var/db \
         /opt/vespa/var/zookeeper \
         /opt/vespa/logs

chown -R vespa:vespa /opt/vespa/var /opt/vespa/logs
chmod -R 777 /opt/vespa/var
chmod -R 755 /opt/vespa/logs

# exec directly into the original Vespa entrypoint as PID 1.
# start-container.sh handles user-switching internally, so we do NOT
# wrap it in 'su' — that would break stdout/stderr capture in Railway
# and prevent proper signal (SIGTERM) propagation.
echo ">>> Handing off to Vespa original entrypoint..."
exec /usr/local/bin/start-container.sh