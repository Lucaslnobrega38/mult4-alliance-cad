#!/usr/bin/env python3
"""
gen_test_vectors.py
Gera os 256 casos de teste exaustivos (A de 0-15, B de 0-15) para o
multiplicador 4x4 sem sinal, calculando o produto e o overflow
esperados. Serve como referencia para conferir a simulacao do
circuito (asimut, ou qualquer outro simulador) bit a bit.

Uso:
    python3 gen_test_vectors.py            -> imprime tabela completa
    python3 gen_test_vectors.py --pat      -> gera texto em formato
                                               proximo de um .pat do asimut
"""

import sys


def bits(value, n):
    """retorna string com n bits, MSB primeiro"""
    return format(value, "0{}b".format(n))[::-1]  # LSB primeiro (b0..bn-1)


def main():
    modo_pat = "--pat" in sys.argv

    total = 0
    print(f"{'A':>4} {'B':>4} {'P(esperado)':>12} {'OVF':>4}  A(bin) B(bin) P(bin,P7..P0)")
    for a in range(16):
        for b in range(16):
            p = a * b
            ovf = 1 if p > 15 else 0
            total += 1

            a_bin = format(a, "04b")
            b_bin = format(b, "04b")
            p_bin = format(p, "08b")  # P7..P0

            if modo_pat:
                # exemplo de linha de vetor: a3a2a1a0 b3b2b1b0 -> p7..p0 ovf
                print(f"{a_bin}{b_bin} {p_bin}{ovf}")
            else:
                print(f"{a:>4} {b:>4} {p:>12} {ovf:>4}  {a_bin}   {b_bin}   {p_bin}")

    if not modo_pat:
        print(f"\nTotal de casos testados: {total} (esperado: 256)")


if __name__ == "__main__":
    main()
