#!/usr/bin/env bash
# run.sh - compila (genlib) e simula (asimut) o mult4 dentro do container,
# e mostra o resultado de forma resumida. Nao precisa entrar no container
# manualmente: so rodar "./run.sh" depois do "./start.sh" ter sido usado
# ao menos uma vez (ou nem isso - este script builda a imagem se precisar).
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="alliance-cad"

# usa "docker" direto se o usuario tiver permissao; senao cai pra "sudo docker"
if docker info >/dev/null 2>&1; then
    DOCKER="docker"
else
    DOCKER="sudo docker"
fi

echo "==> Ligando docker.socket e docker.service..."
sudo systemctl start docker.socket
sudo systemctl start docker

echo "==> Verificando se a imagem '$IMAGE_NAME' existe..."
if ! $DOCKER image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    echo "==> Imagem nao encontrada, buildando a partir do Dockerfile..."
    $DOCKER build -t "$IMAGE_NAME" "$PROJECT_DIR"
fi

echo "==> Compilando (genlib) e simulando (asimut) mult4..."
echo ""

$DOCKER run --rm -v "$PROJECT_DIR":/work -w /work "$IMAGE_NAME" bash -c '
    set -e
    ./build_mult4.sh
    echo ""
    echo "==> Rodando simulacao exaustiva (256 casos)..."
    asimut mult4 mult4_test mult4_res > run.log 2>&1
    ERRS=$(grep -c "error on" mult4_res.pat || true)
    echo ""
    echo "=================================================="
    if [ "$ERRS" -eq 0 ]; then
        echo "  RESULTADO: TODOS OS 256 CASOS PASSARAM (0 erros)"
    else
        echo "  RESULTADO: $ERRS erro(s) encontrado(s)"
        echo ""
        echo "  Primeiros erros:"
        grep -B1 "error on" mult4_res.pat | head -30
        echo ""
        echo "  (log completo em run.log, resultado completo em mult4_res.pat)"
    fi
    echo "=================================================="
'
