// LzFindOpt.S -- LoongArch64 ASM version of GetMatchesSpecN_2()
// Public domain
//
// This source keeps the current GCC-LoongArch schedule as an explicit
// assembly baseline.  It is enabled only with USE_LOONGARCH64_LZFIND_OPT.
// The MT match finder uses this entry; the single-thread finder uses
// GetMatchesSpec1 in C/LzFind.c.
//
// Generated baseline source: gcc -S -O2 -fomit-frame-pointer C/LzFindOpt.c
// If pair[0]/pair[1] are combined into one ld.d, keep the loaded value out
// of $r16: that register holds delta for the long-match path after .L27.
	.text
	.align	2
	.align	4
	.globl	GetMatchesSpecN_2
	.type	GetMatchesSpecN_2, @function
GetMatchesSpecN_2:
	addi.d	$r3,$r3,-128
	st.d	$r1,$r3,0
	st.d	$r22,$r3,120
	st.d	$r25,$r3,96
	st.d	$r31,$r3,48
	ld.d	$r19,$r3,144
	ldptr.w	$r14,$r3,152
	st.d	$r23,$r3,112
	st.d	$r24,$r3,104
	st.d	$r26,$r3,88
	st.d	$r27,$r3,80
	st.d	$r28,$r3,72
	st.d	$r29,$r3,64
	st.d	$r30,$r3,56
	or	$r22,$r4,$r0
	or	$r31,$r5,$r0
	or	$r25,$r6,$r0
	st.d	$r8,$r3,32
	or	$r17,$r9,$r0
	st.d	$r10,$r3,40
	or	$r18,$r11,$r0
	b	.L26
	.align	5
.L50:
	bltu	$r6,$r13,.L6
	or	$r11,$r6,$r0
	addi.d	$r23,$r22,1
	addi.d	$r30,$r18,4
	slli.d	$r15,$r19,3
	addi.d	$r20,$r17,4
	alsl.d	$r24,$r19,$r7,3
	bgtu	$r11,$r13,.L7
	.align	3
.L51:
	stptr.w	$r0,$r17,0
	or	$r18,$r30,$r0
	or	$r17,$r20,$r0
	or	$r22,$r23,$r0
	stptr.d	$r0,$r24,0
	.align	3
.L8:
	ld.d	$r12,$r3,128
	addi.d	$r31,$r31,1
	addi.d	$r19,$r19,1
	addi.d	$r25,$r25,1
	bgeu	$r17,$r12,.L2
	.align	3
.L26:
	ld.d	$r12,$r3,136
	beq	$r18,$r12,.L2
	ldptr.w	$r13,$r18,0
	beqz	$r13,.L6
	slli.w	$r6,$r31,0
	bltu	$r6,$r14,.L50
	or	$r11,$r14,$r0
	addi.d	$r23,$r22,1
	addi.d	$r30,$r18,4
	slli.d	$r15,$r19,3
	addi.d	$r20,$r17,4
	alsl.d	$r24,$r19,$r7,3
	bleu	$r11,$r13,.L51
	.align	3
.L7:
	ld.d	$r12,$r3,40
	addi.d	$r26,$r15,4
	ld.d	$r5,$r3,32
	add.d	$r26,$r7,$r26
	add.d	$r29,$r25,$r12
	or	$r10,$r25,$r0
	or	$r9,$r25,$r0
	or	$r28,$r20,$r0
	bstrpick.d	$r27,$r11,31,0
	st.d	$r15,$r3,8
	st.d	$r22,$r3,16
	st.d	$r18,$r3,24
	b	.L25
	.align	5
.L53:
	srai.d	$r16,$r1,32
	stptr.w	$r13,$r24,0
	bleu	$r13,$r16,.L6
	addi.w	$r5,$r5,-1
	addi.d	$r24,$r12,4
	or	$r10,$r15,$r0
	beqz	$r5,.L24
	.align	3
.L54:
	sub.w	$r13,$r6,$r16
	bleu	$r11,$r13,.L24
	.align	3
.L25:
	sltu	$r12,$r10,$r9
	bstrpick.d	$r16,$r13,31,0
	masknez	$r15,$r9,$r12
	maskeqz	$r12,$r10,$r12
	or	$r15,$r15,$r12
	sub.d	$r12,$r19,$r16
	add.d	$r4,$r12,$r27
	sltu	$r18,$r19,$r16
	sub.d	$r8,$r0,$r16
	masknez	$r12,$r12,$r18
	ldx.bu	$r22,$r15,$r8
	maskeqz	$r18,$r4,$r18
	ld.bu	$r4,$r15,0
	or	$r12,$r18,$r12
	alsl.d	$r12,$r12,$r7,3
	ld.d	$r1,$r12,0
	beq	$r22,$r4,.L52
	.align	3
.L10:
	sub.w	$r13,$r6,$r13
	bltu	$r22,$r4,.L53
	slli.w	$r16,$r1,0
	stptr.w	$r13,$r26,0
	bleu	$r13,$r16,.L6
	addi.w	$r5,$r5,-1
	or	$r9,$r15,$r0
	or	$r26,$r12,$r0
	bnez	$r5,.L54
	.align	3
.L24:
	stptr.w	$r0,$r24,0
	sub.d	$r20,$r28,$r20
	ld.d	$r12,$r3,128
	stptr.w	$r0,$r26,0
	srai.d	$r20,$r20,2
	stptr.w	$r20,$r17,0
	or	$r17,$r28,$r0
	or	$r18,$r30,$r0
	or	$r22,$r23,$r0
	addi.d	$r31,$r31,1
	addi.d	$r19,$r19,1
	addi.d	$r25,$r25,1
	bltu	$r17,$r12,.L26
	.align	3
