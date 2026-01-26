cmake_minimum_required(VERSION 3.10)
message(STATUS "CMake Version ${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION}.${CMAKE_PATCH_VERSION}")

###This file is used to build the verilated models of CV32E40X and Vicuna###

########################
# Arguments
#
# RV_ARCH : select the processor architecture configuration to verilate
# TRACE   : If defined, enable vcd trace outputs.  WARNING: Traces can be very large (GBs)
# TRACE_FULL   : If defined, trace outputs of ENTIRE model WARNING: Traces can be very VERY large (GBs) (requires TRACE=ON)
# CACHE :   Enable a cache configuration


#####################
# Setup the CMake Project
####################

project(Verilated-Builds LANGUAGES C CXX DESCRIPTION "Environment for Verilating Models")
find_package(verilator HINTS ${CMAKE_CURRENT_SOURCE_DIR}/../toolchain/verilator)

set(CMAKE_VERBOSE_MAKEFILE ON)

# Using C and C++ 11
set(CMAKE_C_STANDARD 14)
set(CMAKE_CXX_STANDARD 14)

option(TRACE "Enable minimal VCD trace outputs" OFF)
option(TRACE_FULL "Enable FULL VCD trace outputs" OFF) #TODO: prevent this option from being cached, force user to always manually enable it

########
## Import RTL configuration from here instead of command line.
## File shared with program compliation.
########
include(${CMAKE_CURRENT_SOURCE_DIR}/vector_config.cmake)
message("Selected SCALAR_CORE = ${SCALAR_CORE}")
set(ENV{VPROC_PIPELINES} ${VPROC_PIPELINES})
message("Selected VPROC_PIPELINES = ${VPROC_PIPELINES}")
message("Selected RISCV_ARCH = ${RISCV_ARCH}")
message("Selected VREG_W = ${VREG_W}")
set(MEM_W ${VMEM_W})
message("Selected MEM_W = ${MEM_W}")

set(MEM_SZ 4194304)

######################
# Extension Flags
######################

if(${RISCV_ARCH} STREQUAL "rv32im") #Build only scalar core
    set(XIF_FLAG "" )
    set(RISCV_F "" )
    set(RISCV_ZFH "" )
    set(RISCV_ZVE32X "" )
    set(RISCV_ZVE32F "" )
    set(RISCV_ZVFH "" )

elseif(${RISCV_ARCH} STREQUAL "rv32imf") #Build scalar core with FPU on the Xif interface
    set(XIF_FLAG "-DXIF_ON" )
    set(RISCV_F "-DRISCV_F" )
    set(RISCV_ZFH "" )
    set(RISCV_ZVE32X "" )
    set(RISCV_ZVE32F "" )
    set(RISCV_ZVFH "" )
    #C++ Flags
    add_definitions(-DRISCV_F)

elseif(${RISCV_ARCH} STREQUAL "rv32imf_zfh") #Build scalar core with FPU on the Xif interface with half-float support
    set(XIF_FLAG "-DXIF_ON" )
    set(RISCV_F "-DRISCV_F" )
    set(RISCV_ZFH "-DRISCV_ZFH" )
    set(RISCV_ZVE32X "" )
    set(RISCV_ZVE32F "" )
    set(RISCV_ZVFH "" )
    #C++ Flags
    add_definitions(-DRISCV_F)
    add_definitions(-DRISCV_ZFH)

elseif(${RISCV_ARCH} STREQUAL "rv32im_zve32x") #Build scalar core with Vicuna on the Xif interface
    set(XIF_FLAG "-DXIF_ON" )
    set(RISCV_F "" )
    set(RISCV_ZFH "" )
    set(RISCV_ZVE32X "-DRISCV_ZVE32X" )
    set(RISCV_ZVE32F "" )
    set(RISCV_ZVFH "" )
    #C++ Flags
    add_definitions(-DRISCV_ZVE32X)

