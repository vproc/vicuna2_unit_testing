# Copyright TU Wien
# Licensed under the Solderpad Hardware License v2.1, see LICENSE.txt for details
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1


    .text
    .balign 4
    .global spill_cache
spill_cache:

    #This function has been rewritten to check spike outputs while being compatible with legacy code.
    la a0, vdata_start
    la a1, vdata_end
    la a2, vref_start

loop:
    lw t0, 0(a0)
    lw t1, 0(a2)

    bne t0, t1, _failure

    addi a0, a0, 4
    addi a2, a2, 4

    beq a0, a1, _success
    j loop

