#!/usr/bin/env bash
# stop.sh - desliga o Docker por completo (service + socket), sem deixar
# nenhum processo relacionado rodando em segundo plano.
set -e

echo "==> Parando containers em execucao (se houver)..."
RUNNING=$(docker ps -q 2>/dev/null || true)
if [ -n "$RUNNING" ]; then
    docker stop $RUNNING
fi

echo "==> Parando docker.service..."
sudo systemctl stop docker

echo "==> Parando docker.socket (evita reativacao automatica)..."
sudo systemctl stop docker.socket

echo "==> Status final:"
systemctl is-active docker || true
systemctl is-active docker.socket || true

echo "==> Docker desligado. Nenhum processo do projeto deve estar rodando agora."
echo "==> Conferir com: docker ps -a  (so funciona se voce ligar o docker de novo)"
