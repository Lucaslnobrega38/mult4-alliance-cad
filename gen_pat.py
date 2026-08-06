#!/usr/bin/env python3
"""
gen_pat.py -- generates mult4_test.pat: the exhaustive 256-case asimut
pattern file, force+check pair per case, with a configurable settle time
between forcing inputs and checking outputs (see find_delay.sh, which
uses this to binary-search the propagation delay).

Usage: python3 gen_pat.py <settle_ns> [output_file]
"""
import sys

settle = int(sys.argv[1])
out_path = sys.argv[2] if len(sys.argv) > 2 else "mult4_test.pat"

lines = []
lines.append(f"-- exhaustive test, {settle}ns settle time between force and check")
lines.append("in vdd;")
lines.append("in vss;")
for n in ["a_3", "a_2", "a_1", "a_0", "b_3", "b_2", "b_1", "b_0"]:
    lines.append(f"in {n};")
for n in ["p_7", "p_6", "p_5", "p_4", "p_3", "p_2", "p_1", "p_0", "ovf"]:
    lines.append(f"out {n};")
lines.append("")
lines.append("begin")

t = 0
idx = 0
skip9 = " ".join(["*"] * 9)
for a in range(16):
    for b in range(16):
        p = a * b
        ovf = 1 if p > 15 else 0
        a_bits = " ".join(format(a, "04b"))
        b_bits = " ".join(format(b, "04b"))
        ins = f"1 0 {a_bits} {b_bits}"
        p_bits = format(p & 0xFF, "08b")
        outs = " ".join("?" + c for c in p_bits) + " ?" + str(ovf)

        lines.append(f"< {t} ns > f{idx} : {ins} {skip9};")
        t += settle
        lines.append(f"< {t} ns > t{idx} : {ins} {outs};")
        t += settle
        idx += 1

lines.append("end;")

with open(out_path, "w") as f:
    f.write("\n".join(lines) + "\n")
