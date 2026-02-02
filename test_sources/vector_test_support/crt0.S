# Copyright TU Wien
# Licensed under the Solderpad Hardware License v2.1, see LICENSE.txt for details
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1


    .section .vectors, "ax", @progbits
    .option norvc;

    # redirect all interrupts to the execption wrapper (Should be caught by simulation and exit)
    .rept 28
    nop
    .endr
    j 0x00000070
    nop
    nop
    nop
    # the reset vector is redirected to _start
    j _start



#test success/failure uses UART
    .section ._uart_out, "ax", @progbits
    .option norvc;
    .global uart_data
    .global uart_status
uart_data:
    .word           0x00000000
uart_status:  #no uart recieve currently supported, and uart write is always valid
    .word           0x00000000

