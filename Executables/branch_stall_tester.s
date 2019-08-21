.text
.align 2

.global _start

_start:
	addi x1,x0,0x0A
	sw x1,0(x0)
	lw x2,0(x0) 	# FDEMW		# First stall: one cycle because of load instruction (next instruction should not be a branch one)
	addi x3,x2,0x0A #  FDsEMW
	#addi x5,x3,1 	#   FsDEMW	## Commenta questa istruzione e metti x3 sotto se vuoi il vero problema da risolvere
	beq x3,x1,_exit #     FsDEMW	# Second stall: one cycle because the branch instruction needs the operands in the Decode Stage
	sw x3,4(x0)

wrong_loop:
	lw x4,4(x0)	#	FDEMW	# Last stall: two cycles when having load-branch instruction
	beq x4,x2,wrong_loop #   FssDEMW

correct_loop:
	addi x1,x1,0x01		# Showing BPU capabilities
	bne x1,x3,correct_loop

_exit:
	j _exit
