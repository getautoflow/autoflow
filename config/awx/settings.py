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
SECRET_KEY   = os.environ['AWX_SECRET_KEY']
ALLOWED_HOSTS = ['*']

# HTTP simple (pas de TLS en Community) — désactiver les cookies Secure
CSRF_COOKIE_SECURE    = False
SESSION_COOKIE_SECURE = False

# ── Redis ─────────────────────────────────────────────────────────────────────
_host     = os.environ.get('REDIS_HOST', 'redis')
_port     = os.environ.get('REDIS_PORT', '6379')
_password = os.environ.get('REDIS_PASSWORD', '')

_redis_base = f'redis://:{_password}@{_host}:{_port}' if _password else f'redis://{_host}:{_port}'

CHANNEL_LAYERS = {
    'default': {
        'BACKEND': 'channels_redis.core.RedisChannelLayer',
        'CONFIG': {'hosts': [f'{_redis_base}/0']},
    }
}

CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': f'{_redis_base}/1',
    }
}

BROKER_URL          = f'{_redis_base}/2'
CELERY_RESULT_BACKEND = f'{_redis_base}/2'

# ── Exécution des jobs ────────────────────────────────────────────────────────
# AWX 24+ utilise Docker via le socket bind-monté (pas Podman)
CONTAINER_RUNTIME = 'docker'

DEFAULT_CONTAINER_RUN_OPTIONS = [
    '--network', 'bridge',
]

AWX_ISOLATION_BASE_PATH = os.environ.get('AWX_ISOLATION_BASE_PATH', '/tmp')

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
