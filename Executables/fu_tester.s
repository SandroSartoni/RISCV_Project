.text
.align 2

.global _start

_start:
	addi x1,x0,45
	addi x2,x0,37
	#sw x0(16),x2
	beq x1,x2,label
	j _exit
label:
	addi x3,x0,30
	
_exit:
	j _exit
