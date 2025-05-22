# Copyright TU Wien
# Licensed under the Solderpad Hardware License v2.1, see LICENSE.txt for details
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1


    .section .vectors, "ax", @progbits
    .option norvc;

    # redirect all interrupts to the execption wrapper
    .rept 29
    nop
    .endr
    nop
    jalr x0, 0(x7)                # failed tests jump here.  Return to execution after success signal (stored in x7)
    ret                           # successful tests jump here.  Return to execution
    # the reset vector is redirected to _start
    j _start



    .section .text
