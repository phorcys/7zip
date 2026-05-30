// 7zCrcOpt.S -- CRC32 calculation : LoongArch64 hardware CRC version
// Public domain

	.text
	.align	4
	.globl	CrcUpdateLoongArch64
	.type	CrcUpdateLoongArch64, @function

// UInt32 Z7_FASTCALL CrcUpdateT12(UInt32 v, const void *data,
//     size_t size, const UInt32 *table);
// LoongArch CRC.W.{B/H/W/D}.W uses rj as the message and rk as the old CRC.
CrcUpdateLoongArch64:
	beqz	$a2, .Ldone

	andi	$t0, $a1, 7
	beqz	$t0, .Laligned

.Lalign_loop:
	ld.bu	$t1, $a1, 0
	addi.d	$a1, $a1, 1
	addi.d	$a2, $a2, -1
	crc.w.b.w $a0, $t1, $a0
	beqz	$a2, .Ldone
	andi	$t0, $a1, 7
	bnez	$t0, .Lalign_loop

.Laligned:
	srli.d	$t0, $a2, 3
	beqz	$t0, .Ltail4

.Lloop8:
	ld.d	$t1, $a1, 0
	addi.d	$a1, $a1, 8
	addi.d	$t0, $t0, -1
	crc.w.d.w $a0, $t1, $a0
	bnez	$t0, .Lloop8

.Ltail4:
	andi	$a2, $a2, 7
	li.d	$t0, 4
	bltu	$a2, $t0, .Ltail2
	ld.wu	$t1, $a1, 0
	addi.d	$a1, $a1, 4
	addi.d	$a2, $a2, -4
	crc.w.w.w $a0, $t1, $a0

.Ltail2:
	li.d	$t0, 2
	bltu	$a2, $t0, .Ltail1
	ld.hu	$t1, $a1, 0
	addi.d	$a1, $a1, 2
	addi.d	$a2, $a2, -2
	crc.w.h.w $a0, $t1, $a0

.Ltail1:
	beqz	$a2, .Ldone
	ld.bu	$t1, $a1, 0
	crc.w.b.w $a0, $t1, $a0

.Ldone:
	jr	$ra
	.size	CrcUpdateLoongArch64, .-CrcUpdateLoongArch64

	.section .note.GNU-stack,"",@progbits
