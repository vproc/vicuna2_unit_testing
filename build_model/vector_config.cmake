###
# Set configurations of the system here.  This is imported into CMAKE
###

#Currently Supported: rv32im, rv32im_zve32x, rv32imf, rv32imf_zhf, rv32imf_zve32x, rv32imf_zve32f
set(RISCV_ARCH rv32im_zve32x CACHE STRING "Specify the configuration")

#Currently Supported: cv32e40x, cv32a60x
set(SCALAR_CORE "cv32a60x")

set(VPROC_PIPELINES "${VMEM_W}:VLSU 32:VELEM,VSLD,VDIV,VALU,VMUL")
set(VREG_W 128)
set(VMEM_W 32)