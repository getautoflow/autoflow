# Receptor — custom image for Autoflow
# Extends the official receptor image with Docker CLI + podman compatibility.
#
# WHY: AWX hardcodes `process_isolation_executable: podman` in jobs.py.
# In a Docker Compose stack, Podman is not available. The symlink makes
# `podman` resolve to `docker`, which uses the host Docker daemon via the
# bind-mounted socket at /var/run/docker.sock.
#
# REQUIRES in docker-compose.yml:
#   - /var/run/docker.sock:/var/run/docker.sock   (host Docker daemon)
#   - /tmp:/tmp                                   (DinD path consistency)

FROM quay.io/ansible/receptor:v1.6.4

USER root

# Install Docker CLI — static build from Docker, no shared-lib dependencies.
# We only install the client (not the daemon — we use the host socket).
ARG DOCKER_VERSION=27.3.1
RUN curl -fsSL "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz" \
    | tar xz --strip=1 -C /usr/local/bin docker/docker && \
    chmod +x /usr/local/bin/docker

# Podman compatibility wrapper — AWX hardcodes "podman" and passes Podman-specific
# flags (e.g. --network slirp4netns:...) that Docker rejects.
# The wrapper translates those flags to Docker equivalents before exec'ing docker.
COPY podman-wrapper.sh /usr/local/bin/podman
RUN chmod +x /usr/local/bin/podman

# Verify
RUN docker --version && podman --version
