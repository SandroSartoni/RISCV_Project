.text
.align 2

.global _start

_start:
	lui x1,0x80000	# FDEMW
	addi x1,x1,0x0A #  FDEMW
	lui x2,0x80000	#   FDEMW
	addi x2,x2,0x0A #    FDEMW
	mul x3,x1,x2	#     FDmmmmMW
	mulh x4,x1,x2	#      FDsssmmmmMW
	mulhsu x5,x1,x2 #       FsssssssDmmmmMW
	mulhu x6,x1,x2	#                FDEMW

	addi x1,x0,0x04		# x1=4
	lui x2,0xFFFFF
	addi x2,x2,2046
	addi x2,x2,2047		# x2=-3
	div x7,x1,x2		# x7=-1
	divu x8,x1,x2
	rem x9,x1,x2
	remu x10,x1,x2
	

_exit:
	j _exit
