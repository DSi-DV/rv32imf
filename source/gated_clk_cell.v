module gated_clk_cell(
  clk_in,
  global_en,
  module_en,
  local_en,
  external_en,
  pad_yy_icg_scan_en,
  clk_out
);

input  clk_in;
input  global_en;
input  module_en;
input  local_en;
input  external_en;
input  pad_yy_icg_scan_en;
output clk_out;

wire   clk_en_bf_latch;
wire   SE;

assign clk_en_bf_latch = (global_en && (module_en || local_en)) || external_en ;

// SE driven from primary input, held constant
assign SE	       = pad_yy_icg_scan_en;
 
// //   &Connect(    .clk_in           (clk_in), @50
// //                .SE               (SE), @51
// //                .external_en      (clk_en_bf_latch), @52
// //                .clk_out          (clk_out) @53
// //                ) ; @54

assign clk_out = clk_in;

endmodule   
