.text
.align 2

.global _start

_start:

# ITYPE Instructions

	addi	x1,x0,0x0E	#FDEMW
	andi	x2,x1,0x02	# FDEMW (forwarding one cycle)
	ori	x3,x0,0x03	#  FDEMW
	xori	x4,x0,0x04	#   FDEMW
	slli	x5,x3,0x05	#    FDEMW (forwarding two cycles)
	addi	x1,x0,0
	sub	x1,x1,x2
	srai	x6,x1,0x01		
	srli	x7,x1,0x01
	slti	x8,x1,8
	sltiu	x9,x1,9

# RTYPE Instructions

	add	x10,x5,x2
	sub	x11,x5,x2
	and	x12,x4,x1
	or	x13,x4,x2
	xor	x14,x4,x3
	sll	x15,x3,x4
	sra	x16,x1,x2
	srl	x17,x1,x2
	slt	x18,x1,x2
	sltu	x19,x1,x2
	sb	x1,0(x0)
	sh	x1,4(x0)
	sw	x1,8(x0)
	lb	x20,8(x0)
	lh	x21,8(x0)
	lw	x22,8(x0)
	lbu	x23,8(x0)
	lhu	x24,8(x0)

_exit:
	j _exit
