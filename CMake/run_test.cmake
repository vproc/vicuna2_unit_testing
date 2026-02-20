#Script to run the tests and compare the outputs  Add_test only allows a single command, so this script does the comparison with expected outputs
#All variables must be passed in from the Add_Tests COMMAND argument
#For reuse, provide the direct path to the files for VERILATED_DIR and BUILD_DIR
#Provide the paths for the mem_trace .csv and signal trace .vcd as XXX_TRACE_ARGS to get those outputs.  
execute_process(COMMAND ${VERILATED_DIR}/verilated_model ${BUILD_DIR}/prog_${TEST_NAME}.txt ${MEM_W} 4194304 ${MEM_LATENCY} 1 ${TEST_NAME} ${VREG_W} ${VCD_TRACE_ARGS}
                RESULT_VARIABLE RETURN_SIM)
                
if(RETURN_SIM)
        message(FATAL_ERROR "SIMULATION ERROR")
endif()
