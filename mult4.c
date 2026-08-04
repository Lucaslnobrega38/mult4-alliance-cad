/*
 * mult4.c -- 4x4 unsigned array multiplier with overflow flag
 *
 * Structural netlist for Alliance CAD's genlib (procedural generation,
 * sxlib standard cells). 16 AND2 gates build the partial-product matrix
 * pp[i][j] = a[i] & b[j]; half/full adders sum its diagonals into P[7:0];
 * OVF = P4 | P5 | P6 | P7 (product doesn't fit in 4 bits).
 */

#include "genlib.h"

#define NB 4

/* 2-input gate instance (model: a2_x2, xr2_x1, o2_x2 in sxlib) */
static void gate2(model, inst, in1, in2, out)
    char *model, *inst, *in1, *in2, *out;
{
    GENLIB_LOINS(model, inst, in1, in2, out, "vdd", "vss", NULL);
}

/* 1-input gate instance (buf_x2) */
static void gate1(model, inst, in1, out)
    char *model, *inst, *in1, *out;
{
    GENLIB_LOINS(model, inst, in1, out, "vdd", "vss", NULL);
}

/* half adder: sum = a^b, carry = a&b */
static void halfadder(tag, a, b, sum, carry)
    char *tag, *a, *b, *sum, *carry;
{
    char inst[64];

    sprintf(inst, "ha_%s_xor", tag);
    gate2("xr2_x1", inst, a, b, sum);

    sprintf(inst, "ha_%s_and", tag);
    gate2("a2_x2", inst, a, b, carry);
}

/* full adder: two half adders + one OR2 for carry-out */
static void fulladder(tag, a, b, cin, sum, carry)
    char *tag, *a, *b, *cin, *sum, *carry;
{
    char s1[32], c1[32], c2[32], inst[64], tag2[64];

    sprintf(s1, "fa_%s_s1", tag);
    sprintf(c1, "fa_%s_c1", tag);
    sprintf(c2, "fa_%s_c2", tag);

    GENLIB_LOSIG(s1);
    GENLIB_LOSIG(c1);
    GENLIB_LOSIG(c2);

    halfadder(tag, a, b, s1, c1);

    sprintf(tag2, "%s_b", tag);
    halfadder(tag2, s1, cin, sum, c2);

    sprintf(inst, "fa_%s_or", tag);
    gate2("o2_x2", inst, c1, c2, carry);
}

