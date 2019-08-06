.text
.align 2

.global _start

_start:
	addi x1,x0,45
	addi x2,x0,37
	sub x3,x1,x2
	xori x4,x0,3
	sll x5,x1,x4
	srl x6,x1,x4

_exit:
	j _exit
