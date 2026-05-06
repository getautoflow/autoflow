#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# Autoflow Community — AWX initialisation (one-shot)
# S'exécute une seule fois avant le démarrage d'awx_web.
# 1. Migrations de base de données
# 2. Types de credentials built-in
# 3. Création du compte administrateur
# 4. Données de démo (organisation, inventaire, projet)
# ──────────────────────────────────────────────────────────────────────────────

set -euo pipefail

log() { echo "[autoflow-community] $*"; }

log "=== Étape 1 : Migrations de base de données ==="
awx-manage migrate --noinput

log "=== Étape 2 : Types de credentials built-in ==="
awx-manage setup_managed_credential_types

log "=== Étape 3 : Création du compte administrateur ==="
awx-manage shell -c "
import os, sys
from django.contrib.auth.models import User

username = os.environ.get('AWX_ADMIN_USER', 'admin')
password = os.environ.get('AWX_ADMIN_PASSWORD', '')
email    = os.environ.get('AWX_ADMIN_EMAIL', 'admin@example.com')

if not password:
    print('ERREUR : AWX_ADMIN_PASSWORD non défini dans .env', file=sys.stderr)
    sys.exit(1)

user, created = User.objects.get_or_create(username=username)
user.set_password(password)
user.is_superuser = True
user.is_staff     = True
user.email        = email
user.save()

action = 'créé' if created else 'mis à jour'
print(f'Compte administrateur \"{username}\" {action}.')
"

log "=== Étape 4 : Données de démo ==="
awx-manage create_preload_data

log "=== Initialisation terminée — AWX prêt ==="
