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
    target_link_options(${folder}-${TEST_NAME} PRIVATE "-T${BSP_TOP}/lld_link.ld")

    #Link BSP
    target_link_libraries(${folder}-${TEST_NAME} PRIVATE bsp_Vicuna)

    add_custom_command(TARGET ${folder}-${TEST_NAME}
                       POST_BUILD
                       COMMAND ${RISCV_LLVM_PREFIX}/llvm-objcopy -O binary ${folder}-${TEST_NAME}.elf ${TEST_NAME}.bin
                       COMMAND srec_cat ${TEST_NAME}.bin -binary -offset 0x0000 -byte-swap 4 -o ${TEST_NAME}.vmem -vmem
                       COMMAND rm -f prog_${TEST_NAME}.txt
                       COMMAND echo -n "${TEST_BUILD_PATH}/${TEST_NAME}.vmem ${TEST_BUILD_PATH}/${TEST_NAME}_reference.txt " > prog_${TEST_NAME}.txt
                       COMMAND readelf -s ${folder}-${TEST_NAME}.elf | sed '2,13 s/ //1' | grep vref_start | cut -d " " -f 6 | tr [=["\n"]=] " " >> prog_${TEST_NAME}.txt
                       COMMAND readelf -s ${folder}-${TEST_NAME}.elf | sed '2,13 s/ //1' | grep vref_end | cut -d " " -f 6 | tr [=["\n"]=] " " >> prog_${TEST_NAME}.txt
                       COMMAND echo -n "${TEST_BUILD_PATH}/${TEST_NAME}_result.txt " >> prog_${TEST_NAME}.txt
                       COMMAND readelf -s ${folder}-${TEST_NAME}.elf | sed '2,13 s/ //1' | grep vdata_start | cut -d " " -f 6 | tr [=["\n"]=] " " >> prog_${TEST_NAME}.txt
                       COMMAND readelf -s ${folder}-${TEST_NAME}.elf | sed '2,13 s/ //1' | grep vdata_end | cut -d " " -f 6 | tr [=["\n"]=] " " >> prog_${TEST_NAME}.txt
                       COMMAND ${RISCV_LLVM_PREFIX}/llvm-objdump -D ${folder}-${TEST_NAME}.elf > ${TEST_NAME}_dump.txt)
    
     
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
             COMMAND cmake -DTEST_NAME=${TEST_NAME} -DBUILD_DIR=${TEST_BUILD_PATH} -DVERILATED_DIR=${MODEL_DIR} -DMEM_TRACE_ARGS=${MEM_TRACE_ARGS} -DMEM_LATENCY=${MEM_LATENCY} -DMEM_W=${MEM_W} -DVCD_TRACE_ARGS=${VCD_TRACE_ARGS} -P ${CMAKE_TOP}/run_legacy_test.cmake
             WORKING_DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})

    message(STATUS "Successfully added ${folder}-${TEST_NAME}")

endmacro()


