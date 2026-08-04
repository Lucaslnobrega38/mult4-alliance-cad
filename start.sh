#!/usr/bin/env bash
# start.sh - liga o Docker e entra no ambiente do projeto (mult4 / genlib)
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="alliance-cad"

echo "==> Ligando docker.socket e docker.service..."
sudo systemctl start docker.socket
sudo systemctl start docker

echo "==> Verificando se a imagem '$IMAGE_NAME' existe..."
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    echo "==> Imagem nao encontrada, buildando a partir do Dockerfile..."
    docker build -t "$IMAGE_NAME" "$PROJECT_DIR"
fi

echo "==> Entrando no container (saia com 'exit' para encerrar)..."
docker run -it --rm -v "$PROJECT_DIR":/work -w /work "$IMAGE_NAME" bash

echo "==> Voce saiu do container. Rode ./stop.sh para desligar o docker."
