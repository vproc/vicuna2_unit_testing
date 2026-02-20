.section .text
.global main

main:
    la      s2, vdata_start
    #set SEW=32 and VL=4
    addi t0, x0, 4
    vsetvli t0, t0, e32, m1, ta, ma
    #load with stride 1 byte, SEW=32
    vle8.v   v19, (s2)
    #store with stride 4 byte, SEW=32
    vse32.v v19, (s2)
    # ----------------------------------------------------------------

    # ====================================================================
    # END OF TEST
    # ====================================================================
    # Load vdata boundaries for cache spill and verification
    la              a0, vdata_start
    la              a1, vdata_end
    j               spill_cache

# ====================================================================
# DATA SECTION
# ====================================================================
.data
.align 4
.global vdata_start
.global vdata_end
vdata_start:
    .word 0x04030201
    .word 0xFFFFFFFF
    .word 0xFFFFFFFF
    .word 0xFFFFFFFF
vdata_end:

# ====================================================================
# REFERENCE SECTION
# ====================================================================
.align 4
.global vref_start
.global vref_end

vref_start:
.align 4
    .word 0x04030201
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
vref_end:
