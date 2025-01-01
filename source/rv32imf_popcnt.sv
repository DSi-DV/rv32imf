// This module implements a population count (popcount) for a 32-bit input.
// It counts the number of '1' bits in the input.

module rv32imf_popcnt (
    input logic [31:0] in_i,  // 32-bit input
    output logic [5:0] result_o  // 6-bit result (since max count of 1s in 32 bits is 32)
);

  logic [15:0][1:0] cnt_l1;  // Level 1 count
  logic [ 7:0][2:0] cnt_l2;  // Level 2 count
  logic [ 3:0][3:0] cnt_l3;  // Level 3 count
  logic [ 1:0][4:0] cnt_l4;  // Level 4 count

  genvar l, m, n, p;
  generate
    // Level 1: Count bits in pairs
    for (l = 0; l < 16; l++) begin : gen_cnt_l1
      assign cnt_l1[l] = {1'b0, in_i[2*l]} + {1'b0, in_i[2*l+1]};
    end
  endgenerate

  generate
    // Level 2: Sum pairs of Level 1 counts
    for (m = 0; m < 8; m++) begin : gen_cnt_l2
      assign cnt_l2[m] = {1'b0, cnt_l1[2*m]} + {1'b0, cnt_l1[2*m+1]};
    end
  endgenerate

  generate
    // Level 3: Sum pairs of Level 2 counts
    for (n = 0; n < 4; n++) begin : gen_cnt_l3
      assign cnt_l3[n] = {1'b0, cnt_l2[2*n]} + {1'b0, cnt_l2[2*n+1]};
    end
  endgenerate

  generate
    // Level 4: Sum pairs of Level 3 counts
    for (p = 0; p < 2; p++) begin : gen_cnt_l4
      assign cnt_l4[p] = {1'b0, cnt_l3[2*p]} + {1'b0, cnt_l3[2*p+1]};
    end
  endgenerate

  // Final result: Sum of Level 4 counts
  assign result_o = {1'b0, cnt_l4[0]} + {1'b0, cnt_l4[1]};

endmodule