elseif(${RISCV_ARCH} STREQUAL "rv32imf_zve32f") #Build scalar core with Vicuna and FPU on the Xif interface
    set(XIF_FLAG "-DXIF_ON" )
    set(RISCV_F "-DRISCV_F" )
    set(RISCV_ZFH "" )
    set(RISCV_ZVE32X "-DRISCV_ZVE32X" )
    set(RISCV_ZVE32F "-DRISCV_ZVE32F" )
    set(RISCV_ZVFH "" )
    #C++ Flags
    add_definitions(-DRISCV_F)
    add_definitions(-DRISCV_ZVE32X)
    add_definitions(-DRISCV_ZVE32F)

elseif(${RISCV_ARCH} STREQUAL "rv32imf_zfh_zve32f_zvfh") #Build scalar core with Vicuna (+floating point + half precision float) and FPU on the Xif interface
    set(XIF_FLAG "-DXIF_ON" )
    set(RISCV_F "-DRISCV_F" )
    set(RISCV_ZFH "-DRISCV_ZFH" )
    set(RISCV_ZVE32X "-DRISCV_ZVE32X" )
    set(RISCV_ZVE32F "-DRISCV_ZVE32F" )
    set(RISCV_ZVFH "-DRISCV_ZVFH" )
    #C++ Flags
    add_definitions(-DRISCV_F)
    add_definitions(-DRISCV_ZFH)
    add_definitions(-DRISCV_ZVE32X)
    add_definitions(-DRISCV_ZVE32F)
    add_definitions(-DRISCV_ZVFH)

else()
    message(FATAL_ERROR "Unsupported RISCV_ARCH selected")

endif()

######################
# Sources/Include Directories
######################

#####################################
#Path to CV32E40X sources               
set(DESIGN_RTL_DIR_CV32E40X ${CMAKE_CURRENT_SOURCE_DIR}/../rtl/cv32e40x/rtl)
#Sources Needed for CV32E40X
set(CV32E40X_SOURCE ${DESIGN_RTL_DIR_CV32E40X}/include/cv32e40x_pkg.sv                  
                    ${DESIGN_RTL_DIR_CV32E40X}/if_c_obi.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/if_xif.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/../bhv/cv32e40x_sim_clock_gate.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_core.sv 
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_a_decoder.sv 
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_alignment_buffer.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_alu.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_alu_b_cpop.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_b_decoder.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_clic_int_controller.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_compressed_decoder.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_controller.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_controller_bypass.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_controller_fsm.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_csr.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_cs_registers.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_data_obi_interface.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_decoder.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_div.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_ex_stage.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_ff_one.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_i_decoder.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_id_stage.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_if_stage.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_instr_obi_interface.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_int_controller.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_load_store_unit.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_lsu_response_filter.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_m_decoder.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_mpu.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_mult.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_pc_target.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_pma.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_popcnt.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_prefetcher.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_prefetch_unit.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_register_file.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_register_file_wrapper.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_sequencer.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_sleep_unit.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_wb_stage.sv
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_write_buffer.sv
                    )
               
#CV32E40X Include Dirs
set(CV32E40X_INCLUDE ${DESIGN_RTL_DIR_CV32E40X}                                         
                    ${DESIGN_RTL_DIR_CV32E40X}/include
                    ${DESIGN_RTL_DIR_CV32E40X}/../bhv)

