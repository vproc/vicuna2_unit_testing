// Copyright 2017-2019 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Florian Zaruba, ETH Zurich
// Date: 19.03.2017
// Description: CVA6 Top-level module

`include "obi/typedef.svh"
`include "obi/assign.svh"
`include "rvfi_types.svh"
`include "cvxif_types.svh"

module vproc_top
  import ariane_pkg::*;
  import vproc_pkg::*;
#(
    // CVA6 config
    parameter config_pkg::cva6_cfg_t CVA6Cfg = build_config_pkg::build_config(
        cva6_config_pkg::cva6_cfg
    ),

    // CVXIF Types
    localparam type readregflags_t = `READREGFLAGS_T(CVA6Cfg),
    localparam type writeregflags_t = `WRITEREGFLAGS_T(CVA6Cfg),
    localparam type id_t = `ID_T(CVA6Cfg),
    localparam type hartid_t = `HARTID_T(CVA6Cfg),
    localparam type x_compressed_req_t = `X_COMPRESSED_REQ_T(CVA6Cfg, hartid_t),
    localparam type x_compressed_resp_t = `X_COMPRESSED_RESP_T(CVA6Cfg),
    localparam type x_issue_req_t = `X_ISSUE_REQ_T(CVA6Cfg, hartit_t, id_t),
    localparam type x_issue_resp_t = `X_ISSUE_RESP_T(CVA6Cfg, writeregflags_t, readregflags_t),
    localparam type x_register_t = `X_REGISTER_T(CVA6Cfg, hartid_t, id_t, readregflags_t),
    localparam type x_commit_t = `X_COMMIT_T(CVA6Cfg, hartid_t, id_t),
    localparam type x_result_t = `X_RESULT_T(CVA6Cfg, hartid_t, id_t, writeregflags_t),
    localparam type cvxif_req_t =
    `CVXIF_REQ_T(CVA6Cfg, x_compressed_req_t, x_issue_req_t, x_register_req_t, x_commit_t),
    localparam type cvxif_resp_t =
    `CVXIF_RESP_T(CVA6Cfg, x_compressed_resp_t, x_issue_resp_t, x_result_t),

    //VPROC TOP PARAMS
    parameter int unsigned     MEM_W         = 32,  // memory bus width in bits
    parameter int unsigned     VMEM_W        = 32,  // vector memory interface width in bits
    parameter vreg_type        VREG_TYPE     = VREG_GENERIC,
    parameter mul_type         MUL_TYPE      = MUL_GENERIC
) (
    // Subsystem Clock - SUBSYSTEM
    input logic clk_i,
    // Asynchronous reset active low - SUBSYSTEM
    input logic rst_ni,

    //////////////////////////////////////////
    //vproc top signals
    output logic               mem_req_o,
    output logic [31:0]        mem_addr_o,
    output logic               mem_we_o,
    output logic               mem_src_o,
    output logic [MEM_W/8-1:0] mem_be_o,
    output logic [MEM_W  -1:0] mem_wdata_o,
    input  logic               mem_rvalid_i,
    input  logic               mem_err_i,
    input  logic               mem_src_i,
    input  logic [MEM_W  -1:0] mem_rdata_i,

    output logic               data_read_o,

    output logic [31:0]        pend_vreg_wr_map_o,

    output logic               mem_ireq_o,    //fetch_req.req
    output logic [31:0]        mem_iaddr_o,   //fetch_req.a.addr
    output logic               mem_iid_o,     //fetch_req.a.aid
    

    input  logic               mem_irvalid_i, //fetch_resp.rvalid
    input  logic               mem_ierr_i,    //fetch_resp.r.err
    input  logic [32  -1:0]    mem_irdata_i,  //fetch_resp.r.rdata
    input  logic               mem_iid_i,     //fetch_resp.r.rid
    input  logic               mem_ignt_i,    //fetch_resp.gnt
   

    output logic flush_o
    //////////////////////////////////////////
);

  //OBI FETCH
  `OBI_LOCALPARAM_TYPE_ALL(obi_fetch, CVA6Cfg.ObiFetchbusCfg);
  //OBI STORE
  `OBI_LOCALPARAM_TYPE_ALL(obi_store, CVA6Cfg.ObiStorebusCfg);
  //OBI LOAD
  `OBI_LOCALPARAM_TYPE_ALL(obi_load, CVA6Cfg.ObiLoadbusCfg);

  obi_fetch_req_t obi_fetch_req;
  obi_fetch_rsp_t obi_fetch_rsp;

  obi_store_req_t obi_store_req;
  obi_store_rsp_t obi_store_rsp;

  obi_load_req_t obi_load_req;
  obi_load_rsp_t obi_load_rsp;

  cvxif_req_t cvxif_req_o;
  cvxif_resp_t cvxif_resp_i;

  // -------------------
  // CV32A60X Pipeline
  // -------------------

  cva6_pipeline #(
      // CVA6 config
      .CVA6Cfg(CVA6Cfg)
      // RVFI PROBES
      //.rvfi_probes_t(rvfi_probes_t)
      //
  ) i_cva6_pipeline (
      .clk_i(clk_i),      
      .rst_ni(rst_ni),    
      .boot_addr_i('h00000080),//TODO:  CURRENTLY SET TO 80 to start at the reset vector -> could set to x8000080 to match with spike?
      .hart_id_i('0), //Only one core
      .irq_i(1'b0),
      .ipi_i(1'b0),
      .time_irq_i(1'b0),

      .cvxif_req_o(cvxif_req_o),
      .cvxif_resp_i(cvxif_resp_i),

      .obi_fetch_req_o(obi_fetch_req),
      .obi_fetch_rsp_i(obi_fetch_rsp),
      
      .obi_store_req_o  (obi_store_req),
      .obi_store_rsp_i  (obi_store_rsp),

      .obi_load_req_o   (obi_load_req),
      .obi_load_rsp_i   (obi_load_rsp)
      
      //.flush_o (flush_o)
  );

  // -------------------
  // VICUNA2 Pipeline
  // -------------------

  // Vector Unit Interface
  localparam X_NUM_RS = 3;
  localparam X_ID_WIDTH = 4;
  localparam X_RFR_WIDTH = 32;
  localparam X_RFW_WIDTH = 32;
  localparam X_MISA = 0;
  vproc_xif #(
      .X_NUM_RS    ( X_NUM_RS    ),
      .X_ID_WIDTH  ( X_ID_WIDTH  ),
      .X_MEM_WIDTH ( VMEM_W      ),
      .X_RFR_WIDTH ( X_RFR_WIDTH ),
      .X_RFW_WIDTH ( X_RFW_WIDTH ),
      .X_MISA      ( X_MISA      )
  ) vcore_xif ();

  `ifdef FORCE_ALIGNED_READS
  localparam bit [VLSU_FLAGS_W-1:0] VLSU_FLAGS = (VLSU_FLAGS_W'(1) << VLSU_ALIGNED_UNITSTRIDE);
  `else
  localparam bit [VLSU_FLAGS_W-1:0] VLSU_FLAGS = (VLSU_FLAGS_W'(0) << VLSU_ALIGNED_UNITSTRIDE);
  `endif

  localparam bit [BUF_FLAGS_W -1:0] BUF_FLAGS  = (BUF_FLAGS_W'(1) << BUF_DEQUEUE  ) |
                                                  (BUF_FLAGS_W'(1) << BUF_VREG_PEND);


`ifdef RISCV_ZVE32X
    vproc_core #(
        .XIF_ID_W           ( X_ID_WIDTH         ),
        .XIF_MEM_W          ( VMEM_W             ),
        .VREG_TYPE          ( VREG_TYPE          ),
        .MUL_TYPE           ( MUL_TYPE           ),
        .VLSU_FLAGS         ( VLSU_FLAGS         ),
        .BUF_FLAGS          ( BUF_FLAGS          ),
        .DONT_CARE_ZERO     ( 1'b0               ),
        .ASYNC_RESET        ( 1'b0               )
    ) v_core (
        .clk_i              ( clk_i              ),
        .rst_ni             ( rst_ni         ),

        .xif_issue_if       ( vcore_xif          ),
        .xif_commit_if      ( vcore_xif          ),
        .xif_mem_if         ( vcore_xif          ), // this interface no longer exists TODO: Upgrade to OBI
        .xif_memres_if      ( vcore_xif          ), // this interface no longer exists TODO: Upgrade to OBI
        .xif_result_if      ( vcore_xif          ),
        //TODO:Register Interface



        .pending_load_o     ( vect_pending_load  ),
        .pending_store_o    ( vect_pending_store ),

        .csr_vtype_o        ( csr_vtype          ),
        .csr_vl_o           ( csr_vl             ),
        .csr_vlenb_o        ( csr_vlenb          ),
        .csr_vstart_o       ( csr_vstart_rd      ),
        .csr_vstart_i       ( csr_vstart_wr      ),
        .csr_vstart_set_i   ( csr_vstart_wren    ),
        .csr_vxrm_o         ( csr_vxrm_rd        ),
        .csr_vxrm_i         ( csr_vxrm_wr        ),
        .csr_vxrm_set_i     ( csr_vxrm_wren      ),
        .csr_vxsat_o        ( csr_vxsat_rd       ),
        .csr_vxsat_i        ( csr_vxsat_wr       ),
        .csr_vxsat_set_i    ( csr_vxsat_wren     ),
        `ifdef RISCV_ZVE32F
        .fpr_wr_req_valid   ( fpr_wr_req_valid   ),
        .fpr_wr_req_addr_o  ( fpr_wr_req_addr    ),
        .fpr_res_valid      ( fpr_wr_resp_valid  ),
        .float_round_mode_i ( float_round_mode   ),

        .fpu_res_acc (fpu_ss_res_accepted),
        .fpu_res_id (fpu_res_id),

        `endif

        .pend_vreg_wr_map_o ( pend_vreg_wr_map_o )
    );

////////////
//Attach vicuna to CVXIF interface
////////////
//CV32A60X splits xif into req/response interfaces
//CV32A60X supports most recent spec.  TODO: Upgrade Vicuna
//    - Memory Request-Response interface is deprecated.  Currently connected directly to DMEM out port with arbitration, TODO: Upgrade to OBI
//    - New Register Interface handles scalar source registers.  Currently re-merge into old Issue Interface (spec allows this).  TODO: Upgrade with support for this interface. -> CV32A60X "X_ISSUE_REGISTER_SPLIT = 0 : Issue and register transactions are synchronous"
//    - Vicuna cannot currently accept any hartid.  Only one core, always tie result hartid to 0
//    - No Result Interface error codes.  Assume traps should be handled with an external interrupt handler.  Does this mean that stalling for loads/store is no longer necessary? (have interrupt hardware keep track for precise traps)
//Issue Interface (combined with register interface)

assign vcore_xif.issue_valid = cvxif_req_o.issue_valid;

assign vcore_xif.issue_req.instr = cvxif_req_o.issue_req.instr;
assign vcore_xif.issue_req.id = cvxif_req_o.issue_req.id;
assign vcore_xif.issue_req.mode = '0; //New issue interface does not provide privilige levels.  Vicuna shouldnt need it
assign vcore_xif.issue_req.rs = cvxif_req_o.register.rs;
always_comb begin
  vcore_xif.issue_req.rs_valid = &cvxif_req_o.register.rs_valid; //one bit per source operand -> currently AND all together, require all possible scalar operands to be valid (NOT EFFICIENT)
end

//TODO: Add bit from decoder saying a register is needed -> CV32A60X doesnt actually process this bit
assign cvxif_resp_i.issue_ready = vcore_xif.issue_ready;
assign cvxif_resp_i.register_ready = vcore_xif.issue_ready;

assign cvxif_resp_i.issue_resp.accept = vcore_xif.issue_resp.accept;
assign cvxif_resp_i.issue_resp.writeback = vcore_xif.issue_resp.writeback; //treated as a single bit internally on CV32A60X side
//TODO: additional bits

//Commit Interface -> Appears that commit happens in the same cycle as issue?  Might not be a problem, this behavior was supported with Ibex

assign vcore_xif.commit_valid = cvxif_req_o.commit_valid;
assign vcore_xif.commit.id = cvxif_req_o.commit.id;
assign vcore_xif.commit.commit_kill = cvxif_req_o.commit.commit_kill;

//Result Interface

assign vcore_xif.result_ready = cvxif_req_o.result_ready;

assign cvxif_resp_i.result_valid = vcore_xif.result_valid;
assign cvxif_resp_i.result.hartid = '0;
assign cvxif_resp_i.result.id = vcore_xif.result.id;
assign cvxif_resp_i.result.data = vcore_xif.result.data;
assign cvxif_resp_i.result.rd = vcore_xif.result.rd;
assign cvxif_resp_i.result.we = vcore_xif.result.we; //we definition seems different?


//test signals
logic issue_ready_test, issue_valid_test, register_ready_test, register_valid_test, commit_valid_test, result_ready_test, result_valid_test;
assign issue_ready_test = cvxif_resp_i.issue_ready;
assign issue_valid_test = cvxif_req_o.issue_valid;
assign register_ready_test = cvxif_resp_i.register_ready;
assign register_valid_test = vcore_xif.issue_req.rs_valid;
assign commit_valid_test = cvxif_req_o.commit_valid;
assign result_ready_test = cvxif_req_o.result_ready;
assign result_valid_test = cvxif_resp_i.result_valid;
logic [31:0] issue_id_test;
assign issue_id_test=cvxif_req_o.issue_req.id;
logic [31:0] issue_instr;
assign issue_instr = cvxif_req_o.issue_req.instr;
logic [31:0] result_id_test;
assign result_id_test=cvxif_resp_i.result.id;



`endif



  /////////
  // Connect OBI Signals to expected VPROC_OUT interface.  TODO: Make vicaun side an OBI interface
  ////////

  //######Connect instruction memory obi signals######
  assign mem_ireq_o = obi_fetch_req.req;
  assign mem_iaddr_o = obi_fetch_req.a.addr;
  assign mem_iid_o = obi_fetch_req.a.aid;
  //parity bits?
  assign obi_fetch_rsp.r.rdata = mem_irdata_i;
  assign obi_fetch_rsp.rvalid = mem_irvalid_i;
  assign obi_fetch_rsp.r.err = mem_ierr_i;
  assign obi_fetch_rsp.r.rid = mem_iid_i; //ID used by CVA6 to managed index in instruction buffer.  TODO: Rework this, CVA6 frontend should keep track of its own order of imem requests (in fifo?).  CURRENT SETUP ONLY SUPPORTS FETCHBUFFER SIZE OF 2
  assign obi_fetch_rsp.gnt = 1'b1; //instruction memory always ready
  


  //######Connect data memory obi signals######
  //two ports (load_req and store_req).  Two requests are allowed to be issued at the same time, so arbitration must happen
  //In case when vector unit included, additional arbitration required
  //From documentation:
  //    - Load only capable of read accesses
  //    - Store exclusively for write accesses
  //    - gntpar and rvalidpar not checked
  //    - store interface does not use channel R
  //    - err signal not processed (still assigned here)
`ifndef RISCV_ZVE32X
always_comb begin
  mem_req_o = obi_load_req.req || obi_store_req.req;
  obi_load_rsp.gnt = !obi_store_req.req; //core can issue load and store request at the same time.  give preference to stores
  obi_store_rsp.gnt = 1'b1;

  mem_addr_o = obi_store_req.a.addr;
  if (obi_load_req.req && !obi_store_req.req) begin
      mem_addr_o = obi_load_req.a.addr;
  end
  //only store can write
  mem_wdata_o = obi_store_req.a.wdata; 
  mem_we_o = obi_store_req.a.we & obi_store_req.req;
  mem_be_o = obi_store_req.a.be; //does loading half-words change this?
  
  //only load uses the r interface
  obi_load_rsp.r.rdata = mem_rdata_i;
  obi_load_rsp.rvalid = mem_rvalid_i;
  obi_load_rsp.r.err = mem_err_i;
  obi_load_rsp.r.rid = '0; //ID? -> hart ID, hard code to 0 since only one hart in system

  //mem_req source tracking.  Without vector unit, src unused but set for completeness
  mem_src_o = 1'b0;
end
`else
//TODO Arbitration with vector unit included.  Preference given Vector > Scalar Store > Scalar Load
//CV32A60X does not stall scalar LSU for vector stores, can lead to non-serialized accesses.
//Current solution is to keep track of offloaded Loads/Stores and reserve the memory port until the vector load/store is resolved.
//TODO: Improve this with a more intelligent memory system (ie write buffer), as this current setup leads to unnecessary stalling
logic [4:0] outstanding_vlsu_id;
logic no_outstanding_vlsu;

//assign no_outstanding_vlsu = 1'b1;

 fifo_v3 #(
    .FALL_THROUGH (1'b0        ), //no fall through mode? cant push and pop a memory transaction in the same cycle by design
    .dtype        (logic [4:0]),
    .DEPTH        (10           )   //What is the maximum depth?
  ) next_vlsu_id_fifo (
    .clk_i      (clk_i),
    .rst_ni     (rst_ni),
    .flush_i    (1'b0                    ),   //No need to flush because CV32A60X only offloads non-speculative instructions
    .data_i     (vcore_xif.issue_req.id), //Push ID of this instruction
    .push_i     (vcore_xif.issue_ready & vcore_xif.issue_valid & vcore_xif.issue_resp.loadstore), //push if a valid LSU instruction is offloaded
    .data_o     (outstanding_vlsu_id),
    .empty_o    (no_outstanding_vlsu),
    .pop_i      (vcore_xif.result_valid & vcore_xif.result_ready & (vcore_xif.result.id == outstanding_vlsu_id) & !no_outstanding_vlsu) //Add empty check in case id 0 is result signalled while fifo is empty
    //.pop_i      (vcore_xif.result_valid & vcore_xif.result_ready & !no_outstanding_vlsu)
  );
logic test_store_req;
logic [31:0] test_store_addr;
assign test_store_req = obi_store_req.req;
assign test_store_addr = obi_store_req.a.addr;

logic test_load_req;
assign test_load_req = obi_load_req.req;
always_comb begin
  mem_req_o = obi_load_req.req || obi_store_req.req || vcore_xif.mem_valid;

  obi_load_rsp.gnt = !obi_store_req.req && !vcore_xif.mem_valid && no_outstanding_vlsu; //only grant cv32a60x the memory interface when no vector loads or stores are outstanding
  obi_store_rsp.gnt = !vcore_xif.mem_valid && no_outstanding_vlsu; //only grant cv32a60x the memory interface when no vector loads or stores are outstanding
  vcore_xif.mem_ready = 1'b1;
  mem_src_o = 1'b1; //default to vector unit source

  //default to vector interface for writes
  mem_addr_o = vcore_xif.mem_req.addr;
  mem_wdata_o = vcore_xif.mem_req.wdata; 
  mem_we_o = vcore_xif.mem_req.we & vcore_xif.mem_valid;
  mem_be_o = vcore_xif.mem_req.be; 

  if (obi_store_req.req && !vcore_xif.mem_valid && no_outstanding_vlsu) begin
      //if vector unit not using memory interface and a valid scalar store
      mem_addr_o = obi_store_req.a.addr;
      mem_wdata_o = obi_store_req.a.wdata; 
      mem_we_o = obi_store_req.a.we & obi_store_req.req;
      mem_be_o = obi_store_req.a.be; //does loading half-words change this?
      mem_src_o = 1'b0; //Scalar source (Store so this signal not required, but here for completeness)
  end else if (obi_load_req.req && !obi_store_req.req && !vcore_xif.mem_valid && no_outstanding_vlsu)begin 
      //if vector unit not using memory interface and a valid scalar load
      mem_addr_o = obi_load_req.a.addr;
      mem_src_o = 1'b0; //Scalar source
      mem_wdata_o = '0; 
      mem_we_o = '0;
      mem_be_o = '0; //does loading half-words change this?

  end
  //arbitrate rvalid based on source of request
  vcore_xif.mem_result_valid = 1'b0;
  obi_load_rsp.rvalid = 1'b0;
  if (mem_src_i) begin
    vcore_xif.mem_result_valid = mem_rvalid_i;
  end else begin
    obi_load_rsp.rvalid = mem_rvalid_i;
  end
  //only scalar load uses the r interface.
  obi_load_rsp.r.rdata = mem_rdata_i;
  obi_load_rsp.r.err = mem_err_i;
  obi_load_rsp.r.rid = '0; //ID? -> hart ID, hard code to 0 since only one hart in system

  vcore_xif.mem_result.rdata = mem_rdata_i;
  vcore_xif.mem_result.err = mem_err_i;
end

`endif

 

endmodule  // ariane
