#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# Custom AWX task launcher for Docker Compose.
# Replaces /usr/bin/launch_awx_task.sh inside the container.
#
# Key difference from the k8s version:
#   provision_instance --hostname <name> bypasses the k8s-only guard that fires
#   when no hostname is given and AWX_AUTO_DEPROVISION_INSTANCES=False.
# ──────────────────────────────────────────────────────────────────────────────

set -euo pipefail

if [ "$(id -u)" -ge 500 ]; then
    echo "awx:x:$(id -u):$(id -g):,,,:/var/lib/awx:/bin/bash" >> /tmp/passwd
    cat /tmp/passwd > /etc/passwd
    rm /tmp/passwd
fi

HOSTNAME="${AWX_TASK_HOSTNAME:-awx}"

echo "[autoflow] Waiting for database migrations..."
wait-for-migrations

echo "[autoflow] Registering instance: hostname=${HOSTNAME}, type=hybrid"
awx-manage provision_instance --hostname "${HOSTNAME}" --node_type hybrid

echo "[autoflow] Starting AWX task supervisor..."
exec supervisord -c /etc/supervisord_task.conf