#####################################
#Path to FPU_SS sources
set(DESIGN_RTL_DIR_FPU_SS ${CMAKE_CURRENT_SOURCE_DIR}/../rtl/fpu_ss/src)
#FPU_SS Sources                   
set(FPU_SS_SOURCE   ${DESIGN_RTL_DIR_FPU_SS}/fpu_ss_pkg.sv                              
                    ${DESIGN_RTL_DIR_FPU_SS}/fpu_ss_prd_f_pkg.sv
                    ${DESIGN_RTL_DIR_FPU_SS}/fpu_ss_prd_f_zfh_pkg.sv
                    ${DESIGN_RTL_DIR_FPU_SS}/fpu_ss_prd_zfinx_pkg.sv
                    ${DESIGN_RTL_DIR_FPU_SS}/fpu_ss_instr_pkg.sv
                    ${DESIGN_RTL_DIR_FPU_SS}/fpu_ss.sv
                    ${DESIGN_RTL_DIR_FPU_SS}/fpu_ss_compressed_predecoder.sv
                    ${DESIGN_RTL_DIR_FPU_SS}/fpu_ss_controller.sv
                    ${DESIGN_RTL_DIR_FPU_SS}/fpu_ss_csr.sv
                    ${DESIGN_RTL_DIR_FPU_SS}/fpu_ss_decoder.sv
                    ${DESIGN_RTL_DIR_FPU_SS}/fpu_ss_predecoder.sv
                    ${DESIGN_RTL_DIR_FPU_SS}/fpu_ss_regfile.sv )

