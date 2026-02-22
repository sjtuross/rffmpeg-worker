#!/bin/bash
set -euo pipefail

SSH_USER="${SSH_USER:-ffmpeg}"
SSH_UID="${SSH_UID:-1000}"
SSH_GID="${SSH_GID:-1000}"

if ! [[ "${SSH_UID}" =~ ^[0-9]+$ ]]; then
    echo "ERROR: SSH_UID must be numeric"
    exit 1
fi

if ! [[ "${SSH_GID}" =~ ^[0-9]+$ ]]; then
    echo "ERROR: SSH_GID must be numeric"
    exit 1
fi

echo "Starting container with:"
echo "  User: ${SSH_USER}"
echo "  UID : ${SSH_UID}"
echo "  GID : ${SSH_GID}"

if ! getent group "${SSH_GID}" >/dev/null; then
    groupadd -g "${SSH_GID}" "${SSH_USER}"
fi

if ! id -u "${SSH_USER}" >/dev/null 2>&1; then
    useradd -m -u "${SSH_UID}" -g "${SSH_GID}" -s /bin/bash "${SSH_USER}"
fi

SSH_HOME="/home/${SSH_USER}"
SSH_DIR="${SSH_HOME}/.ssh"
mkdir -p "${SSH_DIR}"
chmod 700 "${SSH_DIR}"

if [ -f /host_ssh/authorized_keys ]; then
    cp /host_ssh/authorized_keys "${SSH_DIR}/authorized_keys"
    chmod 600 "${SSH_DIR}/authorized_keys"
fi

chown -R "${SSH_USER}:${SSH_GID}" "${SSH_DIR}"

sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

exec /usr/sbin/sshd -D
