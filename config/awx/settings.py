# ──────────────────────────────────────────────────────────────────────────────
# Autoflow Community — AWX settings
# Monté dans le conteneur à /etc/tower/settings.py
# Toutes les valeurs sensibles sont injectées via les variables d'environnement.
# ──────────────────────────────────────────────────────────────────────────────

import os

# ── Base de données ───────────────────────────────────────────────────────────
DATABASES = {
    'default': {
        'ATOMIC_REQUESTS': True,
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('POSTGRES_DB', 'awx'),
        'USER': os.environ.get('POSTGRES_USER', 'awx'),
        'PASSWORD': os.environ['POSTGRES_PASSWORD'],
        'HOST': os.environ.get('DATABASE_HOST', 'postgres'),
        'PORT': os.environ.get('DATABASE_PORT', '5432'),
    }
}

LISTENER_DATABASES = {
    'default': {
        'OPTIONS': {
            'keepalives': 1,
            'keepalives_idle': 5,
            'keepalives_interval': 5,
            'keepalives_count': 5,
        },
    }
}

# ── Sécurité ──────────────────────────────────────────────────────────────────
SECRET_KEY    = os.environ['AWX_SECRET_KEY']
ALLOWED_HOSTS = [h.strip() for h in os.environ.get('AWX_ALLOWED_HOSTS', '*').split(',') if h.strip()]

# HTTP simple (pas de TLS en Community) — cookies non-secure
CSRF_COOKIE_SECURE    = False
SESSION_COOKIE_SECURE = False

# ── Redis ─────────────────────────────────────────────────────────────────────
_host     = os.environ.get('REDIS_HOST', 'redis')
_port     = os.environ.get('REDIS_PORT', '6379')
_password = os.environ.get('REDIS_PASSWORD', '')

_redis_base = f'redis://:{_password}@{_host}:{_port}' if _password else f'redis://{_host}:{_port}'

BROKER_URL = _redis_base + '/0'

CHANNEL_LAYERS = {
    'default': {
        'BACKEND': 'channels_redis.core.RedisChannelLayer',
        'CONFIG': {
            'hosts': [BROKER_URL],
            'capacity': 10000,
            'group_expiry': 157784760,
        },
    }
}

CACHES = {
    'default': {
        'BACKEND': 'awx.main.cache.AWXRedisCache',
        'LOCATION': _redis_base + '/1',
    }
}

# ── Receptor ──────────────────────────────────────────────────────────────────
RECEPTOR_SOCKET_PATH = '/var/run/receptor/receptor.sock'

# ── WebSocket inter-conteneurs (awx_task → awx_web) ──────────────────────────
# AWX production assume HTTPS/443 par défaut.
# En Community on n'a pas de TLS — on force HTTP/80.
BROADCAST_WEBSOCKET_PROTOCOL    = 'http'
BROADCAST_WEBSOCKET_PORT        = 80
BROADCAST_WEBSOCKET_VERIFY_CERT = False

TOWER_URL_BASE = 'http://awxweb'

# ── Branding ──────────────────────────────────────────────────────────────────
LOGOUT_REDIRECT_URL = '/'
LOGIN_URL = '/'

# ── Exécution des jobs ────────────────────────────────────────────────────────
CONTAINER_RUNTIME = 'docker'

DEFAULT_CONTAINER_RUN_OPTIONS = [
    '--network', 'bridge',
]

# Répertoire de base pour les private_data_dir des jobs ansible-runner.
# Doit être un chemin accessible à la fois par awx_task et par le conteneur
# Receptor/EE. '/tmp' est bind-monté depuis l'hôte dans les deux conteneurs,
# ce qui garantit que les chemins sont identiques côté awx_task et côté EE.
AWX_ISOLATION_BASE_PATH = os.environ.get('AWX_ISOLATION_BASE_PATH', '/tmp')

# AWX production.py définit par défaut :
#   AWX_ISOLATION_SHOW_PATHS = [
#       '/etc/pki/ca-trust:/etc/pki/ca-trust:O',
#       '/usr/share/pki:/usr/share/pki:O',
#   ]
# Le mode ':O' est une option Podman (overlay mount). Docker ne le connaît pas
# et échoue avec : "Error response from daemon: invalid mode: O"
# En Community on n'a pas de PKI interne → liste vide, aucun chemin supplémentaire.
AWX_ISOLATION_SHOW_PATHS = []

# ── Logging ───────────────────────────────────────────────────────────────────
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'WARNING',
    },
    'loggers': {
        'awx': {
            'handlers': ['console'],
            'level': os.environ.get('AWX_LOG_LEVEL', 'WARNING'),
            'propagate': False,
        },
    },
}
