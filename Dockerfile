FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    jq \
    bash \
    sudo \
    ca-certificates \
    unzip \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user for devcontainer use
ARG USERNAME=developer
ARG USER_UID=1001
ARG USER_GID=${USER_UID}

RUN groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} \
    && echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

USER ${USERNAME}

# Install Claude Code native binary
RUN curl -fsSL https://claude.ai/install.sh | bash

# Rename real claude binary, install wrapper in its place.
# The wrapper patches IDE lockfile PIDs before exec-ing into claude-real,
# so Claude Code's stale-lockfile check sees its own PID and never deletes it.
RUN mv /home/${USERNAME}/.local/bin/claude /home/${USERNAME}/.local/bin/claude-real

COPY --chown=${USERNAME}:${USERNAME} scripts/claude-wrapper.sh /home/${USERNAME}/.local/bin/claude
RUN chmod +x /home/${USERNAME}/.local/bin/claude

ENV PATH="/home/${USERNAME}/.local/bin:${PATH}"
ENV SHELL=/bin/bash

WORKDIR /workspace

CMD ["bash"]
