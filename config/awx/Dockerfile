# AWX Patched Image — Autoflow Community
# Extends the official AWX image with Docker CLI and CVE fixes.
#
# WHY Docker CLI:
#   ansible-runner invokes the container runtime to launch EE images.
#   CONTAINER_RUNTIME=docker in settings.py requires docker CLI on PATH.
#   We install only the client (not the daemon) — the host socket is bind-mounted.
#
# WHY podman symlink:
#   ansible-runner cleanup calls `podman image prune` unconditionally.
#   Symlinking podman → docker makes it use the host Docker daemon transparently.
#
# Known unfixable CVE:
#   CVE-2024-23342  ecdsa 0.18.0 — Side-channel in ECDH. No upstream fix.
#   AWX uses ecdsa only for SSH key parsing. Risk is LOW (not internet-exposed).

ARG AWX_VERSION=24.6.1
FROM ghcr.io/ansible/awx:${AWX_VERSION}

USER root

# ── Docker CLI ────────────────────────────────────────────────────────────────
RUN dnf install -y dnf-plugins-core && \
    dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo && \
    dnf install -y docker-ce-cli && \
    dnf clean all && rm -rf /var/cache/dnf

RUN ln -sf /usr/bin/docker /usr/local/bin/podman

# ── OS-level security patches ─────────────────────────────────────────────────
RUN dnf upgrade --security -y --nobest --skip-broken && \
    dnf clean all && rm -rf /var/cache/dnf

# ── Python CVE fixes ──────────────────────────────────────────────────────────
# AWX packages live in a dedicated virtualenv — must use its pip.
ENV PIP=/var/lib/awx/venv/awx/bin/pip

RUN $PIP install --no-cache-dir --upgrade "pip>=24.0"

# Group A — independent packages
# setuptools capped at <78 — 78+ removes pkg_resources (used by AWX).
RUN $PIP install --no-cache-dir --upgrade \
    "Django>=4.2.30,<5.0" \
    "setuptools>=75.8.0,<78.0" \
    "sqlparse>=0.5.0" \
    "urllib3>=2.6.3" \
    "PyJWT>=2.12.0" \
    "azure-core>=1.38.0" \
    "wheel>=0.46.2" \
    "protobuf>=4.25.8,<5.0"

# Group B — cryptography + pyOpenSSL (pyOpenSSL 26 requires cryptography>=43)
RUN $PIP install --no-cache-dir --upgrade \
    "cryptography>=43.0.0" \
    "pyOpenSSL>=26.0.0"

# Group C — python-jose (constrains pyasn1<0.5 — accepted trade-off)
RUN $PIP install --no-cache-dir --upgrade \
    "python-jose>=3.4.0"

# Group D — aiohttp (large dependency tree, resolve separately)
RUN $PIP install --no-cache-dir --upgrade \
    "aiohttp>=3.13.3"

RUN /var/lib/awx/venv/awx/bin/python -c "import django, cryptography, urllib3, jose, jwt; print('Django:', django.__version__, '| cryptography:', cryptography.__version__, '| urllib3:', urllib3.__version__, '| jose:', jose.__version__, '| PyJWT:', jwt.__version__)"
