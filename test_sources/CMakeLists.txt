#####
# File to build and include all Vector Unit Tests from the ChipsAlliance suite
#####
include(${CMAKE_TOP}/add_test.cmake)
#####
# Create ASM files for RISCV Tests
#####

if (BUILD_TEST_SOURCE)
    # Set environment override values to generate correct set of tests and use correct RISCV GCC
    set(ENV{RISCV} "${TOOLCHAIN_TOP}/riscv-isa-sim/riscv")
    set(ENV{RISCV_PREFIX} "${RISCV_GCC_BASENAME}-")
    set(ENV{GCC_PATH} "${RISCV_GCC_PREFIX}/bin/")
    set(ENV{PATH} "${RISCV_GCC_PREFIX}/bin/:${TOOLCHAIN_TOP}/riscv-isa-sim/riscv/bin:$ENV{PATH}")
    set(ENV{RISCV_ARCH} ${RISCV_ARCH})
    set(ENV{MABI} ${RISCV_ABI})
    set(ENV{VARCH} zvl${VREG_W}b)

    execute_process(COMMAND echo $ENV{PATH}
                    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/riscv-vector-tests/)     

    execute_process(COMMAND make all -j$ENV{nproc} --environment-overrides VLEN=${VREG_W} XLEN=32 INTEGER=${INTEGER} MARCH=${RISCV_ARCH}
                    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/riscv-vector-tests/)
endif()               


######
# Add Tests
######

file(GLOB files "${CMAKE_CURRENT_SOURCE_DIR}/riscv-vector-tests/out/v${VREG_W}x32machine/tests/stage2/*.S" )
foreach(item ${files})
    string(REPLACE ".S" "" test_name ${item})
    string(REPLACE "${CMAKE_CURRENT_SOURCE_DIR}/riscv-vector-tests/out/v${VREG_W}x32machine/tests/stage2/" "" test_name ${test_name})
    add_unit_test(${test_name})
endforeach()