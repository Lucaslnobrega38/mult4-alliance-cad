#!/usr/bin/env bash
# find_delay.sh - empirically finds mult4's propagation delay: runs the full
# 256-case exhaustive suite through asimut at decreasing settle times (the
# gap between forcing inputs and checking outputs) until it starts failing.
# The last settle time with 0 errors is the propagation delay, using the
# real per-cell delays declared in the sxlib .vbe behavioural models
# (all four cells: 1000 ps -- see sxlib/*.vbe).
#
# Usage: ./find_delay.sh [settle_ns_1 settle_ns_2 ...]
#        defaults to a sweep from 20ns down to 9ns.
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="alliance-cad"

if docker info >/dev/null 2>&1; then
    DOCKER="docker"
else
    DOCKER="sudo docker"
fi

VALUES=("$@")
if [ ${#VALUES[@]} -eq 0 ]; then
    VALUES=(20 15 14 13 12 11 10 9)
fi

echo "==> Compilando mult4.vst..."
$DOCKER run --rm -v "$PROJECT_DIR":/work -w /work "$IMAGE_NAME" bash -c './build_mult4.sh' > /dev/null

for settle in "${VALUES[@]}"; do
    python3 "$PROJECT_DIR/gen_pat.py" "$settle" "$PROJECT_DIR/mult4_test_sweep.pat"
    $DOCKER run --rm -v "$PROJECT_DIR":/work -w /work -e MBK_IN_LO=vst \
        -e MBK_CATA_LIB=".:/usr/share/alliance/cells/sxlib" -e VH_MAXERR=100000 \
        "$IMAGE_NAME" bash -c 'asimut mult4 mult4_test_sweep mult4_res_sweep > /dev/null 2>&1 || true'
    errs=$($DOCKER run --rm -v "$PROJECT_DIR":/work -w /work "$IMAGE_NAME" \
        bash -c 'grep -c "error on" mult4_res_sweep.pat || true')
    printf "settle=%3sns  errors=%s\n" "$settle" "$errs"
done

rm -f "$PROJECT_DIR/mult4_test_sweep.pat" "$PROJECT_DIR/mult4_res_sweep.pat"
