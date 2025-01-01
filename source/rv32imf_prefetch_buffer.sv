// This module implements a prefetch buffer for the RV32IMF processor.
// It handles instruction prefetching and buffering.

module rv32imf_prefetch_buffer #(
    parameter int PULP_OBI   = 0,  // Enable PULP OBI interface
    parameter int COREV_PULP = 1   // Enable COREV PULP support
) (
    input logic clk,   // Clock signal
    input logic rst_n, // Active low reset signal

    input logic        req_i,         // Request input
    input logic        branch_i,      // Branch input
    input logic [31:0] branch_addr_i, // Branch address input

    input logic        hwlp_jump_i,   // Hardware loop jump input
    input logic [31:0] hwlp_target_i, // Hardware loop target address input

    input  logic        fetch_ready_i,  // Fetch ready input
    output logic        fetch_valid_o,  // Fetch valid output
    output logic [31:0] fetch_rdata_o,  // Fetch data output

    output logic        instr_req_o,     // Instruction request output
    input  logic        instr_gnt_i,     // Instruction grant input
    output logic [31:0] instr_addr_o,    // Instruction address output
    input  logic [31:0] instr_rdata_i,   // Instruction data input
    input  logic        instr_rvalid_i,  // Instruction valid input
    input  logic        instr_err_i,     // Instruction error input
    input  logic        instr_err_pmp_i, // Instruction PMP error input

    output logic busy_o  // Busy output
);

  localparam int FifoDepth = 2;  // Depth of the FIFO
  localparam int unsigned FifoAddrDepth = $clog2(FifoDepth);  // Address depth of the FIFO

  logic                   trans_valid;
  logic                   trans_ready;
  logic [           31:0] trans_addr;

  logic                   fifo_flush;
  logic                   fifo_flush_but_first;
  logic [FifoAddrDepth:0] fifo_cnt;

  logic [           31:0] fifo_rdata;
  logic                   fifo_push;
  logic                   fifo_pop;
  logic                   fifo_empty;

  logic                   resp_valid;
  logic [           31:0] resp_rdata;
  logic                   resp_err;

  // Prefetch controller instantiation
  rv32imf_prefetch_controller #(
      .DEPTH     (FifoDepth),
      .PULP_OBI  (PULP_OBI),
      .COREV_PULP(COREV_PULP)
  ) prefetch_controller_i (
      .clk  (clk),
      .rst_n(rst_n),

      .req_i        (req_i),
      .branch_i     (branch_i),
      .branch_addr_i(branch_addr_i),
      .busy_o       (busy_o),

      .hwlp_jump_i  (hwlp_jump_i),
      .hwlp_target_i(hwlp_target_i),

      .trans_valid_o(trans_valid),
      .trans_ready_i(trans_ready),
      .trans_addr_o (trans_addr),

      .resp_valid_i(resp_valid),

      .fetch_ready_i(fetch_ready_i),
      .fetch_valid_o(fetch_valid_o),

      .fifo_push_o           (fifo_push),
      .fifo_pop_o            (fifo_pop),
      .fifo_flush_o          (fifo_flush),
      .fifo_flush_but_first_o(fifo_flush_but_first),
      .fifo_cnt_i            (fifo_cnt),
      .fifo_empty_i          (fifo_empty)
  );

  // FIFO instantiation
  rv32imf_fifo #(
      .FALL_THROUGH(1'b0),
      .DATA_WIDTH  (32),
      .DEPTH       (FifoDepth)
  ) fifo_i (
      .clk_i            (clk),
      .rst_ni           (rst_n),
      .flush_i          (fifo_flush),
      .flush_but_first_i(fifo_flush_but_first),
      .testmode_i       (1'b0),
      .full_o           (),
      .empty_o          (fifo_empty),
      .cnt_o            (fifo_cnt),
      .data_i           (resp_rdata),
      .push_i           (fifo_push),
      .data_o           (fifo_rdata),
      .pop_i            (fifo_pop)
  );

  // Fetch data assignment
  assign fetch_rdata_o = fifo_empty ? resp_rdata : fifo_rdata;

  // OBI interface instantiation
  rv32imf_obi_interface #(
      .TRANS_STABLE(0)
  ) instruction_obi_i (
      .clk  (clk),
      .rst_n(rst_n),

      .trans_valid_i(trans_valid),
      .trans_ready_o(trans_ready),
      .trans_addr_i ({trans_addr[31:2], 2'b00}),
      .trans_we_i   (1'b0),
      .trans_be_i   (4'b1111),
      .trans_wdata_i(32'b0),
      .trans_atop_i (6'b0),

      .resp_valid_o(resp_valid),
      .resp_rdata_o(resp_rdata),
      .resp_err_o  (resp_err),

      .obi_req_o   (instr_req_o),
      .obi_gnt_i   (instr_gnt_i),
      .obi_addr_o  (instr_addr_o),
      .obi_we_o    (),
      .obi_be_o    (),
      .obi_wdata_o (),
      .obi_atop_o  (),
      .obi_rdata_i (instr_rdata_i),
      .obi_rvalid_i(instr_rvalid_i),
      .obi_err_i   (instr_err_i)
  );

endmodule
