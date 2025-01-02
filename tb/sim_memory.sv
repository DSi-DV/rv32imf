// This module simulates a memory for instruction and data access in a testbench environment.
// It handles instruction and data requests, grants, and read/write operations with random delays.

module sim_memory (
    // Clock and reset signals
    input logic clk_i,
    input logic rst_ni,

    // Instruction interface
    input  logic        instr_req_i,    // Instruction request
    input  logic [31:0] instr_addr_i,   // Instruction address
    output logic        instr_gnt_o,    // Instruction grant
    output logic [31:0] instr_rdata_o,  // Instruction read data
    output logic        instr_rvalid_o, // Instruction read valid

    // Data interface
    input  logic        data_req_i,     // Data request
    input  logic [31:0] data_addr_i,    // Data address
    input  logic        data_we_i,      // Data write enable
    input  logic [31:0] data_wdata_i,   // Data write data
    input  logic [ 3:0] data_be_i,      // Data byte enable
    output logic        data_gnt_o,     // Data grant
    output logic        data_rvalid_o,  // Data read valid
    output logic [31:0] data_rdata_o    // Data read data
);

  // Internal signals for instruction and data grants
  logic instr_gnt;
  logic data_gnt;

  // Memory array
  bit [7:0] mem[int];

  // Queues for instruction and data read data
  logic [31:0] instr_rdata_queue[$];
  logic [31:0] data_rdata_queue[$];

  // Assign grant signals based on internal logic and requests
  assign instr_gnt_o = instr_gnt & instr_req_i;
  assign data_gnt_o  = data_gnt & data_req_i;

  // Generate instruction grant signal based on request and random delay
  always @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      instr_gnt <= '0;
    end else begin
      instr_gnt <= ($urandom_range(0, 4) == 0) ? 1'b0 : instr_req_i;
    end
  end

  // Generate data grant signal based on request and random delay
  always @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      data_gnt <= '0;
    end else begin
      data_gnt <= ($urandom_range(0, 2) == 0) ? 1'b0 : data_req_i;
    end
  end

  // Handle instruction read valid signal and data queue
  always @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      instr_rdata_queue.delete();
      instr_rdata_o  <= '0;
      instr_rvalid_o <= '0;
    end else begin
      if (instr_rdata_queue.size()) begin
        instr_rdata_o  <= instr_rdata_queue.pop_front();
        instr_rvalid_o <= 1'b1;
      end else begin
        instr_rvalid_o <= 1'b0;
      end
      if (instr_req_i && instr_gnt_o) begin
        instr_rdata_queue.push_back({
                                    mem[{instr_addr_i[31:2], 2'b0}+3],
                                    mem[{instr_addr_i[31:2], 2'b0}+2],
                                    mem[{instr_addr_i[31:2], 2'b0}+1],
                                    mem[{instr_addr_i[31:2], 2'b0}]
                                    });
      end
    end
  end

  // Handle data read valid signal and data queue
  always @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      data_rdata_queue.delete();
      data_rdata_o  <= '0;
      data_rvalid_o <= '0;
    end else begin
      if (data_rdata_queue.size()) begin
        data_rdata_o  <= data_rdata_queue.pop_front();
        data_rvalid_o <= 1'b1;
      end else begin
        data_rvalid_o <= 1'b0;
      end
      if (data_req_i && data_gnt_o) begin
        if (data_we_i) begin
          // Write data to memory based on byte enable signals
          for (int i = 0; i < 4; i++) begin
            if (data_be_i[i]) begin
              mem[{data_addr_i[31:2], 2'b0}+i] = data_wdata_i[8*i+:8];
            end
          end
        end
        // Push read data to the queue
        data_rdata_queue.push_back({
                                   mem[{data_addr_i[31:2], 2'b0}+3],
                                   mem[{data_addr_i[31:2], 2'b0}+2],
                                   mem[{data_addr_i[31:2], 2'b0}+1],
                                   mem[{data_addr_i[31:2], 2'b0}]
                                   });
      end
    end
  end

endmodule
