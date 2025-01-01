// This module implements a prefetch controller for the RV32IMF processor.
// It handles instruction prefetching, branching, and hardware loop jumps.

module rv32imf_prefetch_controller #(
    parameter int PULP_OBI        = 0,                               // Enable PULP OBI interface
    parameter int COREV_PULP      = 1,                               // Enable COREV PULP support
    parameter int DEPTH           = 4,                               // Depth of the prefetch FIFO
    parameter int FIFO_ADDR_DEPTH = (DEPTH > 1) ? $clog2(DEPTH) : 1  // Address depth of the FIFO
) (
    input logic clk,   // Clock signal
    input logic rst_n, // Active low reset signal

    input  logic        req_i,          // Request input
    input  logic        branch_i,       // Branch input
    input  logic [31:0] branch_addr_i,  // Branch address input
    output logic        busy_o,         // Busy output

    input logic        hwlp_jump_i,   // Hardware loop jump input
    input logic [31:0] hwlp_target_i, // Hardware loop target address input

    output logic        trans_valid_o,  // Transaction valid output
    input  logic        trans_ready_i,  // Transaction ready input
    output logic [31:0] trans_addr_o,   // Transaction address output

    input logic resp_valid_i,  // Response valid input

    input  logic fetch_ready_i,  // Fetch ready input
    output logic fetch_valid_o,  // Fetch valid output

    output logic                     fifo_push_o,             // FIFO push output
    output logic                     fifo_pop_o,              // FIFO pop output
    output logic                     fifo_flush_o,            // FIFO flush output
    output logic                     fifo_flush_but_first_o,  // FIFO flush but first output
    input  logic [FIFO_ADDR_DEPTH:0] fifo_cnt_i,              // FIFO count input
    input  logic                     fifo_empty_i             // FIFO empty input
);

  import rv32imf_pkg::*;

  prefetch_state_e state_q, next_state;

  logic [FIFO_ADDR_DEPTH:0] cnt_q;
  logic [FIFO_ADDR_DEPTH:0] next_cnt;
  logic                     count_up;
  logic                     count_down;

  logic [FIFO_ADDR_DEPTH:0] flush_cnt_q;
  logic [FIFO_ADDR_DEPTH:0] next_flush_cnt;

  logic [31:0] trans_addr_q, trans_addr_incr;
  logic [             31:0] aligned_branch_addr;

  logic                     fifo_valid;
  logic [FIFO_ADDR_DEPTH:0] fifo_cnt_masked;

  logic                     hwlp_wait_resp_flush;
  logic                     hwlp_flush_after_resp;
  logic [FIFO_ADDR_DEPTH:0] hwlp_flush_cnt_delayed_q;
  logic                     hwlp_flush_resp_delayed;
  logic                     hwlp_flush_resp;

  // Busy signal assignment
  assign busy_o = (cnt_q != 3'b000) || trans_valid_o;

  // Fetch valid signal assignment
  assign fetch_valid_o = (fifo_valid || resp_valid_i) && !(branch_i || (flush_cnt_q > 0));

  // Align branch address to 4-byte boundary
  assign aligned_branch_addr = {branch_addr_i[31:2], 2'b00};

  // Increment transaction address by 4
  assign trans_addr_incr = {trans_addr_q[31:2], 2'b00} + 32'd4;

  if (PULP_OBI == 0) begin : gen_no_pulp_obi
    // Transaction valid signal assignment without PULP OBI
    assign trans_valid_o = req_i && (fifo_cnt_masked + cnt_q < DEPTH);
  end else begin : gen_pulp_obi
    // Transaction valid signal assignment with PULP OBI
    assign trans_valid_o = (cnt_q == 3'b000) ?
      req_i && (fifo_cnt_masked + cnt_q < DEPTH) :
      req_i && (fifo_cnt_masked + cnt_q < DEPTH) && resp_valid_i;
  end

  // Mask FIFO count based on branch or hardware loop jump
  assign fifo_cnt_masked = (branch_i || hwlp_jump_i) ? '0 : fifo_cnt_i;

  always_comb begin
    next_state   = state_q;
    trans_addr_o = trans_addr_q;

    case (state_q)
      default: begin  // IDLE
        if (branch_i) begin
          trans_addr_o = aligned_branch_addr;
        end else if (hwlp_jump_i) begin
          trans_addr_o = hwlp_target_i;
        end else begin
          trans_addr_o = trans_addr_incr;
        end
        if ((branch_i || hwlp_jump_i) && !(trans_valid_o && trans_ready_i)) begin
          next_state = BRANCH_WAIT;
        end
      end

      BRANCH_WAIT: begin
        trans_addr_o = branch_i ? aligned_branch_addr : trans_addr_q;
        if (trans_valid_o && trans_ready_i) begin
          next_state = IDLE;
        end
      end
    endcase
  end

  // FIFO control signals
  assign fifo_valid = !fifo_empty_i;
  assign fifo_push_o = resp_valid_i &&
                      (fifo_valid || !fetch_ready_i) && !(branch_i || (flush_cnt_q > 0));
  assign fifo_pop_o = fifo_valid && fetch_ready_i;

  // Count up and down logic
  assign count_up = trans_valid_o && trans_ready_i;
  assign count_down = resp_valid_i;

  always_comb begin
    case ({
      count_up, count_down
    })
      2'b01:   next_cnt = cnt_q - 1'b1;
      2'b10:   next_cnt = cnt_q + 1'b1;
      default: next_cnt = cnt_q;
    endcase
  end

  if (COREV_PULP) begin : gen_hwlp
    // Hardware loop control signals
    assign fifo_flush_o           = branch_i || (hwlp_jump_i && !fifo_empty_i && fifo_pop_o);
    assign fifo_flush_but_first_o = (hwlp_jump_i && !fifo_empty_i && !fifo_pop_o);
    assign hwlp_flush_resp        = hwlp_jump_i && !(fifo_empty_i && !resp_valid_i);
    assign hwlp_wait_resp_flush   = hwlp_jump_i && (fifo_empty_i && !resp_valid_i);

    always_ff @(posedge clk or negedge rst_n) begin
      if (~rst_n) begin
        hwlp_flush_after_resp    <= 1'b0;
        hwlp_flush_cnt_delayed_q <= 2'b00;
      end else begin
        if (branch_i) begin
          hwlp_flush_after_resp    <= 1'b0;
          hwlp_flush_cnt_delayed_q <= 2'b00;
        end else begin
          if (hwlp_wait_resp_flush) begin
            hwlp_flush_after_resp    <= 1'b1;
            hwlp_flush_cnt_delayed_q <= cnt_q - 1'b1;
          end else begin
            if (hwlp_flush_resp_delayed) begin
              hwlp_flush_after_resp    <= 1'b0;
              hwlp_flush_cnt_delayed_q <= 2'b00;
            end
          end
        end
      end
    end

    assign hwlp_flush_resp_delayed = hwlp_flush_after_resp && resp_valid_i;

  end else begin : gen_no_hwlp
    // No hardware loop control signals
    assign fifo_flush_o             = branch_i;
    assign fifo_flush_but_first_o   = 1'b0;
    assign hwlp_flush_resp          = 1'b0;
    assign hwlp_wait_resp_flush     = 1'b0;
    assign hwlp_flush_after_resp    = 1'b0;
    assign hwlp_flush_cnt_delayed_q = 2'b00;
    assign hwlp_flush_resp_delayed  = 1'b0;
  end

  always_comb begin
    next_flush_cnt = flush_cnt_q;
    if (branch_i || hwlp_flush_resp) begin
      next_flush_cnt = cnt_q;
      if (resp_valid_i && (cnt_q > 0)) begin
        next_flush_cnt = cnt_q - 1'b1;
      end
    end else if (hwlp_flush_resp_delayed) begin
      next_flush_cnt = hwlp_flush_cnt_delayed_q;
    end else if (resp_valid_i && (flush_cnt_q > 0)) begin
      next_flush_cnt = flush_cnt_q - 1'b1;
    end
  end

  always_ff @(posedge clk, negedge rst_n) begin
    if (rst_n == 1'b0) begin
      state_q      <= IDLE;
      cnt_q        <= '0;
      flush_cnt_q  <= '0;
      trans_addr_q <= '0;
    end else begin
      state_q     <= next_state;
      cnt_q       <= next_cnt;
      flush_cnt_q <= next_flush_cnt;
      if (branch_i || hwlp_jump_i || (trans_valid_o && trans_ready_i)) begin
        trans_addr_q <= trans_addr_o;
      end
    end
  end

endmodule