#FPU_SS Include Dirs
set(FPU_SS_INCLUDE  ${DESIGN_RTL_DIR_FPU_SS} )
#####################################
#Path to CV32A60X sources
#Just include sources to instantiate a core, not full soc system.    TODO:  REMOVE UNECESSARY SOURCES           
set(CVA6_REPO_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../rtl/cv32a60x)
set(HPDCACHE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../rtl/cv32a60x/core/cache_subsystem/hpdcache)
#Sources Needed for CV32A60X. In the order from Flist.cva6
set(CV32A60X_SOURCE ${CVA6_REPO_DIR}/vendor/pulp-platform/fpga-support/rtl/SyncDpRam.sv #FPGA Memory
                    ${CVA6_REPO_DIR}/vendor/pulp-platform/fpga-support/rtl/AsyncDpRam.sv
                    ${CVA6_REPO_DIR}/vendor/pulp-platform/fpga-support/rtl/AsyncThreePortRam.sv
                    ${CVA6_REPO_DIR}/vendor/pulp-platform/fpga-support/rtl/SyncThreePortRam.sv
                    ${CVA6_REPO_DIR}/vendor/pulp-platform/fpga-support/rtl/SyncDpRam_ind_r_w.sv
                    
                    ${CVA6_REPO_DIR}/core/cvfpu/src/fpnew_pkg.sv        #FPNEW Floating point unit
                    ${CVA6_REPO_DIR}/core/cvfpu/src/fpnew_cast_multi.sv
                    ${CVA6_REPO_DIR}/core/cvfpu/src/fpnew_classifier.sv
                    ${CVA6_REPO_DIR}/core/cvfpu/src/fpnew_divsqrt_multi.sv
                    ${CVA6_REPO_DIR}/core/cvfpu/src/fpnew_fma_multi.sv
                    ${CVA6_REPO_DIR}/core/cvfpu/src/fpnew_fma.sv
                    ${CVA6_REPO_DIR}/core/cvfpu/src/fpnew_noncomp.sv
                    ${CVA6_REPO_DIR}/core/cvfpu/src/fpnew_opgroup_block.sv
                    ${CVA6_REPO_DIR}/core/cvfpu/src/fpnew_opgroup_fmt_slice.sv
                    ${CVA6_REPO_DIR}/core/cvfpu/src/fpnew_opgroup_multifmt_slice.sv
                    ${CVA6_REPO_DIR}/core/cvfpu/src/fpnew_rounding.sv
                    ${CVA6_REPO_DIR}/core/cvfpu/src/fpnew_top.sv
                    ${CVA6_REPO_DIR}/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/defs_div_sqrt_mvp.sv
                    ${CVA6_REPO_DIR}/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/control_mvp.sv
                    ${CVA6_REPO_DIR}/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/div_sqrt_top_mvp.sv
                    ${CVA6_REPO_DIR}/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/iteration_div_sqrt_mvp.sv
                    ${CVA6_REPO_DIR}/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/norm_div_sqrt_mvp.sv
                    ${CVA6_REPO_DIR}/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/nrbd_nrsc_mvp.sv
                    ${CVA6_REPO_DIR}/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/preprocess_mvp.sv

                    ${CVA6_REPO_DIR}/vendor/pulp-platform/common_cells/src/cf_math_pkg.sv #packages
                    ${CVA6_REPO_DIR}/vendor/pulp-platform/obi/src/obi_pkg.sv
                    ${CVA6_REPO_DIR}/core/include/config_pkg.sv
                    ${CVA6_REPO_DIR}/core/include/cv32a60x_config_pkg.sv
                    ${CVA6_REPO_DIR}/core/include/riscv_pkg.sv

                    ${DESIGN_RTL_DIR_CV32E40X}/include/cv32e40x_pkg.sv  #VPROC VDIV has a dependency on this package  TODO: REMOVE IT
                    ${DESIGN_RTL_DIR_CV32E40X}/cv32e40x_ff_one.sv
                    
                    ${CVA6_REPO_DIR}/core/include/ariane_pkg.sv
                    ${CVA6_REPO_DIR}/vendor/pulp-platform/axi/src/axi_pkg.sv

                    ${CVA6_REPO_DIR}/core/include/wt_cache_pkg.sv
                    ${CVA6_REPO_DIR}/core/include/std_cache_pkg.sv
                    ${CVA6_REPO_DIR}/core/include/instr_tracer_pkg.sv
                    ${CVA6_REPO_DIR}/core/include/build_config_pkg.sv

                    ${CVA6_REPO_DIR}/core/cvxif_compressed_if_driver.sv             #CVXIF
                    ${CVA6_REPO_DIR}/core/cvxif_issue_register_commit_if_driver.sv
                    ${CVA6_REPO_DIR}/core/cvxif_example/include/cvxif_instr_pkg.sv
                    ${CVA6_REPO_DIR}/core/cvxif_fu.sv
                    ${CVA6_REPO_DIR}/core/cvxif_example/cvxif_example_coprocessor.sv
                    ${CVA6_REPO_DIR}/core/cvxif_example/instr_decoder.sv
                    ${CVA6_REPO_DIR}/core/cvxif_example/compressed_instr_decoder.sv
                    ${CVA6_REPO_DIR}/core/cvxif_example/copro_alu.sv

                    #${CVA6_REPO_DIR}/vendor/pulp-platform/common_cells/src/fifo_v3.sv   #Common Cells Included in Vicuna
                    ${CVA6_REPO_DIR}/vendor/pulp-platform/common_cells/src/lfsr.sv
                    ${CVA6_REPO_DIR}/vendor/pulp-platform/common_cells/src/lfsr_8bit.sv
                    ${CVA6_REPO_DIR}/vendor/pulp-platform/common_cells/src/stream_arbiter.sv
                    ${CVA6_REPO_DIR}/vendor/pulp-platform/common_cells/src/stream_arbiter_flushable.sv
                    ${CVA6_REPO_DIR}/vendor/pulp-platform/common_cells/src/stream_mux.sv
                    ${CVA6_REPO_DIR}/vendor/pulp-platform/common_cells/src/stream_demux.sv
                    ${CVA6_REPO_DIR}/vendor/pulp-platform/common_cells/src/lzc.sv
                    ${CVA6_REPO_DIR}/vendor/pulp-platform/common_cells/src/rr_arb_tree.sv
                    ${CVA6_REPO_DIR}/vendor/pulp-platform/common_cells/src/shift_reg.sv
                    ${CVA6_REPO_DIR}/vendor/pulp-platform/common_cells/src/popcount.sv
                    ${CVA6_REPO_DIR}/vendor/pulp-platform/common_cells/src/exp_backoff.sv

                    ${CVA6_REPO_DIR}/vendor/pulp-platform/common_cells/src/counter.sv   #Common cells for example co-processor
                    ${CVA6_REPO_DIR}/vendor/pulp-platform/common_cells/src/delta_counter.sv

                    ${CVA6_REPO_DIR}/vendor/pulp-platform/obi/src/obi_atop_resolver.sv  #OBI
                    ${CVA6_REPO_DIR}/vendor/pulp-platform/obi/src/obi_demux.sv
                    ${CVA6_REPO_DIR}/vendor/pulp-platform/obi/src/obi_err_sbr.sv
                    ${CVA6_REPO_DIR}/vendor/pulp-platform/obi/src/obi_intf.sv
                    ${CVA6_REPO_DIR}/vendor/pulp-platform/obi/src/obi_mux.sv
                    ${CVA6_REPO_DIR}/vendor/pulp-platform/obi/src/obi_sram_shim.sv
                    ${CVA6_REPO_DIR}/vendor/pulp-platform/obi/src/obi_xbar.sv

                    ${CVA6_REPO_DIR}/core/cva6.sv               #Top level sources
                    ${CVA6_REPO_DIR}/core/cva6_pipeline.sv
                    ${CVA6_REPO_DIR}/core/cva6_rvfi_probes.sv
                    ${CVA6_REPO_DIR}/core/alu.sv
                    
                    ${CVA6_REPO_DIR}/core/fpu_wrap.sv           #depends on fpu-pkg
                    ${CVA6_REPO_DIR}/core/branch_unit.sv
                    ${CVA6_REPO_DIR}/core/compressed_decoder.sv
                    ${CVA6_REPO_DIR}/core/macro_decoder.sv
                    ${CVA6_REPO_DIR}/core/controller.sv
                    ${CVA6_REPO_DIR}/core/zcmt_decoder.sv
                    ${CVA6_REPO_DIR}/core/csr_buffer.sv
                    ${CVA6_REPO_DIR}/core/csr_regfile.sv
                    ${CVA6_REPO_DIR}/core/decoder.sv
                    ${CVA6_REPO_DIR}/core/ex_stage.sv
                    ${CVA6_REPO_DIR}/core/instr_realign.sv
                    ${CVA6_REPO_DIR}/core/id_stage.sv
                    ${CVA6_REPO_DIR}/core/issue_read_operands.sv
                    ${CVA6_REPO_DIR}/core/issue_stage.sv
                    ${CVA6_REPO_DIR}/core/load_unit.sv
                    ${CVA6_REPO_DIR}/core/load_store_unit.sv
                    ${CVA6_REPO_DIR}/core/lsu_bypass.sv
                    ${CVA6_REPO_DIR}/core/mult.sv
                    ${CVA6_REPO_DIR}/core/multiplier.sv
                    ${CVA6_REPO_DIR}/core/serdiv.sv
                    ${CVA6_REPO_DIR}/core/perf_counters.sv
                    ${CVA6_REPO_DIR}/core/ariane_regfile_ff.sv
                    ${CVA6_REPO_DIR}/core/ariane_regfile_fpga.sv
                    
                    ${CVA6_REPO_DIR}/core/scoreboard.sv
                    ${CVA6_REPO_DIR}/core/store_buffer.sv
                    ${CVA6_REPO_DIR}/core/amo_buffer.sv
                    ${CVA6_REPO_DIR}/core/store_unit.sv
                    ${CVA6_REPO_DIR}/core/commit_stage.sv
                    ${CVA6_REPO_DIR}/core/axi_shim.sv
                    ${CVA6_REPO_DIR}/core/cva6_accel_first_pass_decoder_stub.sv
                    ${CVA6_REPO_DIR}/core/acc_dispatcher.sv
                    ${CVA6_REPO_DIR}/core/cva6_fifo_v3.sv

                    
                    ${CVA6_REPO_DIR}/core/frontend/btb.sv
                    ${CVA6_REPO_DIR}/core/frontend/bht.sv
                    ${CVA6_REPO_DIR}/core/frontend/ras.sv
                    ${CVA6_REPO_DIR}/core/frontend/instr_scan.sv
                    ${CVA6_REPO_DIR}/core/frontend/instr_queue.sv
                    ${CVA6_REPO_DIR}/core/frontend/frontend.sv
                    
                    ${CVA6_REPO_DIR}/core/pmp/src/pmp.sv    #Physical Memory Protection NOTE: pmp.sv modified for DSIM (unchanged for other simulators)
                    ${CVA6_REPO_DIR}/core/pmp/src/pmp_entry.sv
                    ${CVA6_REPO_DIR}/core/pmp/src/pmp_data_if.sv
                    )
    

