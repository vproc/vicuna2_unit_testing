###
# Set configurations of the system here.  This is imported into CMAKE
###

#Currently Supported: rv32im, rv32im_zve32x, rv32imf, rv32imf_zhf, rv32imf_zve32x, rv32imf_zve32f
set(RISCV_ARCH rv32im_zve32x CACHE STRING "Specify the configuration")

set(VREG_W 128)
set(VMEM_W 32)
set(VPROC_PIPELINES "${VMEM_W}:VLSU 64:VELEM,VSLD,VDIV,VALU,VMUL")
