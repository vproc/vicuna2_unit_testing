OUTPUT_ARCH( "riscv" )
ENTRY(_start)

MEMORY
{
    boot : ORIGIN = 0x00000000, LENGTH = 0x00002000 /*   8 kB */
    ram  : ORIGIN = 0x00002000, LENGTH = 0x004FE000 /* 248 kB */
}


SECTIONS
{
  .vectors 0 : {
        *(.vectors)
  } >boot

  ._uart_out : ALIGN(1000) { *(._uart_out) } >boot

  .text.init : { *(.text.init) } >ram
  . = ALIGN(0x1000);
  .tohost : { *(.tohost) } >ram
  . = ALIGN(0x1000);
  .text : { *(.text) } >ram
  . = ALIGN(0x1000);
  .data : { *(.data) } >ram
  .bss : { *(.bss) } >ram
  _end = .;
}