main()
{
    int i, j, k;
    char pp[4][4][32];
    char s1[4][32], c1[4][32];
    char s2[4][32], c2[4][32];
    char s3[4][32], c3[4][32];
    char cf[4][32];
    char p[8][32];
    char aname[16], bname[16], gname[32], pinname[16];

    GENLIB_DEF_LOFIG("mult4");

    GENLIB_LOCON("vdd", IN, "vdd");
    GENLIB_LOCON("vss", IN, "vss");

    for (i = 0; i < NB; i++) {
        sprintf(aname, "a(%d)", i);
        GENLIB_LOCON(aname, IN, aname);

        sprintf(bname, "b(%d)", i);
        GENLIB_LOCON(bname, IN, bname);
    }

    /* the bus must exist before any instance drives one of its bits */
    GENLIB_BUS("p", 0, 7);

    for (k = 0; k < 8; k++) {
        sprintf(pinname, "p(%d)", k);
        GENLIB_LOCON(pinname, OUT, pinname);
    }

    GENLIB_LOCON("ovf", OUT, "ovf");

    /* partial products: pp[i][j] = a[i] & b[j] */
    for (i = 0; i < NB; i++) {
        for (j = 0; j < NB; j++) {
            sprintf(pp[i][j], "pp_%d_%d", i, j);
            GENLIB_LOSIG(pp[i][j]);

            sprintf(aname, "a(%d)", i);
            sprintf(bname, "b(%d)", j);
            sprintf(gname, "and_%d_%d", i, j);

            gate2("a2_x2", gname, aname, bname, pp[i][j]);
        }
    }

    sprintf(p[0], "%s", pp[0][0]);

    /* row 1: half adders */
    for (k = 0; k < 3; k++) {
        char tag[16];
        sprintf(s1[k], "s1_%d", k);
        sprintf(c1[k], "c1_%d", k);
        GENLIB_LOSIG(s1[k]);
        GENLIB_LOSIG(c1[k]);
        sprintf(tag, "r1_%d", k);
        halfadder(tag, pp[0][k + 1], pp[1][k], s1[k], c1[k]);
    }
    sprintf(p[1], "%s", s1[0]);

    /* row 2: full adders */
    sprintf(s2[0], "s2_0"); sprintf(c2[0], "c2_0");
    GENLIB_LOSIG(s2[0]); GENLIB_LOSIG(c2[0]);
    fulladder("r2_0", s1[1], pp[2][0], c1[0], s2[0], c2[0]);

    sprintf(s2[1], "s2_1"); sprintf(c2[1], "c2_1");
    GENLIB_LOSIG(s2[1]); GENLIB_LOSIG(c2[1]);
    fulladder("r2_1", s1[2], pp[2][1], c1[1], s2[1], c2[1]);

    sprintf(s2[2], "s2_2"); sprintf(c2[2], "c2_2");
    GENLIB_LOSIG(s2[2]); GENLIB_LOSIG(c2[2]);
    fulladder("r2_2", pp[1][3], pp[2][2], c1[2], s2[2], c2[2]);

    sprintf(p[2], "%s", s2[0]);

    /* row 3: full adders */
    sprintf(s3[0], "s3_0"); sprintf(c3[0], "c3_0");
    GENLIB_LOSIG(s3[0]); GENLIB_LOSIG(c3[0]);
    fulladder("r3_0", s2[1], pp[3][0], c2[0], s3[0], c3[0]);

    sprintf(s3[1], "s3_1"); sprintf(c3[1], "c3_1");
    GENLIB_LOSIG(s3[1]); GENLIB_LOSIG(c3[1]);
    fulladder("r3_1", s2[2], pp[3][1], c2[1], s3[1], c3[1]);

    sprintf(s3[2], "s3_2"); sprintf(c3[2], "c3_2");
    GENLIB_LOSIG(s3[2]); GENLIB_LOSIG(c3[2]);
    fulladder("r3_2", pp[2][3], pp[3][2], c2[2], s3[2], c3[2]);

    sprintf(p[3], "%s", s3[0]);

    /* final row: ripple-carry merge into P4..P7 */
    sprintf(p[4], "p_4_int"); sprintf(cf[0], "cf_0");
    GENLIB_LOSIG(p[4]); GENLIB_LOSIG(cf[0]);
    fulladder("rf_0", s3[1], c3[0], "vss", p[4], cf[0]);

    sprintf(p[5], "p_5_int"); sprintf(cf[1], "cf_1");
    GENLIB_LOSIG(p[5]); GENLIB_LOSIG(cf[1]);
    fulladder("rf_1", s3[2], c3[1], cf[0], p[5], cf[1]);

    sprintf(p[6], "p_6_int"); sprintf(cf[2], "cf_2");
    GENLIB_LOSIG(p[6]); GENLIB_LOSIG(cf[2]);
    fulladder("rf_2", pp[3][3], c3[2], cf[1], p[6], cf[2]);

    sprintf(p[7], "%s", cf[2]);

    for (k = 0; k < 8; k++) {
        char inst[32];
        sprintf(pinname, "p(%d)", k);

        sprintf(inst, "buf_p%d", k);
        gate1("buf_x2", inst, p[k], pinname);
    }

    /* overflow = OR(P4, P5, P6, P7) */
    GENLIB_LOSIG("ovf1");
    GENLIB_LOSIG("ovf2");
    gate2("o2_x2", "or_ovf_1", p[4], p[5], "ovf1");
    gate2("o2_x2", "or_ovf_2", p[6], p[7], "ovf2");
    gate2("o2_x2", "or_ovf_3", "ovf1", "ovf2", "ovf");

    GENLIB_SAVE_LOFIG();
}
