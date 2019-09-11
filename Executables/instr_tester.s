.text
.align 2

.global _start

_start:

# ITYPE Instructions

	addi	x1,x0,0x0E	# 0x0000000E
	andi	x2,x1,0x02	# 0x00000002
	ori	x3,x0,0x03	# 0x00000003
	xori	x4,x0,0x04	# 0x00000004
	slli	x5,x3,0x05	# 0x00000060
	addi	x1,x0,0		# 0x00000000
	sub	x1,x1,x2	# 0xFFFFFFFE
	srai	x6,x1,0x01	# 0xFFFFFFFF
	srli	x7,x1,0x01	# 0x7FFFFFFF
	slti	x8,x1,8		# 0x00000001
	sltiu	x9,x1,9		# 0x00000000

# RTYPE Instructions

	add	x10,x5,x2	# 0x00000062
	sub	x11,x5,x2	# 0x0000005E
	and	x12,x4,x1	# 0x00000004
	or	x13,x4,x2	# 0x00000006
	xor	x14,x4,x3	# 0x00000007
	sll	x15,x3,x4	# 0x00000030
	sra	x16,x1,x2	# 0xFFFFFFFF
	srl	x17,x1,x2	# 0x3FFFFFFF
	slt	x18,x1,x2	# 0x00000001
	sltu	x19,x1,x2	# 0x00000000
	sb	x1,0(x0)	# no effect
	sh	x1,4(x0)	# no effect
	sw	x1,8(x0)	# no effect
	lb	x20,8(x0)	# 0xFFFFFFE
	lh	x21,8(x0)	# 0xFFFFFFE
	lw	x22,8(x0)	# 0xFFFFFFE
	lbu	x23,8(x0)	# 0x00000FE
	lhu	x24,8(x0)	# 0x000FFFE

# LUI/AUIPC Instructions

	lui	x25,0x800	# 0x00800000
	auipc	x26,0x10	# 0x0001007C

# Branch instructions and JALR

	beq	x25,x26,beq_lab #  FsDEMW
bne_instr:
	bne	x25,x26,bne_lab
blt_instr:
	blt	x1,x2,blt_lab
bge_instr:
	bge	x1,x2,bge_lab
bltu_instr:
	bltu	x1,x2,bltu_lab
bgeu_instr:
	bgeu	x1,x2,bgeu_lab

jalr_lab:
	addi x2,x2,10		# 0x0000000C
	jalr x3,x1,0		# 0x0000009C
beq_lab:
	addi x27,x27,27
	j bne_instr
bne_lab:
	addi x28,x28,28		# 0x0000001C
	j blt_instr
blt_lab:
	addi x29,x29,29		# 0x0000001D
	j bge_instr
bge_lab:
	addi x30,x30,30
	j bltu_instr
bltu_lab:
	addi x31,x31,37
	j bgeu_instr
bgeu_lab:
	addi x27,x27,27		# 0x0000001B
	jal x1,jalr_lab		# 0x000000CC

# End of Program

_exit:
	j _exit
