<div align="center">

<img src="https://raw.githubusercontent.com/getautoflow/autoflow/main/docs/logo.png" alt="Autoflow" width="80" />

# Autoflow Community

**AWX sur Docker Compose — déployé en 5 minutes, sans expertise préalable.**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![AWX](https://img.shields.io/badge/AWX-24.6.1-red.svg)](https://github.com/ansible/awx)
[![Docker](https://img.shields.io/badge/Docker-24%2B-blue.svg)](https://docs.docker.com/engine/install/)
[![GitHub Stars](https://img.shields.io/github/stars/getautoflow/autoflow-community?style=flat)](https://github.com/getautoflow/autoflow-community/stargazers)
[![GitHub Issues](https://img.shields.io/github/issues/getautoflow/autoflow-community)](https://github.com/getautoflow/autoflow-community/issues)

[Site officiel](https://getautoflow.dev) · [Documentation](https://getautoflow.dev/docs) · [Version Enterprise](https://getautoflow.dev/pricing) · [Signaler un bug](https://github.com/getautoflow/autoflow-community/issues)

</div>

---

## À propos

Autoflow Community est une distribution **prête à l'emploi** d'[AWX](https://github.com/ansible/awx) — l'interface web open-source pour Ansible — packagée avec :

- Une **image AWX patchée** (CVE fixes, Docker CLI intégré) construite localement depuis le `Dockerfile` inclus
- Un **`docker-compose.yml`** opérationnel (AWX + PostgreSQL + Redis + Receptor)
- Une **interface de connexion personnalisée** avec logo et thème Autoflow
- Un fichier **`.env` documenté** pour configurer tous les paramètres

L'objectif est simple : vous concentrer sur l'automatisation de votre infrastructure, pas sur l'installation d'AWX.

> **Aucun fichier binaire à télécharger.** Les images Docker sont construites directement sur votre machine depuis les Dockerfiles du dépôt, en s'appuyant sur les images de base officielles publiques.

```
$ docker compose build && docker compose up -d
...
✓ postgres   healthy
✓ redis      healthy
✓ receptor   healthy
✓ awx_web    healthy   → http://localhost:8080
```

---

## Pourquoi Autoflow Community ?

| | **Autoflow Community** | AWX (installation officielle) | Ansible Automation Platform |
|---|:---:|:---:|:---:|
| Temps de déploiement | **~15 min** | 2–4 heures | Plusieurs jours |
| Docker Compose ready | ✅ | ❌ (Kubernetes requis) | ❌ |
| Image patchée (CVE fixes) | ✅ | ❌ (à construire) | ✅ |
| Interface de connexion custom | ✅ | ❌ | ✅ |
| Execution Environments inclus | ✅ | ❌ | ✅ |
| Sans comptage de nœuds | ✅ | ✅ | ❌ (licence par nœud) |
| Gratuit pour toujours | ✅ | ✅ | ❌ (~14 000 €/an) |
| PKI, Gitea, Grafana intégrés | ❌ ([Enterprise](https://getautoflow.dev/pricing)) | ❌ | Partiel |
| Support commercial | ❌ ([Enterprise](https://getautoflow.dev/pricing)) | ❌ | ✅ |

---

## Ce qui est construit localement

Le projet contient deux `Dockerfile` qui sont buildés sur votre machine :

| Image | Dockerfile | Base | Rôle |
|---|---|---|---|
| `autoflow/awx-patched:24.6.1` | `config/awx/Dockerfile` | `ghcr.io/ansible/awx:24.6.1` | AWX Web + Task + Migration |
| `autoflow/receptor-community:local` | `config/receptor/Dockerfile` | `quay.io/ansible/receptor:v1.6.4` | Moteur d'exécution des jobs |

Les images de base sont publiques — **aucun compte ou accès privé requis**.

---

## Prérequis

### Matériel

| Ressource | Minimum | Recommandé (prod) |
|---|---|---|
| RAM | 4 Go | 8 Go |
| CPU | 2 vCPU | 4 vCPU |
| Disque | 20 Go | 60 Go+ (images EE : 1–3 Go chacune) |

### Système d'exploitation

Linux x86_64 — **Ubuntu 22.04 LTS / Debian 12 / RHEL 8+ / Rocky Linux 8+** sont testés.

> Windows et macOS sont supportés via Docker Desktop mais **non recommandés en production**.

### Logiciels requis

Tous ces outils doivent être installés sur la machine hôte avant de commencer.

#### Docker Engine 24+

```bash
# Ubuntu / Debian
curl -fsSL https://get.docker.com | sh

# Vérifier
docker --version        # Docker version 24.x.x ou supérieur
docker compose version  # Docker Compose version v2.20.x ou supérieur
```

> **Important :** Autoflow Community utilise **Docker Compose V2** (plugin intégré à Docker, commande `docker compose`).
> La version autonome `docker-compose` (V1) n'est pas supportée.

#### Ajouter votre utilisateur au groupe docker

```bash
sudo usermod -aG docker $USER
newgrp docker          # appliquer sans se déconnecter

# Vérifier
docker ps              # doit fonctionner sans sudo
```

#### Autres utilitaires système

Ces outils sont présents sur toute distribution Linux standard :

```bash
# Vérifier leur présence
git --version          # ≥ 2.x  — pour cloner le dépôt
curl --version         # ≥ 7.x  — pour les health checks
openssl version        # ≥ 1.1  — pour générer AWX_SECRET_KEY
getent group docker    # outil coreutils — pour obtenir le GID Docker
```

Si l'un d'eux manque :

```bash
# Ubuntu / Debian
sudo apt-get install -y git curl openssl

# RHEL / Rocky / AlmaLinux
sudo dnf install -y git curl openssl
```

#### Python 3 et venv (optionnel — uniquement pour ansible-builder)

**Python n'est pas nécessaire pour faire tourner la stack AWX.** Tout s'exécute dans des conteneurs Docker.

Python est utile uniquement si vous souhaitez construire des **Execution Environments** personnalisés avec `ansible-builder` :

```bash
python3 -m venv ~/ansible-tools
source ~/ansible-tools/bin/activate
pip install ansible-builder awxkit
```

---

## Démarrage rapide

### 1. Cloner le dépôt

```bash
git clone https://github.com/getautoflow/autoflow-community.git
cd autoflow-community
```

### 2. Configurer l'environnement

```bash
cp .env.example .env
chmod 600 .env        # protéger le fichier (contient des secrets)
```

Ouvrez `.env` et remplissez **au minimum** ces quatre valeurs :

```dotenv
POSTGRES_PASSWORD=un_mot_de_passe_fort
REDIS_PASSWORD=un_autre_mot_de_passe
AWX_ADMIN_PASSWORD=votre_mot_de_passe_admin
AWX_SECRET_KEY=     # voir ci-dessous
```

Générez la clé secrète Django :

```bash
openssl rand -hex 32
# copiez la sortie dans AWX_SECRET_KEY=...
```

> **Important :** Ne réutilisez jamais `AWX_SECRET_KEY` entre environnements. Cette clé chiffre les credentials stockés dans AWX.

### 3. Récupérer le GID du groupe Docker

Receptor a besoin d'accéder au socket Docker pour lancer les conteneurs EE :

```bash
getent group docker | cut -d: -f3
# exemple : 998  →  ajoutez DOCKER_GID=998 dans .env
```

### 4. Construire les images

```bash
docker compose build
```

> Le premier build télécharge les images de base officielles et applique les patches CVE.
> **Durée estimée : 10–15 minutes** selon votre connexion et votre machine.
> Les builds suivants sont instantanés (couches mises en cache).

### 5. Démarrer la stack

```bash
docker compose up -d
```

La première fois, AWX initialise la base de données (~3–5 minutes). Suivez la progression :

```bash
docker compose logs -f awx_migrate   # étape 1 : migrations + création admin
docker compose logs -f awx_web       # étape 2 : démarrage interface
```

### 6. Accéder à AWX

Une fois `awx_web` en état `healthy` :

```
http://localhost:8080
Identifiant : valeur de AWX_ADMIN_USER  (défaut : admin)
Mot de passe : valeur de AWX_ADMIN_PASSWORD
```

```bash
# Vérifier que tous les services sont sains
docker compose ps
```

---

## Configuration — référence `.env`

| Variable | Description | Défaut |
|---|---|---|
| `AWX_VERSION` | Version de l'image AWX patchée | `24.6.1` |
| `POSTGRES_DB` | Nom de la base de données | `awx` |
| `POSTGRES_USER` | Utilisateur PostgreSQL | `awx` |
| `POSTGRES_PASSWORD` | Mot de passe PostgreSQL | **obligatoire** |
| `REDIS_PASSWORD` | Mot de passe Redis | **obligatoire** |
| `AWX_ADMIN_USER` | Login du compte administrateur AWX | `admin` |
| `AWX_ADMIN_PASSWORD` | Mot de passe du compte administrateur | **obligatoire** |
| `AWX_ADMIN_EMAIL` | Email du compte administrateur | `admin@example.com` |
| `AWX_SECRET_KEY` | Clé secrète Django — générer avec `openssl rand -hex 32` | **obligatoire** |
| `AWX_ALLOWED_HOSTS` | Hôtes autorisés (virgule-séparés) | `*` |
| `AWX_HTTP_PORT` | Port HTTP exposé sur l'hôte | `8080` |
| `DOCKER_GID` | GID du groupe `docker` sur l'hôte | `998` |

---

## Tuning système (production)

Ces réglages sont **requis en production** pour éviter des avertissements Redis et des problèmes de performance.

### Redis — overcommit mémoire

```bash
# Appliquer immédiatement
sudo sysctl -w vm.overcommit_memory=1
sudo sysctl -w net.core.somaxconn=1024

# Rendre persistant après reboot
echo 'vm.overcommit_memory = 1' | sudo tee -a /etc/sysctl.d/99-autoflow.conf
echo 'net.core.somaxconn = 1024' | sudo tee -a /etc/sysctl.d/99-autoflow.conf
sudo sysctl --system
```

### Désactiver Transparent Huge Pages (THP)

THP dégrade les performances de Redis et PostgreSQL :

```bash
# Appliquer immédiatement
echo never | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
echo never | sudo tee /sys/kernel/mm/transparent_hugepage/defrag

# Rendre persistant (systemd)
sudo tee /etc/systemd/system/disable-thp.service > /dev/null <<'EOF'
[Unit]
Description=Disable Transparent Huge Pages
DefaultDependencies=no
After=sysinit.target local-fs.target
Before=basic.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo never > /sys/kernel/mm/transparent_hugepage/enabled'
ExecStart=/bin/sh -c 'echo never > /sys/kernel/mm/transparent_hugepage/defrag'
RemainAfterExit=yes

[Install]
WantedBy=basic.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now disable-thp.service
```

### Limites de fichiers ouvertes

```bash
# Vérifier la limite actuelle
ulimit -n

# Si < 65536, augmenter dans /etc/security/limits.conf :
echo '* soft nofile 65536' | sudo tee -a /etc/security/limits.conf
echo '* hard nofile 65536' | sudo tee -a /etc/security/limits.conf
```

---

## Reverse proxy HTTPS (production)

En production, **n'exposez jamais AWX directement sur le port 8080 sans TLS**. Placez un reverse proxy devant.

### Option A — nginx + Let's Encrypt (Certbot)

```bash
sudo apt-get install -y nginx certbot python3-certbot-nginx

# Obtenir un certificat
sudo certbot --nginx -d awx.votre-domaine.com
```

Ajoutez ce bloc dans `/etc/nginx/sites-available/awx` :

```nginx
server {
    listen 443 ssl http2;
    server_name awx.votre-domaine.com;

    ssl_certificate     /etc/letsencrypt/live/awx.votre-domaine.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/awx.votre-domaine.com/privkey.pem;

    add_header Strict-Transport-Security "max-age=31536000" always;
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;

    location / {
        proxy_pass         http://127.0.0.1:8080;
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;

        # WebSocket (live output des jobs)
        proxy_http_version 1.1;
        proxy_set_header   Upgrade    $http_upgrade;
        proxy_set_header   Connection "upgrade";
        proxy_read_timeout 86400s;
    }
}

server {
    listen 80;
    server_name awx.votre-domaine.com;
    return 301 https://$host$request_uri;
}
```

```bash
sudo nginx -t && sudo systemctl reload nginx
```

### Option B — Caddy (certificat automatique)

```bash
sudo apt-get install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf https://dl.cloudsmith.io/public/caddy/stable/gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/caddy-stable-archive-keyring.gpg] https://dl.cloudsmith.io/public/caddy/stable/deb/debian any-version main" | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt-get update && sudo apt-get install -y caddy
```

`/etc/caddy/Caddyfile` :

```caddyfile
awx.votre-domaine.com {
    reverse_proxy localhost:8080 {
        header_up X-Forwarded-Proto {scheme}
    }
}
```

```bash
sudo systemctl reload caddy
```

> **Note :** Après avoir configuré le reverse proxy, liez AWX uniquement à localhost : `AWX_HTTP_PORT=127.0.0.1:8080` dans votre `.env`.

---

## Pare-feu

```bash
# UFW (Ubuntu/Debian)
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP (redirection vers HTTPS)
sudo ufw allow 443/tcp   # HTTPS
sudo ufw deny 8080/tcp   # bloquer l'accès direct AWX depuis l'extérieur
sudo ufw enable

# firewalld (RHEL/Rocky)
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --remove-port=8080/tcp
sudo firewall-cmd --reload
```

---

## Sécurité — checklist

- [ ] `.env` protégé en lecture seule : `chmod 600 .env`
- [ ] Mots de passe forts (≥ 20 caractères) pour `POSTGRES_PASSWORD`, `REDIS_PASSWORD`, `AWX_ADMIN_PASSWORD`
- [ ] `AWX_SECRET_KEY` générée avec `openssl rand -hex 32`, unique par environnement
- [ ] `AWX_ALLOWED_HOSTS` restreint au nom de domaine réel (pas `*`) en production
- [ ] AWX derrière un reverse proxy TLS (nginx ou Caddy)
- [ ] Port 8080 fermé depuis l'extérieur (firewall)
- [ ] SSH avec clé uniquement (`PasswordAuthentication no`)
- [ ] Mises à jour système régulières (`apt upgrade` / `dnf update`)
- [ ] Sauvegardes testées et stockées hors du serveur

> **Docker socket :** Receptor et AWX Task montent `/var/run/docker.sock` pour lancer les conteneurs EE.
> Tout processus avec accès à ce socket a les droits root effectif sur l'hôte.
> Assurez-vous que seuls les conteneurs de cette stack y accèdent.

---

## Execution Environments

### C'est quoi un Execution Environment ?

Un **Execution Environment (EE)** est l'image Docker dans laquelle AWX exécute vos playbooks Ansible. Il contient :

- Python et Ansible Core
- Les **collections Ansible** dont vos playbooks ont besoin (`community.general`, `cisco.ios`, `amazon.aws`…)
- Les **dépendances Python** associées (`boto3`, `netmiko`, `pyOpenSSL`…)

### Utiliser un EE externe

Pour ajouter un EE depuis Docker Hub, GHCR ou votre registry privé :

1. Dans AWX : **Administration → Execution Environments → Add**
2. Renseignez le champ **Image** avec le nom complet de l'image
3. Si votre registry est privé, ajoutez d'abord un **Credential** de type `Container Registry`

### Construire votre propre EE

```bash
source ~/ansible-tools/bin/activate

cat > execution-environment.yml <<'EOF'
version: 3

dependencies:
  galaxy:
    collections:
      - name: community.general
      - name: ansible.posix
      - name: cisco.ios

  python:
    - boto3
    - netmiko
EOF

ansible-builder build \
  --tag mon-registry/mon-ee:1.0.0 \
  --file execution-environment.yml

docker push mon-registry/mon-ee:1.0.0
```

---

## Commandes utiles

```bash
# État de tous les services
docker compose ps

# Logs en temps réel
docker compose logs -f

# Logs d'un service spécifique
docker compose logs -f awx_web
docker compose logs -f awx_task
docker compose logs -f receptor

# Redémarrer AWX (sans toucher la base de données)
docker compose restart awx_web awx_task

# Shell dans le conteneur AWX
docker compose exec awx_web bash

# Lancer une commande awx-manage
docker compose exec awx_web awx-manage shell

# Reconstruire les images (après mise à jour du Dockerfile)
docker compose build --no-cache

# Arrêter la stack (données conservées dans les volumes)
docker compose stop

# Arrêter et supprimer les conteneurs (volumes conservés)
docker compose down

# Tout supprimer y compris les volumes — IRRÉVERSIBLE
docker compose down -v
```

---

## Sauvegarde et restauration

### Sauvegarder

```bash
#!/usr/bin/env bash
BACKUP_DIR="/opt/backups/awx"
DATE=$(date +%Y%m%d-%H%M%S)
mkdir -p "$BACKUP_DIR"

# 1. Base de données PostgreSQL
docker compose exec -T postgres pg_dump \
  -U "${POSTGRES_USER:-awx}" "${POSTGRES_DB:-awx}" \
  | gzip > "$BACKUP_DIR/postgres-$DATE.sql.gz"

# 2. Projets AWX
docker run --rm \
  -v autoflow_community_projects:/data \
  -v "$BACKUP_DIR":/backup \
  alpine tar czf "/backup/projects-$DATE.tar.gz" -C /data .

echo "Sauvegarde terminée : $BACKUP_DIR"
ls -lh "$BACKUP_DIR"
```

> Les **credentials AWX** sont chiffrés en base avec `AWX_SECRET_KEY`. Sauvegardez aussi votre `.env`.

### Restaurer la base de données

```bash
docker compose stop awx_web awx_task receptor

gunzip -c /opt/backups/awx/postgres-YYYYMMDD.sql.gz \
  | docker compose exec -T postgres psql \
    -U "${POSTGRES_USER:-awx}" "${POSTGRES_DB:-awx}"

docker compose up -d
```

---

## Mise à jour

### 1. Sauvegarder avant tout

Voir section [Sauvegarde](#sauvegarde-et-restauration) ci-dessus.

### 2. Vérifier les notes de version

Consultez le [CHANGELOG](CHANGELOG.md) avant toute mise à jour majeure.

### 3. Appliquer la mise à jour

```bash
# Mettre à jour AWX_VERSION dans .env, puis reconstruire l'image patchée :
docker compose build --no-cache awx_web
docker compose up -d
```

Les migrations de base de données s'appliquent automatiquement via `awx_migrate` au redémarrage.

### 4. Vérifier

```bash
docker compose ps           # tous les services doivent être healthy
docker compose logs awx_web # vérifier l'absence d'erreurs
```

---

## Architecture

```
Internet
   │  HTTPS :443
   ▼
┌──────────────────┐
│  nginx / Caddy   │  reverse proxy TLS (à configurer sur l'hôte)
│  (hôte Linux)    │
└────────┬─────────┘
         │  HTTP :8080 (loopback)
         ▼
┌─────────────────────────────────────────────────────────────┐
│                    Docker Compose Stack                      │
│                                                              │
│  ┌───────────┐    ┌───────────┐    ┌─────────────────────┐  │
│  │  awx_web  │    │  awx_task │    │      receptor       │  │
│  │ nginx+    │◄──►│  Celery   │◄──►│  (job runner)       │  │
│  │ Django    │    │ dispatcher│    │  ansible-runner      │  │
│  └───────────┘    └───────────┘    └──────────┬──────────┘  │
│        │                │                     │              │
│  ┌─────┴────────────────┴─────┐    /var/run/docker.sock     │
│  │       PostgreSQL 15        │               │              │
│  │       Redis 7              │    ┌──────────▼──────────┐  │
│  └────────────────────────────┘    │  EE containers      │  │
│                                    │  (ephemeral, /tmp)  │  │
└────────────────────────────────────┴─────────────────────┘
```

- **awx_web** — Interface Django + nginx (UI + API REST v2)
- **awx_task** — Dispatcher Celery (planification et suivi des jobs)
- **receptor** — Moteur d'exécution : lance chaque job dans un conteneur EE via le socket Docker
- **awx_migrate** — Service one-shot : migrations DB + création du compte admin (premier démarrage uniquement)
- **PostgreSQL** — Base de données principale (inventaires, credentials, jobs, projets…)
- **Redis** — Cache Django, broker Celery, WebSocket channels

---

## Support & Communauté

- **Bug ou question ?** → [GitHub Issues](https://github.com/getautoflow/autoflow-community/issues)
- **Discussions** → [GitHub Discussions](https://github.com/getautoflow/autoflow-community/discussions)
- **Site officiel** → [getautoflow.dev](https://getautoflow.dev)
- **Documentation AWX** → [ansible.readthedocs.io](https://ansible.readthedocs.io/projects/awx/)
- **Email** → [support@getautoflow.dev](mailto:support@getautoflow.dev)

### Besoin de plus ?

La **[version Enterprise d'Autoflow](https://getautoflow.dev/pricing)** ajoute :

| Fonctionnalité | Community | Enterprise |
|---|:---:|:---:|
| AWX (Ansible Controller) | ✅ | ✅ |
| PKI interne + certificats TLS wildcard | ❌ | ✅ |
| Gitea (SCM intégré) | ❌ | ✅ |
| Grafana + Prometheus + Loki + Tempo | ❌ | ✅ |
| Deploy Wizard interactif | ❌ | ✅ |
| Support air-gap complet | Partiel | ✅ |
| SLA contractuel + support prioritaire | ❌ | ✅ |

---

## Contribuer

Les contributions sont les bienvenues ! Consultez [CONTRIBUTING.md](CONTRIBUTING.md) pour les détails.

```bash
git clone https://github.com/getautoflow/autoflow-community.git
git checkout -b feat/ma-contribution
# Soumettre une Pull Request
```

---

## License

Autoflow Community est distribué sous licence **MIT**. Voir [LICENSE](LICENSE) pour le texte complet.

---

<div align="center">

Fait avec ❤️ par l'équipe [Autoflow](https://getautoflow.dev) · [getautoflow.dev](https://getautoflow.dev)

</div>
