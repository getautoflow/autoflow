#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# Autoflow Community — AWX initialisation (one-shot)
# S'exécute une seule fois avant le démarrage d'awx_web.
# ──────────────────────────────────────────────────────────────────────────────

set -euo pipefail

log() { echo "[autoflow-community] $*"; }

log "=== Étape 1 : Migrations de base de données ==="
awx-manage migrate --noinput

log "=== Étape 2 : Types de credentials built-in ==="
awx-manage setup_managed_credential_types

log "=== Étape 3 : Données de démo (organisation, inventaire, projet) ==="
# create_preload_data crée l'organisation par défaut et les données initiales.
# Le UserProfile de l'admin en dépend — doit tourner AVANT la création du compte.
awx-manage create_preload_data

log "=== Étape 4 : Création du compte administrateur ==="
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

# Garantit l'existence du UserProfile avant le premier appel /api/v2/me/.
# Sans ça, AWX tente de le créer en concurrence lors du premier chargement
# de l'interface et lève une IntegrityError (duplicate key).
try:
    from awx.main.models import UserProfile
    UserProfile.objects.get_or_create(user=user)
except Exception as e:
    print(f'Note: UserProfile déjà existant ou erreur ignorée : {e}')

action = 'créé' if created else 'mis à jour'
print(f'Compte administrateur \"{username}\" {action}.')
"

log "=== Initialisation terminée — AWX prêt ==="
