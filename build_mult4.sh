#!/bin/sh
# build_mult4.sh - compila mult4.c com genlib e corrige o bug conhecido do
# genlib que gera identificadores VHDL invalidos para conectores em barramento
# (ex: "a(0)" vira "a_0_", com underscore sobrando no final, o que o asimut
# rejeita). Rodar de dentro do container ("./start.sh" primeiro).
#
# Uso: ./build_mult4.sh

set -e

genlib mult4

sed -i \
    -e 's/\ba_0_\b/a_0/g' -e 's/\ba_1_\b/a_1/g' -e 's/\ba_2_\b/a_2/g' -e 's/\ba_3_\b/a_3/g' \
    -e 's/\bb_0_\b/b_0/g' -e 's/\bb_1_\b/b_1/g' -e 's/\bb_2_\b/b_2/g' -e 's/\bb_3_\b/b_3/g' \
    -e 's/\bp_0_\b/p_0/g' -e 's/\bp_1_\b/p_1/g' -e 's/\bp_2_\b/p_2/g' -e 's/\bp_3_\b/p_3/g' \
    -e 's/\bp_4_\b/p_4/g' -e 's/\bp_5_\b/p_5/g' -e 's/\bp_6_\b/p_6/g' -e 's/\bp_7_\b/p_7/g' \
    mult4.vst

echo "mult4.vst gerado e corrigido."
