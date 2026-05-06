#!/bin/sh
set -e
RUNTIME_CONF="/tmp/redis-runtime.conf"
if [ -n "$REDIS_PASSWORD" ]; then
    echo "requirepass $REDIS_PASSWORD" > "$RUNTIME_CONF"
else
    echo "" > "$RUNTIME_CONF"
fi
cat /etc/redis/redis.conf >> "$RUNTIME_CONF"
exec redis-server "$RUNTIME_CONF"
