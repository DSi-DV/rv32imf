// Math package for RV32IMF core
// This package provides mathematical utility functions such as ceiling division
// and index width calculation.

package cf_math_pkg;

  // Calculates ceiling division of dividend by divisor
  function automatic integer ceil_div(input longint dividend, input longint divisor);
    automatic longint remainder;
    remainder = dividend;
    for (ceil_div = 0; remainder > 0; ceil_div++) begin
      remainder = remainder - divisor;
    end
  endfunction

  // Returns minimum width in bits needed to represent num_idx values
  function automatic integer unsigned idx_width(input integer unsigned num_idx);
    return (num_idx > 32'd1) ? unsigned'($clog2(num_idx)) : 32'd1;
  endfunction

endpackage
