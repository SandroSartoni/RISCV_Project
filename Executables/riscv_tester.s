.text
.align 2

.global _start

_start:
	addi x1,x0,45
	addi x2,x0,37
	sw x1,0(x0)
	addi x3,x0,16
	lw x4,0(x0)
	xor x5,x4,x3

_exit:
	j _exit
