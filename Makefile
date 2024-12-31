# Set the default goal to 'help'
.DEFAULT_GOAL := help

# Define the root directory
ROOT     := $(shell echo "$(realpath .)")

# Define the grep command for warnings and errors
GREP_EW       := grep -E "WARNING:|ERROR:|" --color=auto

# Define the GCC command for RISC-V
RV64G_GCC     := riscv64-unknown-elf-gcc -march=rv32imf -mabi=ilp32 -nostdlib -nostartfiles 

################################################################################
# Add all the RTL source files to the LIB variable
################################################################################

LIB += ${ROOT}/source/rv32imf_apu_core_pkg.sv
LIB += ${ROOT}/source/rv32imf_pkg.sv
LIB += ${ROOT}/source/rv32imf_fpu_pkg.sv
LIB += ${ROOT}/source/fpnew_pkg.sv
LIB += ${ROOT}/source/cf_math_pkg.sv
LIB += ${ROOT}/source/rv32imf_clock_gate.sv
LIB += ${ROOT}/source/rv32imf_sleep_unit.sv
LIB += ${ROOT}/source/rv32imf_prefetch_controller.sv
LIB += ${ROOT}/source/rv32imf_fifo.sv
LIB += ${ROOT}/source/rv32imf_obi_interface.sv
LIB += ${ROOT}/source/rv32imf_prefetch_buffer.sv
LIB += ${ROOT}/source/rv32imf_aligner.sv
LIB += ${ROOT}/source/rv32imf_compressed_decoder.sv
LIB += ${ROOT}/source/rv32imf_if_stage.sv
LIB += ${ROOT}/source/rv32imf_register_file_ff.sv
LIB += ${ROOT}/source/rv32imf_decoder.sv
LIB += ${ROOT}/source/rv32imf_controller.sv
LIB += ${ROOT}/source/rv32imf_int_controller.sv
LIB += ${ROOT}/source/rv32imf_id_stage.sv
LIB += ${ROOT}/source/rv32imf_popcnt.sv
LIB += ${ROOT}/source/rv32imf_ff_one.sv
LIB += ${ROOT}/source/rv32imf_alu_div.sv
LIB += ${ROOT}/source/rv32imf_alu.sv
LIB += ${ROOT}/source/rv32imf_mult.sv
LIB += ${ROOT}/source/rv32imf_apu_disp.sv
LIB += ${ROOT}/source/rv32imf_ex_stage.sv
LIB += ${ROOT}/source/rv32imf_load_store_unit.sv
LIB += ${ROOT}/source/rv32imf_cs_registers.sv
LIB += ${ROOT}/source/rv32imf_core.sv
LIB += ${ROOT}/source/fpnew_classifier.sv
LIB += ${ROOT}/source/lzc.sv
LIB += ${ROOT}/source/fpnew_rounding.sv
LIB += ${ROOT}/source/fpnew_fma_multi.sv
LIB += ${ROOT}/source/fpnew_opgroup_multifmt_slice.sv
LIB += ${ROOT}/source/rr_arb_tree.sv
LIB += ${ROOT}/source/fpnew_opgroup_block.sv
LIB += ${ROOT}/source/pa_fdsu_special.v
LIB += ${ROOT}/source/pa_fdsu_ff1.v
LIB += ${ROOT}/source/pa_fdsu_prepare.v
LIB += ${ROOT}/source/gated_clk_cell.v
LIB += ${ROOT}/source/pa_fdsu_srt_single.v
LIB += ${ROOT}/source/pa_fdsu_round_single.v
LIB += ${ROOT}/source/pa_fdsu_pack_single.v
LIB += ${ROOT}/source/pa_fdsu_ctrl.v
LIB += ${ROOT}/source/pa_fdsu_top.v
LIB += ${ROOT}/source/pa_fpu_src_type.v
LIB += ${ROOT}/source/pa_fpu_dp.v
LIB += ${ROOT}/source/pa_fpu_frbus.v
LIB += ${ROOT}/source/fpnew_divsqrt_th_32.sv
LIB += ${ROOT}/source/fpnew_noncomp.sv
LIB += ${ROOT}/source/fpnew_opgroup_fmt_slice.sv
LIB += ${ROOT}/source/fpnew_cast_multi.sv
LIB += ${ROOT}/source/fpnew_top.sv
LIB += ${ROOT}/source/rv32imf_fp_wrapper.sv
LIB += ${ROOT}/source/rv32imf_top.sv
LIB += ${ROOT}/source/rv32imf.sv

################################################################################
# Add all the testbench files to the LIB variable
################################################################################

LIB += ${ROOT}/tb/sim_memory.sv
LIB += ${ROOT}/tb/rv32imf_tb.sv

################################################################################
# TARGETS
################################################################################

# Define the 'vivado' target to clean and run the build
.PHONY: vivado
vivado: clean run

# Define the 'clean' target to remove the build directory
.PHONY: clean
clean:
	@rm -rf build
	@make -s build

# Define the 'build' target to create the build directory and add it to gitignore
build:
	@mkdir -p build
	@echo "*" > build/.gitignore
	@git add build > /dev/null 2>&1

# Define the 'build/done' target to compile the project
build/done:
	@make -s compile

# Define the 'compile' target to compile the source files
.PHONY: compile
compile: build
	@cd build; xvlog -i ${ROOT}/include -sv ${LIB} | $(GREP_EW)
	@cd build; xelab rv32imf_tb -s top | $(GREP_EW)
	@echo "build done" > build/done

# Define the 'run' target to run the tests
.PHONY: run
run: build/done
	@make -s test TEST=$(TEST)
	@cd build; xsim top -runall | $(GREP_EW)

# Define the 'test' target to compile and run a specific test
.PHONY: test
test: build
	@if [ -z ${TEST} ]; then echo -e "\033[1;31mTEST is not set\033[0m"; exit 1; fi
	@if [ ! -f tests/$(TEST) ]; then echo -e "\033[1;31mtests/$(TEST) does not exist\033[0m"; exit 1; fi
	@$(eval TEST_TYPE := $(shell echo "$(TEST)" | sed "s/.*\.//g"))
	@if [ "$(TEST_TYPE)" = "c" ]; then TEST_ARGS="lib/startup.s"; else TEST_ARGS=""; fi; \
		$(RV64G_GCC) -o build/$(TEST).elf tests/$(TEST) $$TEST_ARGS -Ilib
	@riscv64-unknown-elf-objcopy -O verilog build/$(TEST).elf build/prog.hex
	@riscv64-unknown-elf-nm build/$(TEST).elf > build/prog.sym
	@riscv64-unknown-elf-objdump -d build/$(TEST).elf > build/$(TEST).dump

# Define the 'help' target to display usage information
.PHONY: help
help:
	@echo -e "\033[1;32mUsage:\033[0m"
	@echo -e "\033[1;35m  make help                \033[0m# Display this help message"
	@echo -e "\033[1;35m  make clean               \033[0m# Remove the build directory"
	@echo -e "\033[1;35m  make vivado TEST=<test>  \033[0m# Clean and run the build"
	@echo -e "\033[1;35m  make run TEST=<test>     \033[0m# Run the tests"
	@echo -e ""
	@echo -e "\033[1;32mExamples:\033[0m"
	@for file in $(shell ls tests); do \
		if [ $${file##*.} = "c" ] || [ $${file##*.} = "s" ]; then \
			echo -e "\033[1;35m  make run TEST=$${file}\033[0m"; \
		fi; \
	done
