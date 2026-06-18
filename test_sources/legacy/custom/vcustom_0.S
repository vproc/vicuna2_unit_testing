# Copyright TU Wien
# Licensed under the Solderpad Hardware License v2.1, see LICENSE.txt for details
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1


    .text
    .global main
main:
    la              a0, vdata_start
    addi            a1, a0, 16

    li              t0, 16
    vsetvli         t0, t0, e8,m4,tu,mu

    li              t0, 1
    vle8.v          v0, (a0)
    vredsum.vs      v4, v0, v0
    #vsetvli         t0, t0, e8,m1,tu,mu
    #vadd.vv         v3, v5, v5
    #vle8.v          v3, (a0)
    #vle8.v          v2, (a0)
    nop
    nop
    .word           0x8031007F
    nop
    nop
    vse8.v          v4, (a1)

    la              a0, vdata_start
    la              a1, vdata_end
    j               spill_cache


    .data
    .align 10
    .global vdata_start
    .global vdata_end
vdata_start:
    .word           0x01010101
    .word           0x01010101
    .word           0x01010101
    .word           0x01010101
vdata_end:

    .align 10
    .global vref_start
    .global vref_end
vref_start:
    .word           0x10010101
    .word           0x01010101
    .word           0x01010101
    .word           0x01010101
vref_end:
