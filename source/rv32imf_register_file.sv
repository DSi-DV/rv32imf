// This module implements a register file for the RV32IMF processor.
// It supports both integer and floating-point registers, with optional ZFINX extension.

module rv32imf_register_file #(
    parameter int ADDR_WIDTH = 5,   // Address width for the register file
    parameter int DATA_WIDTH = 32,  // Data width for the register file
    parameter int FPU        = 0,   // Enable floating-point unit
    parameter int ZFINX      = 0    // Enable ZFINX extension
) (
    input logic clk,          // Clock signal
    input logic rst_n,        // Active low reset signal
    input logic scan_cg_en_i, // Scan clock gating enable

    input  logic [ADDR_WIDTH-1:0] raddr_a_i,  // Read address A
    output logic [DATA_WIDTH-1:0] rdata_a_o,  // Read data A

    input  logic [ADDR_WIDTH-1:0] raddr_b_i,  // Read address B
    output logic [DATA_WIDTH-1:0] rdata_b_o,  // Read data B

    input  logic [ADDR_WIDTH-1:0] raddr_c_i,  // Read address C
    output logic [DATA_WIDTH-1:0] rdata_c_o,  // Read data C

    input logic [ADDR_WIDTH-1:0] waddr_a_i,  // Write address A
    input logic [DATA_WIDTH-1:0] wdata_a_i,  // Write data A
    input logic                  we_a_i,     // Write enable A

    input logic [ADDR_WIDTH-1:0] waddr_b_i,  // Write address B
    input logic [DATA_WIDTH-1:0] wdata_b_i,  // Write data B
    input logic                  we_b_i      // Write enable B
);

  // Number of integer registers
  localparam int NumWords = 2 ** (ADDR_WIDTH - 1);
  // Number of floating-point registers
  localparam int NumFPWords = 2 ** (ADDR_WIDTH - 1);
  // Total number of registers
  localparam int NumTotalWords = FPU ? (ZFINX ? NumWords : NumWords + NumFPWords) : NumWords;

  // Integer register memory
  logic [NumWords-1:0][DATA_WIDTH-1:0] mem;

  // Floating-point register memory
  logic [NumFPWords-1:0][DATA_WIDTH-1:0] mem_fp;

  logic [ADDR_WIDTH-1:0] waddr_a;
  logic [ADDR_WIDTH-1:0] waddr_b;

  // Write enable decoders
  logic [NumTotalWords-1:0] we_a_dec;
  logic [NumTotalWords-1:0] we_b_dec;

  // Read data assignment
  assign rdata_a_o = raddr_a_i[5] ? mem_fp[raddr_a_i[4:0]] : mem[raddr_a_i[4:0]];
  assign rdata_b_o = raddr_b_i[5] ? mem_fp[raddr_b_i[4:0]] : mem[raddr_b_i[4:0]];
  assign rdata_c_o = raddr_c_i[5] ? mem_fp[raddr_c_i[4:0]] : mem[raddr_c_i[4:0]];

  assign waddr_a   = waddr_a_i;
  assign waddr_b   = waddr_b_i;

  // Generate write enable decoders
  for (genvar gidx = 0; gidx < NumTotalWords; gidx++) begin : gen_we_decoder
    assign we_a_dec[gidx] = (waddr_a == gidx) ? we_a_i : 1'b0;
    assign we_b_dec[gidx] = (waddr_b == gidx) ? we_b_i : 1'b0;
  end

  // Initialize register 0 to zero
  always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      mem[0] <= 32'b0;
    end else begin
      mem[0] <= 32'b0;
    end
  end

  // Register write logic for integer registers
  for (genvar i = 1; i < NumWords; i++) begin : gen_rf
    always_ff @(posedge clk, negedge rst_n) begin : register_write_behavioral
      if (rst_n == 1'b0) begin
        mem[i] <= 32'b0;
      end else begin
        if (we_b_dec[i] == 1'b1) mem[i] <= wdata_b_i;
        else if (we_a_dec[i] == 1'b1) mem[i] <= wdata_a_i;
      end
    end
  end

  // Register write logic for floating-point registers
  if (FPU == 1 && ZFINX == 0) begin : gen_mem_fp_write
    for (genvar l = 0; l < NumFPWords; l++) begin : gen_fpu_regs
      always_ff @(posedge clk, negedge rst_n) begin : fp_regs
        if (rst_n == 1'b0) mem_fp[l] <= '0;
        else if (we_b_dec[l+NumWords] == 1'b1) mem_fp[l] <= wdata_b_i;
        else if (we_a_dec[l+NumWords] == 1'b1) mem_fp[l] <= wdata_a_i;
      end
    end
  end else begin : gen_no_mem_fp_write
    assign mem_fp = 'b0;
  end

endmodule
