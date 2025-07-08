#Script to run the tests and compare the outputs  Add_test only allows a single command, so this script calls the python script which performs the comparison
#All variables must be passed in from the Add_Tests COMMAND argument
execute_process(COMMAND ${SPIKE_DIR}/spike --isa=rv32imf_zicntr_zihpm_zfh_zve32f_zvfh_zvl${VREG_W}b --log-commits --log=${TEST_NAME}_register_commits_Spike.txt ${BUILD_DIR}/vector-tests/${TEST_NAME}_Spike.elf   
                RESULT_VARIABLE RETURN_SIM)
execute_process(COMMAND python3 ${SCRIPTS_DIR}compare_commits.py ${VREG_W} ${TEST_NAME}
                RESULT_VARIABLE RETURN_DIFF)
                
if(RETURN_SIM)
        message(FATAL_ERROR "SPIKE SIMULATION ERROR")
else()
        if(RETURN_DIFF)
                message(FATAL_ERROR "SPIKE OUTPUT MISMATCH WITH VERILATOR MODEL")
        endif()
endif()
