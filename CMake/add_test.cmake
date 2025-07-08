#######
# Macro for adding a ChipsAlliance unit test to ctest
#######

macro(add_unit_test TEST_NAME)

    add_executable(${TEST_NAME})

    target_include_directories(${TEST_NAME} PRIVATE
        ${TEST_SOURCES}/riscv-vector-tests/out/v${VREG_W}x32machine/tests/stage2/
        ${TEST_SOURCES}/vector_test_support/
        ${TEST_SOURCES}/riscv-vector-tests/env/riscv-test-env/
    )

    target_sources(${TEST_NAME} PRIVATE
        ${TEST_SOURCES}/riscv-vector-tests/out/v${VREG_W}x32machine/tests/stage2/${TEST_NAME}.S
        ${TEST_SOURCES}/vector_test_support/test_macros.h
        ${TEST_SOURCES}/vector_test_support/riscv_test.h
        ${TEST_SOURCES}/vector_test_support/crt0.S
        ${TEST_SOURCES}/riscv-vector-tests/env/riscv-test-env/encoding.h
    )

    #Set Linker
    target_link_options(${TEST_NAME} PRIVATE "-nostdlib")
    target_link_options(${TEST_NAME} PRIVATE "-T${TEST_SOURCES}/vector_test_support/link.ld")

    add_custom_command(TARGET ${TEST_NAME}
                       POST_BUILD
                       COMMAND ${CMAKE_OBJCOPY} -O binary ${TEST_NAME}.elf ${TEST_NAME}.bin
                       COMMAND srec_cat ${TEST_NAME}.bin -binary -offset 0x0000 -byte-swap 4 -o ${TEST_NAME}.vmem -vmem
                       COMMAND rm -f prog_${TEST_NAME}.txt
                       COMMAND echo -n "${BUILD_DIR}/vector-tests/${TEST_NAME}.vmem" > prog_${TEST_NAME}.txt
                       COMMAND ${CMAKE_OBJDUMP} -D ${TEST_NAME}.elf > ${TEST_NAME}_dump.txt
                       )
    
     
    #If trace option is selected, provide the paths for the .vcd trace files.          
    if(TRACE)
        set(VCD_TRACE_ARGS "${BUILD_DIR}/Testing/last_test_sig.vcd")
    else()
        set(VCD_TRACE_ARGS "")
    endif()
	              

    #Add Test
    add_test(NAME ${TEST_NAME}
             COMMAND ${MODEL_DIR}/verilated_model ${BUILD_DIR}/vector-tests/prog_${TEST_NAME}.txt 32 4194304 1 1 ${TEST_NAME} ${VREG_W} ${VCD_TRACE_ARGS}
             WORKING_DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})

    message(STATUS "Successfully added ${TEST_NAME}")

endmacro()


#######
# Macro for adding a Spike Co-Sim ChipsAlliance unit test to ctest
#######
macro(add_unit_test_Spike TEST_NAME)

    add_executable(${TEST_NAME}_Spike)

    target_include_directories(${TEST_NAME}_Spike PRIVATE
        ${TEST_SOURCES}/riscv-vector-tests/out/v${VREG_W}x32machine/tests/stage2/
        ${TEST_SOURCES}/spike_cosim_support/
        ${TEST_SOURCES}/riscv-vector-tests/env/riscv-test-env/
    )

    target_sources(${TEST_NAME}_Spike PRIVATE
        ${TEST_SOURCES}/riscv-vector-tests/out/v${VREG_W}x32machine/tests/stage2/${TEST_NAME}.S
        ${TEST_SOURCES}/spike_cosim_support/test_macros.h
        ${TEST_SOURCES}/spike_cosim_support/riscv_test.h
        ${TEST_SOURCES}/spike_cosim_support/crt0.S
        ${TEST_SOURCES}/riscv-vector-tests/env/riscv-test-env/encoding.h
    )

    #Set Linker
    target_link_options(${TEST_NAME}_Spike PRIVATE "-nostdlib")
    target_link_options(${TEST_NAME}_Spike PRIVATE "-T${TEST_SOURCES}/spike_cosim_support/link.ld")

    add_custom_command(TARGET ${TEST_NAME}_Spike
                       POST_BUILD
                       COMMAND ${CMAKE_OBJDUMP} -D ${TEST_NAME}_Spike.elf > ${TEST_NAME}_Spike_dump.txt
                       )
	              

    #Add Test
    add_test(NAME ${TEST_NAME}_Spike
             COMMAND cmake -DTEST_NAME=${TEST_NAME} -DVREG_W=${VREG_W} -DSCRIPTS_DIR=${SCRIPTS_DIR} -DBUILD_DIR=${BUILD_DIR} -DSPIKE_DIR=${SPIKE_DIR} -P ${CMAKE_TOP}/run_spike_comparison.cmake 
             WORKING_DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})

    set_tests_properties(${TEST_NAME}_Spike PROPERTIES DEPENDS "${TEST_NAME}")

    message(STATUS "Successfully added ${TEST_NAME}_Spike")

