#include "genlib.h"
main()
{
    GENLIB_DEF_LOFIG("mini");
    GENLIB_LOCON("i0", IN, "i0");
    GENLIB_LOCON("i1", IN, "i1");
    GENLIB_LOCON("q", OUT, "q");
    GENLIB_LOINS("a2_x2", "and1", "i0", "i1", "q", "vdd", "vss", NULL);
    GENLIB_SAVE_LOFIG();
}