set(CV32A60X_INCLUDE ${CVA6_REPO_DIR}/core/include/
                     ${CVA6_REPO_DIR}/vendor/pulp-platform/obi/include/
                     #${CVA6_REPO_DIR}/vendor/pulp-platform/common_cells/include/ #included in Vicuna repo
                     #${CVA6_REPO_DIR}/vendor/pulp-platform/common_cells/src/     #
                     ${CVA6_REPO_DIR}/vendor/pulp-platform/axi/include/
                     ${CVA6_REPO_DIR}/common/local/util/
                     ${HPDCACHE_DIR}/rtl/include)





#################
#Path to Vicuna Sources  Include the CMakeList file from the repo
set(VICUNA_TOP_DIR  ${CMAKE_CURRENT_SOURCE_DIR}/../rtl/vicuna2_core )  
add_subdirectory(../rtl/vicuna2_core vicuna) # Include vicuna and cvfpu with VICUNA_SRCS, VICUNA_INCS

### TRACE FLAGS

if(TRACE)
    add_definitions(-DTRACE_VCD) #This does nothing.  TODO: Confirm and remove.
    set(TRACE TRACE)
    
    if(TRACE_FULL)
        set(TRACE_FLAG  ) #no --trace-depth flag defaults to entire model
    else()
        set(TRACE_FLAG --trace-depth 2)
    endif()
