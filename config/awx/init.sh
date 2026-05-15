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

log "=== Étape 4 : Données de démo (organisation, inventaire, projet) ==="
# create_preload_data nécessite un superuser existant — doit tourner APRÈS l'étape 3.
awx-manage create_preload_data

log "=== Étape 5 : Enregistrement des Execution Environments par défaut ==="
# Obligatoire : sans EE enregistré, le endpoint /api/v2/instance_groups/
# lève une RuntimeError sur la requête OPTIONS et renvoie 500 au navigateur.
awx-manage register_default_execution_environments

log "=== Étape 6 : Politique de pull EE → 'missing' ==="
# Par défaut AWX enregistre les EE built-in avec pull='always', ce qui force
# un docker pull ghcr.io/ansible/awx-ee:latest à chaque lancement de job.
# Si le registry est lent ou inaccessible, le job reste en "pending" jusqu'au
# timeout. On force 'missing' : l'image n'est tirée que si absente localement.
awx-manage shell -c "
from awx.main.models import ExecutionEnvironment
n = ExecutionEnvironment.objects.filter(pull='always').update(pull='missing')
print(f'[init] EE pull policy: {n} EE(s) mis à jour → pull=missing')
"

log "=== Étape 7 : Pré-téléchargement de l'image EE de base ==="
# Tire l'image maintenant (pendant l'init, pas pendant le premier job) pour
# éviter tout délai ou échec réseau au moment du dispatch.
# On utilise 'docker pull' si Docker est disponible, sinon on ignore.
AWX_EE_IMAGE="ghcr.io/ansible/awx-ee:latest"
if command -v docker &>/dev/null; then
    log "docker pull ${AWX_EE_IMAGE} ..."
    docker pull "${AWX_EE_IMAGE}" && log "Image EE pré-téléchargée ✔" \
        || log "WARN: docker pull échoué — le premier job tentera lui-même (réseau ?)"
else
    log "WARN: docker non disponible dans ce conteneur — pull ignoré."
fi

log "=== Initialisation terminée — AWX prêt ==="
