# RISC-V Executables
All of the RISC-V executables have been generated using the `riscv_none_embed_gcc` toolchain, downloadable online.
In particular, the command used was `riscv-none-embed-gcc -Wall -nostdlib -march=rv32i -mabi=ilp32 riscv_ex.s -o riscv_ex` and then, to convert it into a 
readable hex file, we typed `./bin2hex riscv_ex > riscv_ex.in`.
