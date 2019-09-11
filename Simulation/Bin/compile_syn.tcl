# Added te +acc flag, it may make the simulations run faster, see http://www.pldworld.com/_hdl/2/_ref/se_html/manual_html/c_vlog19.html

set PATH ../../HardwareDescription
set SYN_PATH ../../Synthesis/SynthetizedCore

# Compile the library, core and testbench
### Library ###
vlog +acc -work work $SYN_PATH/NangateOpenCellLibrary.v
#################

### RISCV Core ###
vlog +acc -work work $SYN_PATH/riscv_syn_im.v
##################

### RISCV Testbench ###
vlog +acc -sv +define+post_synthesis -work work $PATH/Testbench/riscv_tester.sv
#######################

# Launch RISCV Core simulator
vsim -t ns work.riscv_tester

# Add waves
#add wave -position insertpoint sim:/riscv_tester/riscv_processor/*
#add wave -position insertpoint sim:/riscv_tester/riscv_processor/register_file/registers
# add wave -position insertpoint sim:/riscv_tester/riscv_processor/control_unit/state
# add wave -position insertpoint sim:/riscv_tester/riscv_processor/control_unit/next_state

source ../Bin/wave.do

radix -h

# Run the simulation
run 1500 ns
