#!/usr/bin/env bash
# run.sh - compila (genlib) e simula (asimut) o mult4 dentro do container,
# e imprime as 256 contas (A * B = P) decodificadas do resultado do asimut,
# uma por uma, com [OK]/[FALHOU]. Nao precisa entrar no container
# manualmente: so rodar "./run.sh" (builda a imagem se precisar).
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="alliance-cad"

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
    echo ""
    echo "==> A x B = P (decodificado de mult4_res.pat)"
    echo ""

    ok_count=0
    fail_count=0

    while IFS= read -r line; do
        if [[ "$line" =~ ^\<[[:space:]]*[0-9]+[[:space:]]*ps\>t[0-9]+[[:space:]]*:[[:space:]]*([01u]{10})([^\;]+)\; ]]; then
            ins="${BASH_REMATCH[1]}"
            outs="${BASH_REMATCH[2]//\?/}"

            [[ "$ins" == *u* || "$outs" == *u* ]] && continue

            a=$((2#${ins:2:1}${ins:3:1}${ins:4:1}${ins:5:1}))
            b=$((2#${ins:6:1}${ins:7:1}${ins:8:1}${ins:9:1}))
            p=$((2#${outs:0:8}))
            ovf=${outs:8:1}
            expected=$((a * b))
            expected_ovf=0
            [ "$expected" -gt 15 ] && expected_ovf=1

            if [ "$p" -eq "$expected" ] && [ "$ovf" -eq "$expected_ovf" ]; then
                status="OK"
                ok_count=$((ok_count + 1))
            else
                status="FALHOU (esperado $expected, ovf=$expected_ovf)"
                fail_count=$((fail_count + 1))
            fi

            printf "%2d x %2d = %3d   ovf=%s   [%s]\n" "$a" "$b" "$p" "$ovf" "$status"
        fi
    done < mult4_res.pat

    echo ""
    echo "=================================================="
    echo "  $ok_count / $((ok_count + fail_count)) contas corretas"
    if [ "$fail_count" -eq 0 ]; then
        echo "  RESULTADO: TODOS OS 256 CASOS PASSARAM (0 erros)"
    else
        echo "  RESULTADO: $fail_count erro(s) encontrado(s) - ver acima"
    fi
    echo "=================================================="
'
