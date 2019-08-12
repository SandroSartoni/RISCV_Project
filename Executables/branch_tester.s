.text
.align 2

.global _start

_start:
	addi x1,x0,45
	sw x1,0(x0)
loop:
	nop
	lw x2,0(x0)	#FDEMW
	bne x1,x2,loop	#FssDEMW

_exit:
	j _exit
