`ifndef COMMON_CELLS_REGISTERS_SVH_
`define COMMON_CELLS_REGISTERS_SVH_ 0

`define FF(__q, __d, __reset_value)                  \
  always_ff @(posedge clk_i or negedge rst_ni) begin \
    if (!rst_ni) begin                               \
      __q <= (__reset_value);                        \
    end else begin                                   \
      __q <= (__d);                                  \
    end                                              \
  end

`define FFAR(__q, __d, __reset_value, __clk, __arst)     \
  always_ff @(posedge (__clk) or posedge (__arst)) begin \
    if (__arst) begin                                    \
      __q <= (__reset_value);                            \
    end else begin                                       \
      __q <= (__d);                                      \
    end                                                  \
  end

`define FFARN(__q, __d, __reset_value, __clk, __arst_n)    \
  always_ff @(posedge (__clk) or negedge (__arst_n)) begin \
    if (!__arst_n) begin                                   \
      __q <= (__reset_value);                              \
    end else begin                                         \
      __q <= (__d);                                        \
    end                                                    \
  end

`define FFSR(__q, __d, __reset_value, __clk, __reset_clk) \
  always_ff @(posedge (__clk)) begin                      \
    __q <= (__reset_clk) ? (__reset_value) : (__d);       \
  end

`define FFSRN(__q, __d, __reset_value, __clk, __reset_n_clk) \
  always_ff @(posedge (__clk)) begin                         \
    __q <= (!__reset_n_clk) ? (__reset_value) : (__d);       \
  end

`define FFNR(__q, __d, __clk)        \
  always_ff @(posedge (__clk)) begin \
    __q <= (__d);                    \
  end

`define FFL(__q, __d, __load, __reset_value)         \
  always_ff @(posedge clk_i or negedge rst_ni) begin \
    if (!rst_ni) begin                               \
      __q <= (__reset_value);                        \
    end else begin                                   \
      __q <= (__load) ? (__d) : (__q);               \
    end                                              \
  end

`define FFLAR(__q, __d, __load, __reset_value, __clk, __arst) \
  always_ff @(posedge (__clk) or posedge (__arst)) begin      \
    if (__arst) begin                                         \
      __q <= (__reset_value);                                 \
    end else begin                                            \
      __q <= (__load) ? (__d) : (__q);                        \
    end                                                       \
  end

`define FFLARN(__q, __d, __load, __reset_value, __clk, __arst_n) \
  always_ff @(posedge (__clk) or negedge (__arst_n)) begin       \
    if (!__arst_n) begin                                         \
      __q <= (__reset_value);                                    \
    end else begin                                               \
      __q <= (__load) ? (__d) : (__q);                           \
    end                                                          \
  end

`define FFLSR(__q, __d, __load, __reset_value, __clk, __reset_clk)       \
  always_ff @(posedge (__clk)) begin                                     \
    __q <= (__reset_clk) ? (__reset_value) : ((__load) ? (__d) : (__q)); \
  end

`define FFLSRN(__q, __d, __load, __reset_value, __clk, __reset_n_clk)       \
  always_ff @(posedge (__clk)) begin                                        \
    __q <= (!__reset_n_clk) ? (__reset_value) : ((__load) ? (__d) : (__q)); \
  end

`define FFLARNC(__q, __d, __load, __clear, __reset_value, __clk, __arst_n) \
  always_ff @(posedge (__clk) or negedge (__arst_n)) begin                 \
    if (!__arst_n) begin                                                   \
      __q <= (__reset_value);                                              \
    end else begin                                                         \
      __q <= (__clear) ? (__reset_value) : (__load) ? (__d) : (__q);       \
    end                                                                    \
  end

`define FFLNR(__q, __d, __load, __clk) \
  always_ff @(posedge (__clk)) begin   \
    __q <= (__load) ? (__d) : (__q);   \
  end

`endif
