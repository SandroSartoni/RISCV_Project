set PATH ../../HardwareDescription

# Compile all of the RISCV Modules
### Constants ###
vlog -sv -work work $PATH/Constants/constants.sv
#################

### Fetch Unit ###
# Branch Prediction Unit
vlog -sv -work work $PATH/FetchUnit/BranchPredictionUnit/bpu.sv

# Instruction Cache
vlog -sv -work work $PATH/FetchUnit/InstructionCache/i_cache.sv
vlog -sv -work work $PATH/FetchUnit/InstructionCache/icache_controller.sv

# FetchUnit Block
vlog -sv -work work $PATH/FetchUnit/fetch_unit.sv
##################

### Register File ###
vlog -sv -work work $PATH/RegisterFile/reg_file.sv
#####################

### Arithmetic Logic Unit ###
vlog -sv -work work $PATH/ALU/alu.sv
#############################

### Forward Unit ###
vlog -sv -work work $PATH/ForwardUnit/forwardunit.sv
#####################

### Control Unit ###
vlog -sv -work work $PATH/ControlUnit/cu.sv
##################

### Data RAM ###
vlog -sv -work work $PATH/DRAM/dram.sv
##################

### RISCV Core ###
vlog -sv -work work $PATH/RISCVCore/riscv_core.sv
##################

### RISCV Testbench ###
vlog -sv -work work $PATH/Testbench/riscv_tester.sv
#######################

# Launch RISCV Core simulator
vsim -t ns work.riscv_tester

# Add waves
add wave -position insertpoint sim:/riscv_tester/riscv_processor/*
add wave -position insertpoint sim:/riscv_tester/riscv_processor/register_file/registers
radix -h