endif()

### Experimental Features flags
if(OLD_VICUNA)
    set(VICUNA_MODE -DOLD_VICUNA)
endif()

if(FORCE_ALIGNED_READS)
    set(READ_MODE -DFORCE_ALIGNED_READS)
endif()

if(${SCALAR_CORE} STREQUAL "cv32a60x")
    set(COMMIT_AND_ISSUE -DCOMMIT_AND_ISSUE)
endif()

#Create the verilated model 
add_executable(verilated_model)


# target_include_directories(verilated_model PRIVATE
#     ${CMAKE_CURRENT_SOURCE_DIR}
#     ${VICUNA_TOP_DIR})

target_sources(verilated_model PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/${SCALAR_CORE}/verilator_support_${SCALAR_CORE}.h
    ${CMAKE_CURRENT_SOURCE_DIR}/${SCALAR_CORE}/verilator_support_${SCALAR_CORE}.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/${SCALAR_CORE}/verilator_main.cpp)

if ( ${SCALAR_CORE} STREQUAL "cv32e40x" )
    verilate(verilated_model SOURCES  ${CV32E40X_SOURCE} ${VICUNA_FPU_SRCS} ${VICUNA_SRCS} ${FPU_SS_SOURCE} ${CMAKE_CURRENT_SOURCE_DIR}/${SCALAR_CORE}/vproc_top.sv
                INCLUDE_DIRS  ${CV32E40X_INCLUDE} ${VICUNA_FPU_INCS} ${VICUNA_INCS} ${FPU_SS_INCLUDE} ${CMAKE_CURRENT_SOURCE_DIR}
                TOP_MODULE vproc_top 
                PREFIX Vvproc_top
                ${TRACE}                                    
                VERILATOR_ARGS -cc -exe ${CMAKE_CURRENT_SOURCE_DIR}/${SCALAR_CORE}/verilator_main.cpp --unroll-count 1024
                                -Wno-WIDTH -Wno-PINMISSING -Wno-UNOPTFLAT   
                                -Wno-UNSIGNED -Wno-IMPLICIT -Wno-LITENDIAN -Wno-CASEINCOMPLETE        
                                -Wno-SYMRSVDWORD -Wno-BLKANDNBLK -Wno-BLKSEQ -Wno-SYNCASYNCNET        
                                -Wno-COMBDLY 
                                -Wno-WIDTHCONCAT
                                -Wno-ENUMVALUE 
                                -Wno-SELRANGE -Wno-LATCH #These might be caused from not connecting everything properly
                                -Wno-IMPLICITSTATIC      
                                #+define+COREV_ASSERT_OFF       #Fixes UVM error with CV32E40X (Needed when not using -DVPROC_SVA)
                                ${TRACE_FLAG} 
                                --assert -DVPROC_SVA
                                -GMEM_W=${MEM_W} -GVMEM_W=${VMEM_W}
                                ${VICUNA_MODE}
                                ${READ_MODE}
                                ${XIF_FLAG}
                                ${RISCV_F}
                                ${RISCV_ZFH}
                                ${RISCV_ZVE32X}
                                ${RISCV_ZVE32F}
                                ${RISCV_ZVFH}
                                -CFLAGS "-std=gnu++14 -O2")