endmacro()





#######
# Macro for adding a legacy unit test to ctest
#######

macro(add_legacy_test TEST_NAME)


    string(REPLACE "${SPILL_CACHE_PATH}/" "" folder ${CMAKE_CURRENT_SOURCE_DIR})

    add_executable(${folder}-${TEST_NAME})

    target_include_directories(${folder}-${TEST_NAME} PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}
    )

    target_sources(${folder}-${TEST_NAME} PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/${TEST_NAME}.S
        ${SPILL_CACHE_PATH}/spill_cache.S
    )

    string(REPLACE "${REPO_TOP}/test_sources" "${BUILD_DIR}" TEST_BUILD_PATH ${CMAKE_CURRENT_SOURCE_DIR})

    #Set Linker
    target_link_options(${folder}-${TEST_NAME} PRIVATE "-nostartfiles")
    target_link_options(${folder}-${TEST_NAME} PRIVATE "-nostdlib")
    target_link_options(${folder}-${TEST_NAME} PRIVATE "-T${SPILL_CACHE_PATH}/link.ld")

    #Link BSP
    target_link_libraries(${folder}-${TEST_NAME} PRIVATE bsp_Vicuna)

    add_custom_command(TARGET ${folder}-${TEST_NAME}
                       POST_BUILD
                       COMMAND ${CMAKE_OBJCOPY} -O binary ${folder}-${TEST_NAME}.elf ${TEST_NAME}.bin
                       COMMAND srec_cat ${TEST_NAME}.bin -binary -offset 0x0000 -byte-swap 4 -o ${TEST_NAME}.vmem -vmem
                       COMMAND rm -f prog_${TEST_NAME}.txt
                       COMMAND echo -n "${TEST_BUILD_PATH}/${TEST_NAME}.vmem ${TEST_BUILD_PATH}/${TEST_NAME}_reference.txt " > prog_${TEST_NAME}.txt
                       COMMAND readelf -s ${folder}-${TEST_NAME}.elf | sed '2,13 s/ //1' | grep vref_start | cut -d " " -f 6 | tr [=["\n"]=] " " >> prog_${TEST_NAME}.txt
                       COMMAND readelf -s ${folder}-${TEST_NAME}.elf | sed '2,13 s/ //1' | grep vref_end | cut -d " " -f 6 | tr [=["\n"]=] " " >> prog_${TEST_NAME}.txt
                       COMMAND echo -n "${TEST_BUILD_PATH}/${TEST_NAME}_result.txt " >> prog_${TEST_NAME}.txt
                       COMMAND readelf -s ${folder}-${TEST_NAME}.elf | sed '2,13 s/ //1' | grep vdata_start | cut -d " " -f 6 | tr [=["\n"]=] " " >> prog_${TEST_NAME}.txt
                       COMMAND readelf -s ${folder}-${TEST_NAME}.elf | sed '2,13 s/ //1' | grep vdata_end | cut -d " " -f 6 | tr [=["\n"]=] " " >> prog_${TEST_NAME}.txt
                       COMMAND ${CMAKE_OBJDUMP} -D ${folder}-${TEST_NAME}.elf > ${TEST_NAME}_dump.txt)
    
     
    #If trace option is selected, provide the paths for the .csv and .vcd trace files.  Due to argument parsing in verilator_main.cpp, both must be provided                
    if(TRACE)
        set(MEM_TRACE_ARGS "${BUILD_DIR}/Testing/last_test_mem.csv")
        set(VCD_TRACE_ARGS "${BUILD_DIR}/Testing/last_test_sig.vcd")
    else()
        set(MEM_TRACE_ARGS "")
        set(VCD_TRACE_ARGS "")
    endif()
	              

    #Add Test
    add_test(NAME ${folder}-${TEST_NAME}
             COMMAND cmake -DTEST_NAME=${TEST_NAME} -DBUILD_DIR=${TEST_BUILD_PATH} -DVERILATED_DIR=${MODEL_DIR} -DMEM_TRACE_ARGS=${MEM_TRACE_ARGS} -DMEM_LATENCY=${MEM_LATENCY} -DMEM_W=${MEM_W} -DVCD_TRACE_ARGS=${VCD_TRACE_ARGS} -DTEST_NAME=${TEST_NAME} -DVREG_W=${VREG_W} -P ${CMAKE_TOP}/run_legacy_test.cmake
             WORKING_DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})

    message(STATUS "Successfully added Legacy Test ${folder}-${TEST_NAME}")

endmacro()


