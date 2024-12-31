// Top-level wrapper for RISC-V RV32IMF core implementation
// This module serves as the top-level wrapper for the RV32IMF core,
// connecting it to the external interfaces for clock, reset, memory, and interrupts.

module rv32imf (

    // Clock and reset signals
    input logic clk_i,
    input logic rst_ni,

    // Boot and exception handling configuration
    input logic [31:0] boot_addr_i,
    input logic [31:0] mtvec_addr_i,
    input logic [31:0] dm_halt_addr_i,
    input logic [31:0] hart_id_i,
    input logic [31:0] dm_exception_addr_i,

    // Instruction memory interface
    output logic        instr_req_o,
    input  logic        instr_gnt_i,
    input  logic        instr_rvalid_i,
    output logic [31:0] instr_addr_o,
    input  logic [31:0] instr_rdata_i,

    // Data memory interface
    output logic        data_req_o,
    input  logic        data_gnt_i,
    input  logic        data_rvalid_i,
    output logic        data_we_o,
    output logic [ 3:0] data_be_o,
    output logic [31:0] data_addr_o,
    output logic [31:0] data_wdata_o,
    input  logic [31:0] data_rdata_i,

    // Interrupt interface
    input  logic [31:0] irq_i,
    output logic        irq_ack_o,
    output logic [ 4:0] irq_id_o
);

  // Instance of core with Floating Point Unit enabled
  rv32imf_top #(
      .FPU(1)
  ) rv32imf_top_inst (
      .clk_i              (clk_i),
      .rst_ni             (rst_ni),
      .pulp_clock_en_i    ('0),
      .scan_cg_en_i       ('0),
      .boot_addr_i        (boot_addr_i),
      .mtvec_addr_i       (mtvec_addr_i),
      .dm_halt_addr_i     (dm_halt_addr_i),
      .hart_id_i          (hart_id_i),
      .dm_exception_addr_i(dm_exception_addr_i),
      .instr_req_o        (instr_req_o),
      .instr_gnt_i        (instr_gnt_i),
      .instr_rvalid_i     (instr_rvalid_i),
      .instr_addr_o       (instr_addr_o),
      .instr_rdata_i      (instr_rdata_i),
      .data_req_o         (data_req_o),
      .data_gnt_i         (data_gnt_i),
      .data_rvalid_i      (data_rvalid_i),
      .data_we_o          (data_we_o),
      .data_be_o          (data_be_o),
      .data_addr_o        (data_addr_o),
      .data_wdata_o       (data_wdata_o),
      .data_rdata_i       (data_rdata_i),
      .irq_i              (irq_i),
      .irq_ack_o          (irq_ack_o),
      .irq_id_o           (irq_id_o),
      .debug_req_i        ('0),
      .debug_havereset_o  (),
      .debug_running_o    (),
      .debug_halted_o     (),
      .fetch_enable_i     ('1),
      .core_sleep_o       ()
  );

endmodule