elseif( ${SCALAR_CORE} STREQUAL "cv32a60x" ) #TODO: Verify/Test support for floating point vector systems with this core.  Currently, only Zve32x tested.
    verilate(verilated_model SOURCES ${CV32A60X_SOURCE} ${VICUNA_SRCS} ${CMAKE_CURRENT_SOURCE_DIR}/${SCALAR_CORE}/vproc_top.sv
                INCLUDE_DIRS ${CV32A60X_INCLUDE} ${VICUNA_INCS} ${CMAKE_CURRENT_SOURCE_DIR}
                TOP_MODULE vproc_top 
                PREFIX Vvproc_top
                ${TRACE}                                    
                VERILATOR_ARGS -cc -exe ${CMAKE_CURRENT_SOURCE_DIR}/${SCALAR_CORE}/verilator_main.cpp --unroll-count 1024
                                -Wno-WIDTH -Wno-PINMISSING -Wno-UNOPTFLAT   
                                -Wno-UNSIGNED -Wno-IMPLICIT -Wno-LITENDIAN -Wno-CASEINCOMPLETE        
                                -Wno-SYMRSVDWORD -Wno-BLKANDNBLK -Wno-BLKSEQ -Wno-SYNCASYNCNET        
                                -Wno-COMBDLY 
                                -Wno-WIDTHCONCAT
                                -Wno-ENUMVALUE 
                                -Wno-SELRANGE -Wno-LATCH #These might be caused from not connecting everything properly
                                -Wno-IMPLICITSTATIC      
                                #+define+COREV_ASSERT_OFF       #Fixes UVM error with CV32E40X (Needed when not using -DVPROC_SVA)
                                #--clk clk_i
                                ${TRACE_FLAG} 
                                --assert -DVPROC_SVA
                                -GMEM_W=${MEM_W} -GVMEM_W=${VMEM_W}
                                ${VICUNA_MODE}
                                ${READ_MODE}
                                ${XIF_FLAG}
                                ${RISCV_F}
                                ${RISCV_ZFH}
                                ${RISCV_ZVE32X}
                                ${RISCV_ZVE32F}
                                ${RISCV_ZVFH}
                                ${COMMIT_AND_ISSUE}
                                -CFLAGS "-std=gnu++14 -O2")
else()
    message(FATAL_ERROR "Unsupported Scalar Core Selected")
endif()
                              
