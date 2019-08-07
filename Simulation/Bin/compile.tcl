# Added te +acc flagg, it may make the simulations run faster, see http://www.pldworld.com/_hdl/2/_ref/se_html/manual_html/c_vlog19.html

set PATH ../../HardwareDescription

# Compile all of the RISCV Modules
### Constants ###
vlog +acc -sv -work work $PATH/Constants/constants.sv
#################

### Fetch Unit ###
# Branch Prediction Unit
vlog +acc -sv -work work $PATH/FetchUnit/BranchPredictionUnit/bpu.sv

# Instruction Cache
vlog +acc -sv -work work $PATH/FetchUnit/InstructionCache/i_cache.sv
vlog +acc -sv -work work $PATH/FetchUnit/InstructionCache/icache_controller.sv

# FetchUnit Block
vlog +acc -sv -work work $PATH/FetchUnit/fetch_unit.sv
##################

### Register File ###
vlog +acc -sv -work work $PATH/RegisterFile/reg_file.sv
#####################

### Arithmetic Logic Unit ###
vlog +acc -sv -work work $PATH/ALU/alu.sv
#############################

### Forward Unit ###
vlog +acc -sv -work work $PATH/ForwardUnit/forwardunit.sv
#####################

### Control Unit ###
vlog +acc -sv -work work $PATH/ControlUnit/cu.sv
##################

### Data RAM ###
vlog +acc -sv -work work $PATH/DRAM/dram.sv
##################

### RISCV Core ###
vlog +acc -sv -work work $PATH/RISCVCore/riscv_core.sv
##################

### RISCV Testbench ###
vlog +acc -sv -work work $PATH/Testbench/riscv_tester.sv
#######################

# Launch RISCV Core simulator
vsim -t ns work.riscv_tester

# # Add waves
# add wave -position insertpoint sim:/riscv_tester/riscv_processor/register_file/registers
# add wave -position insertpoint sim:/riscv_tester/riscv_processor/control_unit/state
# add wave -position insertpoint sim:/riscv_tester/riscv_processor/control_unit/next_state
# add wave -position insertpoint sim:/riscv_tester/riscv_processor/*

source ./wave.do

radix -h

# Run the simulation
run 1500 ns