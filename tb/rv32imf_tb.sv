module rv32imf_tb;

  // Display messages at the start and end of the test
  initial $display("\033[7;38m---------------------- TEST STARTED ----------------------\033[0m");
  final $display("\033[7;38m----------------------- TEST ENDED -----------------------\033[0m");

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // DEFINES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Define macros for accessing General Purpose Registers (GPR) and Floating Point Registers (FPR)
  `define GPR rv32imf_tb.u_rv32imf.rv32imf_top_inst.core_i.id_stage_i.register_file_i.mem
  `define FPR rv32imf_tb.u_rv32imf.rv32imf_top_inst.core_i.id_stage_i.register_file_i.mem_fp

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // DUT Instantiation
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Declare signals for the Device Under Test (DUT)
  logic        clk;
  logic        rst_n;
  logic [31:0] boot_addr;
  logic [31:0] mtvec_addr;
  logic [31:0] dm_halt_addr;
  logic [31:0] hart_id;
  logic [31:0] dm_exception_addr;
  logic        instr_req;
  logic        instr_gnt;
  logic        instr_rvalid;
  logic [31:0] instr_addr;
  logic [31:0] instr_rdata;
  logic        data_req;
  logic        data_gnt;
  logic        data_rvalid;
  logic        data_we;
  logic [ 3:0] data_be;
  logic [31:0] data_addr;
  logic [31:0] data_wdata;
  logic [31:0] data_rdata;
  logic [31:0] irq;
  logic        irq_ack;
  logic [ 4:0] irq_id;

  // Instantiate the DUT
  rv32imf u_rv32imf (
      .clk_i              (clk),
      .rst_ni             (rst_n),
      .boot_addr_i        (boot_addr),
      .mtvec_addr_i       (mtvec_addr),
      .dm_halt_addr_i     (dm_halt_addr),
      .hart_id_i          (hart_id),
      .dm_exception_addr_i(dm_exception_addr),
      .instr_req_o        (instr_req),
      .instr_gnt_i        (instr_gnt),
      .instr_rvalid_i     (instr_rvalid),
      .instr_addr_o       (instr_addr),
      .instr_rdata_i      (instr_rdata),
      .data_req_o         (data_req),
      .data_gnt_i         (data_gnt),
      .data_rvalid_i      (data_rvalid),
      .data_we_o          (data_we),
      .data_be_o          (data_be),
      .data_addr_o        (data_addr),
      .data_wdata_o       (data_wdata),
      .data_rdata_i       (data_rdata),
      .irq_i              (irq),
      .irq_ack_o          (irq_ack),
      .irq_id_o           (irq_id)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Memory
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Instantiate the simulated memory
  sim_memory u_mem (
      .clk_i         (clk),
      .rst_ni        (rst_n),
      .instr_req_i   (instr_req),
      .instr_addr_i  (instr_addr),
      .instr_gnt_o   (instr_gnt),
      .instr_rdata_o (instr_rdata),
      .instr_rvalid_o(instr_rvalid),
      .data_req_i    (data_req),
      .data_addr_i   (data_addr),
      .data_we_i     (data_we),
      .data_wdata_i  (data_wdata),
      .data_be_i     (data_be),
      .data_gnt_o    (data_gnt),
      .data_rvalid_o (data_rvalid),
      .data_rdata_o  (data_rdata)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Variables
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Declare dictionary of symbols
  int sym[string];

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Task to start the clock signal
  task static start_clock();
    fork
      forever begin
        clk <= 1'b1;
        #5ns;
        clk <= 1'b0;
        #5ns;
      end
    join_none
  endtask

  // Task to apply reset and initialize inputs
  task static apply_reset();
    #100ns;
    clk               <= '0;
    rst_n             <= '0;
    mtvec_addr        <= '0;
    dm_halt_addr      <= '0;
    hart_id           <= '0;
    dm_exception_addr <= '0;
    irq               <= '0;
    #100ns;
    rst_n <= 1'b1;
    #100ns;
  endtask

  // Task to dump the register file contents to a CSV file
  task static dump_regfile();
    int clk_count;
    int reg_dump;
    clk_count = 0;
    reg_dump  = $fopen("reg_dump.csv", "w");
    $fwrite(reg_dump, "CLOCK,",);
    for (int i = 0; i < 32; i++) $fwrite(reg_dump, "GPR%0d,", i);
    for (int i = 0; i < 32; i++) $fwrite(reg_dump, "FPR%0d,", i);
    $fwrite(reg_dump, "\n");
    fork
      forever begin
        string text;
        clk_count++;
        @(posedge clk);
        $fwrite(reg_dump, "%08d,", clk_count);
        for (int i = 0; i < 32; i++) $fwrite(reg_dump, "0x%08x,", `GPR[i]);
        for (int i = 0; i < 32; i++) $fwrite(reg_dump, "0x%08x,", `FPR[i]);
        $fwrite(reg_dump, "\n");
      end
    join_none
  endtask

  // Function to load memory contents from a file
  function automatic void load_memory(string filename);
    $readmemh(filename, u_mem.mem);
  endfunction

  // Function to load symbols from a file
  function automatic void load_symbols(string filename);
    int file, r;
    string line;
    string key;
    int value;
    file = $fopen(filename, "r");
    if (file == 0) begin
      $display("Error: Could not open file %s", filename);
      $finish;
    end
    while (!$feof(
        file
    )) begin
      r = $fgets(line, file);
      if (r != 0) begin
        r = $sscanf(line, "%h %*s %s", value, key);
        sym[key] = value;
      end
    end
    $fclose(file);
  endfunction

  // Task to monitor and print characters written to the simulated STDOUT
  task static monitor_prints();
    string prints;
    prints = "";
    fork
      forever begin
        @(posedge clk);
        if ((data_addr === sym["putchar_stdout"]
            && data_we === '1 && data_req === '1 && data_gnt === '1)) begin
          if (data_wdata[7:0] == "\n") begin
            $display("\033[1;33mSTDOUT         : %s\033[0m [%0t]", prints, $realtime);
            prints = "";
          end else begin
            $sformat(prints, "%s%c", prints, data_wdata[7:0]);
          end
        end
      end

      // forever begin
      //   @(posedge clk);
      //   if ((data_addr === sym["putchar2_stdout"]
      //       && data_we === '1 && data_req === '1 && data_gnt === '1)) begin
      //     if (data_wdata[7:0] == "\n") begin
      //       $display("\033[1;33mSTDOUT2         : %s\033[0m [%0t]", prints, $realtime);
      //       prints = "";
      //     end else begin
      //       $sformat(prints, "%s%c", prints, data_wdata[7:0]);
      //     end
      //   end
      // end
    join_none
  endtask

  // Task to wait for the test to exit and display the exit code
  task static wait_exit();
    do begin
      @(posedge clk);
    end while (!(data_addr === sym["tohost"] && data_we === '1 && data_be === 'hf &&
                 data_req === '1 && data_gnt === '1));
    $display("\033[0;35mEXIT CODE      : 0x%08x\033[0m", data_wdata);
    if (data_wdata == 0) $display("\033[1;32m************** TEST PASSED **************\033[0m");
    else $display("\033[1;31m************** TEST FAILED **************\033[0m");
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Procedural Blocks
  //////////////////////////////////////////////////////////////////////////////////////////////////

  initial begin

    // Set time format to microseconds
    $timeformat(-6, 3, "us");

    // Dump VCD file
    $dumpfile("rv32imf_tb.vcd");
    $dumpvars(0, rv32imf_tb);

    // Dump register file contents to CSV file
    dump_regfile();

    // Load simulation memory and symbols
    load_memory("prog.hex");
    load_symbols("prog.sym");

    // Set boot address to the start of the program
    boot_addr <= sym["_start"];

    $display("\033[0;35mBOOTADDR       : 0x%08x\033[0m", sym["_start"]);
    $display("\033[0;35mTOHOSTADDR     : 0x%08x\033[0m", sym["tohost"]);
    $display("\033[0;35mPUTCHAR_STDOUT : 0x%08x\033[0m", sym["putchar_stdout"]);
    // $display("\033[0;35mPUTCHAR2_STDOUT : 0x%08x\033[0m", sym["putchar2_stdout"]);

    // Monitor STDOUT prints
    monitor_prints();

    // Apply reset and start clock
    apply_reset();
    start_clock();

    // Wait for the test to exit
    wait_exit();

    // Finish simulation after 100ns
    #100ns $finish;

  end

endmodule
