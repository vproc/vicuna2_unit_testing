cmake_minimum_required(VERSION 3.10)
message(STATUS "CMake Version ${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION}.${CMAKE_PATCH_VERSION}")

##########################
#
# Configuration variables:
# - RV_ARCH : select the processor architecture configuration for compilation
#
# FEATURES:
# - SPIKE : enable reference checking with Spike. (Some tests cause issues, believed to be bugs with Spike)
# - TRACE : enables .csv memory trace and .vcd signal trace output for unit tests.  Due to large file sizes, only trace of last test run will be kept.  Will be located in /build/Testing
#
#
##########################

set(MEM_LATENCY 1 CACHE STRING "Memory latency")
set(INTEGER 0 CACHE STRING "Variable for ChipsAlliance Tests to build only integer vector tests")

option(TRACE        "Enable trace outputs"                                         OFF)
option(SPIKE        "Enable Spike Cosim"                                           OFF)
option(PRINT        "Enable print statements"                                      OFF)

option(LEGACY       "Use Legacy unit tests"                                        OFF)
option(BUILD_TEST_SOURCE "Build ChipsAlliance Tests from source.  Can skip if already build for chosen configuration" ON)


#####
# Default Paths to Subdirectories
#####

set(BUILD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/build)
set(MODEL_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../build_model/build)
set(TEST_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/../test_sources)
set(BSP_TOP ${CMAKE_CURRENT_SOURCE_DIR}/../bsp)
set(CMAKE_TOP ${CMAKE_CURRENT_SOURCE_DIR}/../CMake)
set(TOOLCHAIN_TOP ${CMAKE_CURRENT_SOURCE_DIR}/../toolchain)
set(SPIKE_DIR ${TOOLCHAIN_TOP}/riscv-isa-sim/build/)
set(SCRIPTS_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../scripts/)

string(REPLACE "/build_tests" "" REPO_TOP ${CMAKE_CURRENT_SOURCE_DIR})


########
## Import RTL configuration from here instead of command line.
## File shared with program compliation.
########
include(${MODEL_DIR}/../vector_config.cmake)
set(ENV{VPROC_PIPELINES} ${VPROC_PIPELINES})
message("Selected VPROC_PIPELINES = ${VPROC_PIPELINES}")
message("Selected RISCV_ARCH = ${RISCV_ARCH}")
message("Selected VREG_W = ${VREG_W}")
message("Selected VMEM_W = ${VMEM_W}")
set(MEM_W ${VMEM_W})
message("Selected MEM_W = ${MEM_W}")


#####
# Select RISCV_ARCH and RISCV_ABI and Autovectorization flags based on selected features
#####

#These control benchmark configurations specific to the selected RISCV_ARCH
option(RISCV_F "Use the RISC-V F Extension" OFF)
option(RISCV_ZFH "Use the RISC-V ZFH Extension" OFF)
option(RISCV_ZVE32X "Use the RISC-V Embedded V Extension" OFF)
option(RISCV_ZVE32F "Use the RISC-V Embedded V Float Extension" OFF)
option(RISCV_ZVFH "Use the RISC-V V Half Float Extension" OFF)
option(RISCV_ZVBB "Use the RISC-V V Basic Bit-manipulation" OFF)
option(RISCV_ZVBC "Use the RISC-V V Carryless Multiplication" OFF)

if(${RISCV_ARCH} STREQUAL "rv32im") 
    set(RISCV_ABI ilp32)

    
elseif(${RISCV_ARCH} STREQUAL "rv32imf")
    set(RISCV_ABI ilp32f)  
    set(RISCV_F ON)
    
elseif(${RISCV_ARCH} STREQUAL "rv32imf_zfh")
    set(RISCV_ABI ilp32f)  
    set(RISCV_F ON)
    set(RISCV_ZFH ON)
    
elseif(${RISCV_ARCH} STREQUAL "rv32im_zve32x")
    set(RISCV_ABI ilp32) 
    set(RISCV_ZVE32X ON)
    set(INTEGER 1)
    
elseif(${RISCV_ARCH} STREQUAL "rv32imf_zve32f")
    set(RISCV_ABI ilp32f) 
    set(RISCV_ZVE32X ON)
    set(RISCV_ZVE32F ON)
    set(RISCV_F ON)
    
elseif(${RISCV_ARCH} STREQUAL "rv32imf_zfh_zve32f_zvfh")
    set(RISCV_ABI ilp32f) 
    set(RISCV_ZVE32X ON)
    set(RISCV_ZVE32F ON)
    set(RISCV_ZFH ON)
    set(RISCV_F ON)
    set(RISCV_ZVFH ON)

elseif(${RISCV_ARCH} STREQUAL "rv32im_zve32x_zvbb")
    set(RISCV_ABI ilp32) 
    set(RISCV_ZVE32X ON)
    set(RISCV_ZVBB ON)
    set(INTEGER 1)

elseif(${RISCV_ARCH} STREQUAL "rv32im_zve32x_zvbc")
    set(RISCV_ABI ilp32) 
    set(RISCV_ZVE32X ON)
    set(RISCV_ZVBC ON)
    set(INTEGER 1)

elseif(${RISCV_ARCH} STREQUAL "rv32im_zve32x_zvbb_zvbc")
    set(RISCV_ABI ilp32) 
    set(RISCV_ZVE32X ON)
    set(RISCV_ZVBB ON)
    set(RISCV_ZVBC ON)
    set(INTEGER 1)
    

else()
    message(FATAL_ERROR "Unsupported RISCV_ARCH selected")
    
endif()

set(RISCV_CMODEL "medany" CACHE STRING "mcmodel argument to the compiler")


#####
#Set LLVM 18 as the Compiler
#####

# Tell CMake about our processor
set(CMAKE_SYSTEM_PROCESSOR ${RISCV_ARCH})
# The Generic system name is used for bare-metal targets (without OS) in CMake
set(CMAKE_SYSTEM_NAME Generic)


set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_SOURCE_DIR}/../CMake/GCC_toolchain.cmake")

####
# Set build mode, Release by default
####
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE RELEASE)
endif()

if(PRINT)
  add_definitions(-DPRINT_OUTPUTS)
endif()


####
# Set some compiler options for easier debug or faster builds
####

# See whats going in CMake while getting the build process up and running
set(CMAKE_VERBOSE_MAKEFILE ON)

# Using C and C++ 11
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 11)

set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -O3 -g -ggdb")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -O3 -g -ggdb")
set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -O3")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Wextra -Wshadow -Wno-format -std=c11") 
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -std=c++11")


#####################
# Setup the CMake Project
####################

set(CMAKE_EXECUTABLE_SUFFIX_C .elf)
set(CMAKE_EXECUTABLE_SUFFIX_CXX .elf)
set(CMAKE_EXECUTABLE_SUFFIX_ASM .elf) 
set(CMAKE_EXECUTABLE_SUFFIX ".elf") #For some reason setting this works for ASM files but SUFFIX_ASM doesnt


project(Unit_Testing LANGUAGES C CXX ASM DESCRIPTION "Compilation and Test Environment for Unit Tests")
include(CTest)

########
#Add Program Subdirectories
########

if (LEGACY)
    add_subdirectory(../test_sources/legacy legacy)
else()
    add_subdirectory(../test_sources vector-tests)
endif()