.L2:
	ld.d	$r12,$r3,160
	or	$r4,$r17,$r0
	stptr.w	$r31,$r12,0
	b	.L1
	.align	5
.L52:
	addi.d	$r18,$r15,1
	slli.w	$r4,$r1,0
	beq	$r23,$r18,.L55
	ld.bu	$r15,$r15,1
	ldx.bu	$r22,$r18,$r8
	beq	$r22,$r15,.L14
	.align	3
.L15:
	bgeu	$r29,$r18,.L56
	sub.d	$r15,$r18,$r25
	stptr.w	$r15,$r28,0
	addi.w	$r15,$r13,-1
	st.w	$r15,$r28,4
	ldx.bu	$r22,$r18,$r8
	ld.bu	$r4,$r18,0
	addi.d	$r28,$r28,8
	or	$r29,$r18,$r0
	or	$r15,$r18,$r0
	b	.L10
	.align	5
.L16:
	ldx.bu	$r22,$r18,$r8
	ld.bu	$r15,$r18,0
	bne	$r22,$r15,.L15
	.align	3
.L14:
	or	$r15,$r18,$r0
	addi.d	$r18,$r18,1
	bne	$r23,$r18,.L16
	bltu	$r29,$r23,.L27
	ld.bu	$r4,$r15,1
	ldx.bu	$r22,$r23,$r8
	or	$r15,$r23,$r0
	b	.L10
	.align	5
.L55:
	bltu	$r29,$r23,.L27
	ld.bu	$r4,$r15,1
	ldx.bu	$r22,$r23,$r8
	or	$r15,$r23,$r0
	b	.L10
	.align	5
.L56:
	ldx.bu	$r22,$r18,$r8
	ld.bu	$r4,$r18,0
	or	$r15,$r18,$r0
	b	.L10
	.align	5
.L27:
	sub.w	$r6,$r23,$r25
	addi.w	$r9,$r13,-1
	stptr.w	$r6,$r28,0
	st.w	$r9,$r28,4
	srai.d	$r12,$r1,32
	addi.d	$r5,$r28,8
	stptr.w	$r4,$r24,0
	sub.d	$r20,$r5,$r20
	stptr.w	$r12,$r26,0
	srai.d	$r12,$r20,2
	stptr.w	$r12,$r17,0
	ld.d	$r12,$r3,136
	ld.d	$r15,$r3,8
	ld.d	$r22,$r3,16
	ld.d	$r18,$r3,24
	beq	$r12,$r30,.L31
	ldptr.w	$r12,$r18,4
	beq	$r12,$r13,.L57
	or	$r18,$r30,$r0
	or	$r17,$r5,$r0
	or	$r22,$r23,$r0
	b	.L8
	.align	5
.L6:
	or	$r4,$r0,$r0
	.align	3
.L1:
	ld.d	$r22,$r3,120
	ld.d	$r23,$r3,112
	ld.d	$r24,$r3,104
	ld.d	$r25,$r3,96
	ld.d	$r26,$r3,88
	ld.d	$r27,$r3,80
	ld.d	$r28,$r3,72
	ld.d	$r29,$r3,64
	ld.d	$r30,$r3,56
	ld.d	$r31,$r3,48
	ld.d	$r1,$r3,0
	addi.d	$r3,$r3,128
	jr	$r1
	.align	3
.L57:
	ld.bu	$r12,$r22,1
	ldx.bu	$r20,$r23,$r8
	or	$r18,$r30,$r0
	or	$r17,$r5,$r0
	or	$r22,$r23,$r0
	bne	$r20,$r12,.L8
	ld.d	$r12,$r3,128
	bgtu	$r12,$r5,.L18
	addi.d	$r31,$r31,1
	b	.L2
	.align	5
.L31:
	ld.d	$r18,$r3,136
	or	$r17,$r5,$r0
	or	$r22,$r23,$r0
	b	.L8
	.align	3
.L18:
	bstrpick.d	$r5,$r11,31,0
	addi.d	$r12,$r7,8
	sub.d	$r5,$r5,$r16
	add.d	$r12,$r12,$r15
	or	$r6,$r31,$r0
	addi.w	$r4,$r0,2			# 0x2
	b	.L21
	.align	3
.L58:
	or	$r6,$r31,$r0
	.align	3
.L21:
	addi.d	$r19,$r19,1
	stptr.w	$r4,$r17,0
	sub.d	$r15,$r22,$r25
	sltu	$r20,$r19,$r16
	st.w	$r15,$r17,4
	maskeqz	$r15,$r5,$r20
	masknez	$r20,$r8,$r20
	or	$r15,$r15,$r20
	alsl.d	$r15,$r15,$r12,3
	st.w	$r9,$r17,8
	ldptr.w	$r20,$r15,0
	ldptr.w	$r15,$r15,4
	addi.d	$r12,$r12,8
	addi.d	$r18,$r18,4
	st.w	$r20,$r12,-8
	st.w	$r15,$r12,-4
	ld.d	$r15,$r3,136
	addi.d	$r17,$r17,12
	addi.d	$r22,$r22,1
	addi.d	$r31,$r31,1
	addi.d	$r25,$r25,1
	beq	$r15,$r18,.L8
	ldptr.w	$r15,$r18,0
	bne	$r15,$r13,.L8
	ldx.bu	$r20,$r22,$r8
	ld.bu	$r15,$r22,0
	bne	$r20,$r15,.L8
	ld.d	$r15,$r3,128
	bgtu	$r15,$r17,.L58
	addi.d	$r31,$r6,2
	b	.L2
	.size	GetMatchesSpecN_2, .-GetMatchesSpecN_2
	.section .note.GNU-stack,"",@progbits
