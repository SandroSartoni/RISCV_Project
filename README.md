# RISCV_Project
# Architecture 
This RISC-V core is fully compliant with the RISC-V specifications, supporting the RV32I base with the M extension, therefore running the **RV32IM** ISA. The discrete mul/div module is the highlight of the device - the architecture is fully implemented, making this core completely unreliant on compiler implementation.
However, it does not support running an Operating System, only compiled i.e. "bare metal" programs can be tested at this point.
The datapath is of the typical five stage pipeline type; the core was tested successully both pre and post synthesis, and synthetized both targeting ASIC and FPGA implementations.
