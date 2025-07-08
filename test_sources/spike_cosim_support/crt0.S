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
    j _failure                # failed tests jump here.  Spike failure means total failure of unit test, abort
    ret

    # the reset vector is redirected to _start
    j _start

_failure:
    li t0, 0xFFFFFFFF     #LSB exits spike, all other bits signal failure
    la t1, tohost
    sw t0, 0(t1)
    j _failure

_success:
    li t0, 0x00000001     #LSB exits spike, all other bits signal failure
    la t1, tohost
    sw t0, 0(t1)
    j _success
