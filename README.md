<div align="center">

<img src="https://raw.githubusercontent.com/your-org/autoflow-community/main/docs/logo.png" alt="Autoflow" width="80" />

# Autoflow Community

**AWX sur Docker Compose — déployé en 5 minutes, sans expertise préalable.**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![AWX](https://img.shields.io/badge/AWX-24.6.1-red.svg)](https://github.com/ansible/awx)
[![Docker](https://img.shields.io/badge/Docker-24%2B-blue.svg)](https://docs.docker.com/engine/install/)
[![GitHub Stars](https://img.shields.io/github/stars/your-org/autoflow-community?style=flat)](https://github.com/your-org/autoflow-community/stargazers)
[![GitHub Issues](https://img.shields.io/github/issues/your-org/autoflow-community)](https://github.com/your-org/autoflow-community/issues)

[Site officiel](https://autoflow.io) · [Documentation](https://autoflow.io/docs) · [Version Enterprise](https://autoflow.io/pricing) · [Signaler un bug](https://github.com/your-org/autoflow-community/issues)

</div>

---

## À propos

Autoflow Community est une distribution **prête à l'emploi** d'[AWX](https://github.com/ansible/awx) — l'interface web open-source pour Ansible — packagée avec une image Docker pré-configurée, un `docker-compose.yml` opérationnel et un fichier `.env` documenté.

L'objectif est simple : vous concentrer sur l'automatisation de votre infrastructure, pas sur l'installation d'AWX.

```
$ docker compose up -d
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
| Temps de déploiement | **~5 min** | 2–4 heures | Plusieurs jours |
| Docker Compose ready | ✅ | ❌ (Kubernetes requis) | ❌ |
| Image pré-configurée | ✅ | ❌ (à construire) | ✅ |
| Execution Environments inclus | ✅ | ❌ | ✅ |
| Sans comptage de nœuds | ✅ | ✅ | ❌ (licence par nœud) |
| Gratuit pour toujours | ✅ | ✅ | ❌ (~14 000 €/an) |
| PKI, Gitea, Grafana intégrés | ❌ ([Enterprise](https://autoflow.io/pricing)) | ❌ | Partiel |
| Support commercial | ❌ ([Enterprise](https://autoflow.io/pricing)) | ❌ | ✅ |

---

## Prérequis

| Composant | Version minimale |
|---|---|
| Docker Engine | 24.0+ |
| Docker Compose | v2.20+ |
| OS | Linux x86_64 (Ubuntu 22.04+, Debian 12+, RHEL 8+) |
| RAM | 4 Go minimum, **8 Go recommandés** |
| CPU | 2 vCPU minimum, 4 recommandés |
| Disque | 20 Go libres |

> **Note :** Windows et macOS sont supportés via Docker Desktop, mais non recommandés pour un usage production.

---

## Démarrage rapide

### 1. Cloner le dépôt

```bash
git clone https://github.com/your-org/autoflow-community.git
cd autoflow-community
```

### 2. Configurer l'environnement

```bash
cp .env.example .env
```

Ouvrez `.env` et remplissez **au minimum** ces quatre valeurs :

```dotenv
POSTGRES_PASSWORD=un_mot_de_passe_fort
REDIS_PASSWORD=un_autre_mot_de_passe
AWX_ADMIN_PASSWORD=votre_mot_de_passe_admin
AWX_SECRET_KEY=$(openssl rand -hex 32)
```

> **Important :** Ne réutilisez jamais `AWX_SECRET_KEY` entre environnements. Générez une valeur unique avec `openssl rand -hex 32`.

### 3. Récupérer le GID Docker

Receptor a besoin d'accéder au socket Docker pour lancer les jobs Ansible :

```bash
# Ajoutez la valeur retournée dans votre .env → DOCKER_GID=...
getent group docker | cut -d: -f3
```

### 4. Construire et démarrer

```bash
docker compose up -d
```

La première fois, Docker construit l'image Receptor et initialise la base de données AWX (~3–5 minutes). Suivez la progression :

```bash
docker compose logs -f awx_migrate   # initialisation (migrations + admin)
docker compose logs -f awx_web       # démarrage de l'interface
```

### 5. Accéder à AWX

Une fois `awx_web` en état `healthy` :

```
http://localhost:8080
Identifiant : valeur de AWX_ADMIN_USER  (défaut : admin)
Mot de passe : valeur de AWX_ADMIN_PASSWORD
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
| `AWX_SECRET_KEY` | Clé secrète Django (générer avec `openssl rand -hex 32`) | **obligatoire** |
| `AWX_HTTP_PORT` | Port HTTP exposé sur l'hôte | `8080` |
| `DOCKER_GID` | GID du groupe `docker` sur l'hôte | `998` |

---

## Execution Environments

### C'est quoi un Execution Environment ?

Un **Execution Environment (EE)** est l'image Docker dans laquelle AWX exécute vos playbooks Ansible. Il contient :

- Python et Ansible Core
- Les **collections Ansible** dont vos playbooks ont besoin (`community.general`, `cisco.ios`, `amazon.aws`…)
- Les **dépendances Python** associées (`boto3`, `netmiko`, `pyOpenSSL`…)

L'EE est isolé du reste de la stack. Chaque job AWX tourne dans son propre conteneur éphémère — pas de conflit de dépendances, pas d'effet de bord entre projets.

```
AWX Task
  └── lance un job
        └── docker run <image-EE>
              └── ansible-runner worker
                    └── ansible-playbook site.yml
```

### EE par défaut

L'image Autoflow inclut un EE de base pré-enregistré dans AWX :

| Nom | Collections incluses | Cas d'usage |
|---|---|---|
| `EE Default (Autoflow)` | `ansible.builtin`, `community.general`, `ansible.posix` | Tâches Linux générales |

Vous le trouverez dans AWX sous **Administration → Execution Environments**.

### Utiliser un EE custom

Pour ajouter un EE externe (depuis Docker Hub, GHCR ou votre registry privé) :

1. Dans AWX : **Administration → Execution Environments → Add**
2. Renseignez le champ **Image** avec le nom complet de l'image
3. Si votre registry est privé, ajoutez d'abord un **Credential** de type `Container Registry`

### Construire votre propre EE

Installez [`ansible-builder`](https://ansible-builder.readthedocs.io/) et créez un fichier `execution-environment.yml` :

```yaml
# execution-environment.yml
version: 3

build_arg_defaults:
  ANSIBLE_GALAXY_CLI_COLLECTION_OPTS: '--pre'

dependencies:
  galaxy:
    collections:
      - name: community.general
        version: ">=9.0"
      - name: ansible.posix
      - name: cisco.ios          # Pour l'automatisation réseau Cisco
      - name: community.crypto   # Pour la gestion PKI/TLS

  python:
    - boto3                      # Pour les modules AWS
    - netmiko                    # Pour les équipements réseau
```

Construisez et poussez l'image :

```bash
# Installer ansible-builder
pip install ansible-builder

# Construire l'image
ansible-builder build \
  --tag mon-registry/mon-ee:latest \
  --file execution-environment.yml

# Pousser sur votre registry
docker push mon-registry/mon-ee:latest
```

Puis enregistrez l'image dans AWX comme décrit ci-dessus.

---

## Commandes utiles

```bash
# Vérifier l'état de tous les services
docker compose ps

# Suivre les logs en temps réel
docker compose logs -f

# Redémarrer AWX uniquement
docker compose restart awx_web awx_task

# Arrêter la stack (données conservées)
docker compose stop

# Arrêter et supprimer les conteneurs (données conservées dans les volumes)
docker compose down

# Lancer un shell dans AWX
docker compose exec awx_web bash
```

---

## Mise à jour

### 1. Vérifier les notes de version

Consultez le [CHANGELOG](CHANGELOG.md) avant toute mise à jour.

### 2. Sauvegarder la base de données

```bash
docker compose exec postgres pg_dump \
  -U ${POSTGRES_USER:-awx} ${POSTGRES_DB:-awx} \
  > backup-$(date +%Y%m%d).sql
```

### 3. Mettre à jour l'image

```bash
# Modifier AWX_VERSION dans .env, puis :
docker compose pull
docker compose up -d
```

Les migrations de base de données s'appliquent automatiquement au redémarrage via le service `awx_migrate`.

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                Docker Compose Stack                  │
│                                                      │
│  ┌──────────┐    ┌──────────┐    ┌────────────────┐ │
│  │ awx_web  │    │ awx_task │    │    receptor    │ │
│  │  :8080   │◄───│          │◄───│  (job runner)  │ │
│  └──────────┘    └──────────┘    └────────────────┘ │
│        │               │                 │           │
│  ┌─────┴───────────────┴─────┐  /var/run/docker.sock │
│  │        PostgreSQL          │           │           │
│  │           Redis            │    ┌──────┴──────┐   │
│  └────────────────────────────┘    │  EE Docker  │   │
│                                    │  containers │   │
└─────────────────────────────────────┴─────────────┘
```

- **awx_web** : Interface Django + nginx (UI + API REST)
- **awx_task** : Dispatcher Celery (planification des jobs)
- **receptor** : Moteur d'exécution des playbooks (lance les conteneurs EE via Docker)
- **PostgreSQL** : Base de données principale (inventaires, jobs, credentials…)
- **Redis** : Cache, broker de messages, WebSocket

---

## Support & Communauté

- **Bug ou question ?** → [GitHub Issues](https://github.com/your-org/autoflow-community/issues)
- **Discussions** → [GitHub Discussions](https://github.com/your-org/autoflow-community/discussions)
- **Site officiel** → [autoflow.io](https://autoflow.io)
- **Documentation AWX** → [ansible.readthedocs.io](https://ansible.readthedocs.io/projects/awx/)

### Besoin de plus ?

La **[version Enterprise d'Autoflow](https://autoflow.io/pricing)** ajoute :

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
# Fork + clone
git clone https://github.com/your-org/autoflow-community.git

# Créer une branche
git checkout -b feat/ma-contribution

# Soumettre une Pull Request
```

---

## License

Autoflow Community est distribué sous licence **MIT**. Voir [LICENSE](LICENSE) pour le texte complet.

---

<div align="center">

Fait avec ❤️ par l'équipe [Autoflow](https://autoflow.io) · [autoflow.io](https://autoflow.io)

</div>
