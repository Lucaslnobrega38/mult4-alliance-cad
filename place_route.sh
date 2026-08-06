#!/usr/bin/env bash
# place_route.sh - places (ocp) and routes (nero) mult4.vst into a physical
# layout (mult4.ap), the same one shown in docs/img/layout.png (captured
# from graal). Needs mult4.vst to already exist (./build_mult4.sh first).
#
# Uso: ./place_route.sh
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="alliance-cad"

if docker info >/dev/null 2>&1; then
    DOCKER="docker"
else
    DOCKER="sudo docker"
fi

$DOCKER run --rm -v "$PROJECT_DIR":/work -w /work \
    -e RDS_TECHNO_NAME=/etc/cmos.rds \
    -e MBK_CATA_LIB=".:/usr/share/alliance/cells/sxlib" \
    -e MBK_IN_LO=vst -e MBK_OUT_LO=vst -e MBK_IN_PH=ap -e MBK_OUT_PH=ap \
    "$IMAGE_NAME" bash -c '
        set -e
        echo "-> ocp (posicionamento)..."
        alliance-ocp -c mult4 mult4_p
        echo "-> nero (roteamento, 2 camadas de metal)..."
        nero -V -2 -p mult4_p mult4 mult4
        echo "[OK] mult4.ap gerado"
    '

echo ""
echo "Para visualizar: entre no container (./start.sh) e rode"
echo "  graal -l mult4"
echo "(precisa de um display X - veja o README para rodar headless com Xvfb)"
