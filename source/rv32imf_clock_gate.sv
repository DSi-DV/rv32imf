// This module implements a clock gating cell for power saving.

module rv32imf_clock_gate (
    input  logic clk_i,         // Input clock
    input  logic en_i,          // Enable signal
    input  logic scan_cg_en_i,  // Scan clock gate enable
    output logic clk_o          // Gated clock output
);

  logic clk_en;  // Clock enable signal

  always_latch begin
    if (clk_i == 1'b0) clk_en <= en_i | scan_cg_en_i;  // Latch enable signals when clock is low
  end

  assign clk_o = clk_i & clk_en;  // Generate gated clock

endmodule  // rv32imf_clock_gate
