// Copyright TU Wien
// Licensed under the Solderpad Hardware License v2.1, see LICENSE.txt for details
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1


#include <stdio.h>
#include <stdint.h>
#include <errno.h>
#include "Vvproc_top.h"

#include "verilator_support_cv32a60x.h"
#include "verilated.h"


int main(int argc, char **argv) {
    fprintf(stderr, "Starting Verilator Main()\n");
    
    int exit_code = 0;
    
    //////////////////////////
    //Check validity and parse input arguments
    //////////////////////////
    if (argc != 9 && argc != 10) {
        fprintf(stderr, "ERROR: Correct Usage: %s PROG_PATHS_LIST MEM_W MEM_SZ MEM_LATENCY EXTRA_CYCLES TEST_NAME VREG_W NUM_TEST_CASES [WAVEFORM_FILE]\n", argv[0]);
        return 1;
    }  

    int mem_w, mem_sz, mem_latency, extra_cycles, num_cases;
    {
        char *endptr;
        mem_w = strtol(argv[2], &endptr, 10);
        if (mem_w == 0 || *endptr != 0) {
            fprintf(stderr, "ERROR: invalid MEM_W argument\n");
            return 1;
        }
        mem_sz = strtol(argv[3], &endptr, 10);
        if (mem_sz == 0 || *endptr != 0) {
            fprintf(stderr, "ERROR: invalid MEM_SZ argument\n");
            return 1;
        }
        mem_latency = strtol(argv[4], &endptr, 10);
        if (*endptr != 0) {
            fprintf(stderr, "ERROR: invalid MEM_LATENCY argument\n");
            return 1;
        }
        extra_cycles = strtol(argv[5], &endptr, 10);
        if (*endptr != 0) {
            fprintf(stderr, "ERROR: invalid EXTRA_CYCLES argument\n");
            return 1;
        }
        num_cases = strtol(argv[8], &endptr, 10);
        if (*endptr != 0) {
            fprintf(stderr, "ERROR: invalid NUM_TEST_CASES argument\n");
            return 1;
        }
    }

    Verilated::traceEverOn(true);
    //Verilated::commandArgs(argc, argv);

    FILE *fprogs = fopen(argv[1], "r");
    if (fprogs == NULL) {
        fprintf(stderr, "ERROR: opening `%s': %s\n", argv[1], strerror(errno));
        return 2;
    }


    //////////////////////////
    //Init regfile logs
    //////////////////////////

    /*Log File for Scalar Registers*/
    std::string filename=(std::string(argv[6])+std::string("_xreg_commits_verilator.txt"));
    FILE *fxreglog = fopen(filename.c_str(), "w");

    /*Log File for Vector Registers.  Separate log because actual writes to VREGs might be out of order relative to the Xregs.  Should NOT be out of order relative to themselves.*/
    filename=(std::string(argv[6])+std::string("_vreg_commits_verilator.txt"));
    FILE *fvreglog = fopen(filename.c_str(), "w");

    /*Log File for Scalar Floating Point Registers*/
    filename=(std::string(argv[6])+std::string("_freg_commits_verilator.txt"));
    FILE *ffreglog = fopen(filename.c_str(), "w");

    //////////////////////////
    //Allocate memory latency buffers
    //////////////////////////

    bool *mem_rvalid_queue = (bool *)malloc(sizeof(bool) * mem_latency);
    unsigned char **mem_rdata_queue  = (unsigned char **)malloc(sizeof(unsigned char *) * mem_latency); //memory data port
    bool **mem_meta_queue   = (bool **)malloc(sizeof(bool *) * mem_latency); //memory metadata port

    for(int queue_pos = 0; queue_pos < mem_latency; queue_pos++)
    {
        mem_rdata_queue[queue_pos] = (unsigned char *)malloc(sizeof(unsigned char) * mem_w/8);
        mem_meta_queue[queue_pos] = (bool *)malloc(sizeof(bool) * 2); //2 metadata values (err and request source)
    }

    bool *mem_ivalid_queue = (bool *)malloc(sizeof(bool) * mem_latency);
    unsigned char **mem_idata_queue    = (unsigned char **)malloc(sizeof(unsigned char *) * mem_latency); //memory instruction port
    bool **mem_imeta_queue    = (bool **)malloc(sizeof(bool *) * mem_latency); //memory metadata port
    //even though known instruction interface width of 32 bits, malloc like this for compatability with memory management helper functions
    //same with metadata queue, known request source
    for(int queue_pos = 0; queue_pos < mem_latency; queue_pos++)
    {
        mem_idata_queue[queue_pos] = (unsigned char *)malloc(sizeof(unsigned char) * 32/8);
        mem_imeta_queue[queue_pos] = (bool *)malloc(sizeof(bool) * 2);
    }

    Vvproc_top *top = new Vvproc_top;


    //////////////////////////
    //Setup vcd trace file
    //////////////////////////
    VerilatedTrace_t *tfp = NULL;
    if (argc == 10) {
        #ifdef TRACE_VCD
        tfp = new VerilatedTrace_t;
        top->trace(tfp, 99);  // Trace 99 levels of hierarchy
        tfp->open(argv[9]);
        #endif
    }


    //////////////////////////
    //Read file containing program paths : TODO - Currently required for support of legacy tests (to get memory dump regions for verification).  Vector tests don't dump any memory to a file
    //////////////////////////

    char *line = NULL, *prog_path = NULL, *ref_path = NULL, *dump_path = NULL;
    size_t line_sz = 0;
    getline(&line, &line_sz, fprogs);
    // allocate sufficient storage space for the four paths (length of the
    // line, or at least 32 bytes)
    if (line_sz < 32) {
        line_sz = 32;
    }
    prog_path = (char *)realloc(prog_path, line_sz);
    ref_path  = (char *)realloc(ref_path,  line_sz);
    dump_path = (char *)realloc(dump_path, line_sz);
    strcpy(ref_path,  "/dev/null");
    strcpy(dump_path, "/dev/null");

    int ref_start  = 0,
        ref_end    = 0,
        dump_start = 0,
        dump_end   = 0,
        items;
    items = sscanf(line, "%s %s %x %x %s %x %x", prog_path, ref_path, &ref_start, &ref_end, dump_path, &dump_start, &dump_end);
    if (items == 0 || items == EOF) {
        return -1;
    }

    unsigned char *mem = load_program(mem_sz, prog_path);

    
    //////////////////////////
    // Write Reference File (Legacy tests only)
    //////////////////////////

    dump_mem_region(ref_start, ref_end, mem, ref_path);

    //////////////////////////
    //Begin Program execution
    //////////////////////////
    
    int i;
    for (i = 0; i < mem_latency; i++) {
        mem_rvalid_queue[i] = 0;
    }
    top->mem_rvalid_i = 0;
    top->mem_irvalid_i = 0;
    top->clk_i        = 0;
    top->rst_ni       = 0;
    for (i = 0; i < 10; i++) {
        top->clk_i = 0;
        top->eval();
        update_stats(top);
        update_vcd(tfp, 0, 0);

        top->clk_i = 1;
        top->eval();
        update_stats(top);
        update_vcd(tfp, 0, 0);
    }
    top->rst_ni = 1;
    top->eval();
    update_stats(top);
    update_vcd(tfp, 0, 0);

        
    
    char *endptr;
    int vreg_w = strtol(argv[7], &endptr, 10);
    
    int  cycles_begin_trace = 0;  //Traces begin at this cycle count.  TODO: expose to the command line
    int  cycles_end_trace = 0;    //Traces end at this cycle count.  TODO: expose to the command line

    // variables to keep track of vector tests successes/failures
    int v_test_success = 0;
    int v_test_failure = 0;
    

    //////////////////////////
    //Program Execution - Infinite loop with defined exit conditions
    //////////////////////////
    while (true) {

        //////////////////////////
        // Advance to next clock cycle
        //////////////////////////
        //advance_cycle_half(top, 0);

        top->clk_i = 1;
        top->eval();
        update_stats(top);
        update_vcd(tfp, cycles_begin_trace, cycles_end_trace);

        //////////////////////////
        //Update Memory interfaces
        //////////////////////////

        //if flush issued, clear all outstanding valid requests
        if (top->flush_o)
        {
            for (int i = mem_latency-1; i >= 0; i--) {
                mem_ivalid_queue[i] = false;
        
            }
        }

        //Update write interface
        update_mem_write(top->mem_addr_o, (top->mem_req_o && top->mem_we_o), mem_w, mem_latency, mem_sz, (unsigned char*)&(top->mem_wdata_o), (unsigned char*)&(top->mem_be_o), mem_rvalid_queue, mem);
        //Update read interface
        update_mem_load(top, top->mem_addr_o, (top->mem_req_o && !top->mem_we_o), top->mem_we_o, (top->mem_src_o), mem_w, mem_latency, mem_sz, (unsigned char*)&(top->mem_rdata_i), (bool*)&(top->mem_rvalid_i), (bool*)&(top->mem_err_i), (bool*)&(top->mem_src_i), mem_rdata_queue, mem_rvalid_queue, mem_meta_queue, mem);
        //Update instruction memory interface.  Never a write here.  Metadata field repurposed to store obi.id field, used internally for the index in the fetchbuffer.
        update_mem_load(top, top->mem_iaddr_o, top->mem_ireq_o, false, (top->mem_iid_o), 32, mem_latency, mem_sz, (unsigned char*)&(top->mem_irdata_i), (bool*)&(top->mem_irvalid_i), (bool*)&(top->mem_ierr_i), (bool*)&(top->mem_iid_i), mem_idata_queue, mem_ivalid_queue, mem_imeta_queue, mem);



        top->eval();
        update_stats(top);
        update_vcd(tfp, cycles_begin_trace, cycles_end_trace);

        //Use memory mapped IO at address 0x400 to signal success or failure
        char w_port;
        if (check_memmapio(top->mem_addr_o, (top->mem_req_o && top->mem_we_o), 8, (unsigned char*)&(top->mem_wdata_o), 0x00000400u, &w_port)){
            if (w_port == 0)
            {
                fprintf(stderr, "SUCCESS: TEST PASS - TEST %d - Output Match\n", v_test_failure+v_test_success+2);
                v_test_success++;
            } else {
                fprintf(stderr, "ERROR: TEST FAILURE - Output Mismatch - TEST %d - Output Mismatch\n", v_test_failure+v_test_success+2);
                v_test_failure++;
                
            }
        }      


        //advance_cycle_half(top, 1);
        top->clk_i = 0;
        top->eval();
        update_stats(top);
        update_vcd(tfp, cycles_begin_trace, cycles_end_trace);

        
        //////////////////////////
        // Check Exit Conditions
        //////////////////////////


        //A jump to address 0x70 is a failed test caused by an interrupt being called (all other interrupts also funnel here)  Exit Program
        if (check_PC(top, 0x00000070u) ) {
            fprintf(stderr, "ERROR: TEST FAILURE - Interrupt Called\n");
            exit_code = 1;
            break;
        }
        
        if (check_PC(top,  0x00000074u)) {
            fprintf(stderr, "PROGRAM EXECUTION ENDED CORRECTLY\n");
            if ( v_test_failure > 0)
            {
                exit_code = 1;
            }
            break;
        }

        if (check_stall(top, 1000)){
            exit_code = 1;
            break;
        }

        //////////
        // Outputs + Statistics
        //////////

        // update_xreg_commit(top, fxreglog);
        // update_freg_commit(top, ffreglog);
        // update_vreg_commit(top, vreg_w, fvreglog); 
        
    }
    
    ////////////////////////
    // On program completion, report statistics
    ////////////////////////
    report_stats(); 

    fprintf(stderr, "Tests Passed     : %d / %d\n", v_test_success, (v_test_success+v_test_failure));
    if ((v_test_success+v_test_failure+1) != num_cases)//+1 because test case numbers for chipsalliance start numbering at 2 for some reason
    {
        fprintf(stderr, "ERROR: Result from all test cases not reported!     : %d reported vs %d total\n", (v_test_success+v_test_failure), num_cases-1); 
        fprintf(stderr, "NOTE: ChipsAlliance Test numbering starts at 2\n"); 
        exit_code=1;
    }

    // write dump file
    dump_mem_region(dump_start, dump_end, mem, dump_path);
    

#if defined(TRACE_VCD) || defined(TRACE_FST)
    if (tfp != NULL)
    {
        tfp->close();
    }
#endif
    top->final();
    free(prog_path);
    free(ref_path);
    free(dump_path);
    free(line);
    free(mem);
    free(mem_rvalid_queue);
    for(int queue_pos = 0; queue_pos < mem_latency; queue_pos++)
    {
        free(mem_rdata_queue[queue_pos]);
        free(mem_idata_queue[queue_pos]);
        free(mem_meta_queue[queue_pos]);
        free(mem_imeta_queue[queue_pos]);
    }
    free(mem_rdata_queue);
    free(mem_idata_queue);
    free(mem_meta_queue);
    free(mem_imeta_queue);

    fclose(fprogs);
    fclose(fxreglog);
    fclose(fvreglog);
    fclose(ffreglog);

    return exit_code;
}
