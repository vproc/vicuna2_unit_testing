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


.section ._start, "ax", @progbits
.global _start
.global _failure
.global _success
.option norvc;
.align 2
_start:
    csrr            a0, mstatus
    li              a1, 0x00002200      #Init FS bits to enable F-EXT and VS bits to enable V-EXT
    or              a0, a0, a1
    csrw            mstatus, a0
    j main

_failure:
.align 2
    li t0, 0xFFFFFFFF     #LSB exits spike, all other bits signal failure
    la t1, tohost
    sw t0, 0(t1)
    j _failure

_success:
.align 2
    li t0, 0x00000001     #LSB exits spike, all other bits signal failure
    la t1, tohost
    sw t0, 0(t1)
    j _success

    .section ._uart_out, "ax", @progbits
    .option norvc;
    .global tohost
    .global fromhost
    .align 16
tohost:
    .word           0x00000000
fromhost:
    .word           0x00000000
