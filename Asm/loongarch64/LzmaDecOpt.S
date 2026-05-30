// LzmaDecOpt.S -- LoongArch64/LA664 ASM opt path for LzmaDec_DecodeReal_3()
// Public domain
//
// This file is a clean hand-written opt path.  It is selected by
// USE_LOONGARCH64_LZMA_OPT, which is enabled by the LoongArch64 make config.

	.text
	.align	4

#ifdef Z7_LOONGARCH64_LZMA_OPT_REAL
#define LZMADEC_SYMBOL LzmaDec_DecodeReal_3
#else
#define LZMADEC_SYMBOL LzmaDec_DecodeReal_3_la664_draft
#endif

#define PSHIFT  1

	.equ PMULT,        (1 << PSHIFT)
	.equ PMULT_2,      (2 << PSHIFT)
	.equ LZMA_LIT_SIZE, 0x300

	.equ kTopValue,              (1 << 24)
	.equ kNumBitModelTotalBits,  11
	.equ kBitModelTotal,         (1 << kNumBitModelTotalBits)
	.equ kNumMoveBits,           5
	.equ kMatchSpecLen_Error_Data, (1 << 9)

	.equ kNumPosBitsMax,       4
	.equ kNumPosStatesMax,     (1 << kNumPosBitsMax)
	.equ kLenNumLowBits,       3
	.equ kLenNumLowSymbols,    (1 << kLenNumLowBits)
	.equ kLenNumHighBits,      8
	.equ kLenNumHighSymbols,   (1 << kLenNumHighBits)
	.equ kNumLenProbs,         (2 * kLenNumLowSymbols * kNumPosStatesMax + kLenNumHighSymbols)

	.equ LenLow,               0
	.equ LenChoice,            LenLow
	.equ LenChoice2,           (LenLow + kLenNumLowSymbols)
	.equ LenHigh,              (LenLow + 2 * kLenNumLowSymbols * kNumPosStatesMax)

	.equ kNumStates,           12
	.equ kNumStates2,          16
	.equ kNumLitStates,        7
	.equ kStateNonRepFlag,     16
	.equ kStartPosModelIndex,  4
	.equ kEndPosModelIndex,    14
	.equ kNumFullDistances,    (1 << (kEndPosModelIndex >> 1))
	.equ kNumPosSlotBits,      6
	.equ kNumLenToPosStates,   4
	.equ kNumAlignBits,        4
	.equ kAlignTableSize,      (1 << kNumAlignBits)
	.equ kMatchMinLen,         2
	.equ kMatchSpecLenStart,   (kMatchMinLen + kLenNumLowSymbols * 2 + kLenNumHighSymbols)

	// We use p->probs_1664 like x64 and C/LzmaDec.c.
	.equ kStartOffset, 1664
	.equ SpecPos,     (-kStartOffset)
	.equ IsRep0Long,  (SpecPos + kNumFullDistances)
	.equ RepLenCoder, (IsRep0Long + (kNumStates2 << kNumPosBitsMax))
	.equ LenCoder,    (RepLenCoder + kNumLenProbs)
	.equ IsMatch,     (LenCoder + kNumLenProbs)
	.equ kAlign,      (IsMatch + (kNumStates2 << kNumPosBitsMax))
	.equ IsRep,       (kAlign + kAlignTableSize)
	.equ IsRepG0,     (IsRep + kNumStates)
	.equ IsRepG1,     (IsRepG0 + kNumStates)
	.equ IsRepG2,     (IsRepG1 + kNumStates)
	.equ PosSlot,     (IsRepG2 + kNumStates)
	.equ Literal,     (PosSlot + (kNumLenToPosStates << kNumPosSlotBits))
	.equ NUM_BASE_PROBS, (Literal + kStartOffset)

	.if kAlign != 0
	.error "Stop_Compiling_Bad_LZMA_kAlign"
	.endif
	.if NUM_BASE_PROBS != 1984
	.error "Stop_Compiling_Bad_LZMA_PROBS"
	.endif

	.equ offset_lc,            0
	.equ offset_lp,            1
	.equ offset_pb,            2
	.equ offset_dicSize,       4
	.equ offset_probs,         4 + offset_dicSize
	.equ offset_probs_1664,    8 + offset_probs
	.equ offset_dic,           8 + offset_probs_1664
	.equ offset_dicBufSize,    8 + offset_dic
	.equ offset_dicPos,        8 + offset_dicBufSize
	.equ offset_buf,           8 + offset_dicPos
	.equ offset_range,         8 + offset_buf
	.equ offset_code,          4 + offset_range
	.equ offset_processedPos,  4 + offset_code
	.equ offset_checkDicSize,  4 + offset_processedPos
	.equ offset_rep0,          4 + offset_checkDicSize
	.equ offset_rep1,          4 + offset_rep0
	.equ offset_rep2,          4 + offset_rep1
	.equ offset_rep3,          4 + offset_rep2
	.equ offset_state,         4 + offset_rep3
	.equ offset_remainLen,     4 + offset_state
	.equ offset_TOTAL_SIZE,    4 + offset_remainLen

	.if offset_TOTAL_SIZE != 96
	.error "Incorrect offset_TOTAL_SIZE"
	.endif

// ---------- ABI / Register Aliases ----------

#define PARAM_lzma       $r4
#define PARAM_limit      $r5
#define PARAM_bufLimit   $r6

#define zero             $r0
#define ra               $r1
#define sp               $r3
#define probs_IsMatch    $r1

#define lzma             $r4
#define limit            $r5
#define bufLimit         $r6
#define dic              $r7
#define dicBufSize       $r8
#define dicPos           $r9
#define buf              $r10
#define probs_Spec       $r11

#define range            $r12
#define cod              $r13
#define processedPos     $r14
#define checkDicSize     $r15
#define state            $r16
#define rep0             $r17
#define rep1             $r18
#define rep2             $r19
#define litProps         $r20

#define pbMaskReg        $r4

#define probs            $r25
#define probBranch       $r26
#define probPtr          $r27
#define bound            $r28
#define update           $r29
#define sym              $r30
#define len              $r31

#define pbPos            bound
#define normTmp          update

#define t0               $r22
#define t1               $r23
#define t2               $r24
#define t3               update

#define MY_ALIGN_FOR_ENTRY   .align 5
#define MY_ALIGN_FOR_LOOP    .align 6
#define MY_ALIGN_FOR_LOOP_16 .align 4

// ---------- Probability Loads / Stores ----------

	.macro PLOAD dest:req, mem:req
	ld.hu	\dest,\mem,0
	.endm

	.macro PSTORE src:req, mem:req
	st.h	\src,\mem,0
	.endm

	.macro PLOAD_2 dest:req, mem1:req, mem2:req
	.if \mem2 == 0
	ld.hu	\dest,\mem1,0
	.else
	ld.hu	\dest,\mem1,\mem2
	.endif
	.endm

	.macro PSTORE_2 src:req, mem1:req, mem2:req
	.if \mem2 == 0
	st.h	\src,\mem1,0
	.else
	st.h	\src,\mem1,\mem2
	.endif
	.endm

	.macro PLOAD_LSL dest:req, mem1:req, mem2:req
	alsl.d	\dest,\mem2,\mem1,PSHIFT
	ld.hu	\dest,\dest,0
	.endm

	.macro PSTORE_LSL src:req, mem1:req, mem2:req
	alsl.d	t2,\mem2,\mem1,PSHIFT
	st.h	\src,t2,0
	.endm

	.macro PSTORE_LSL_M1 src:req, mem1:req, mem2:req, temp_reg:req
	alsl.d	\temp_reg,\mem2,\mem1,PSHIFT
	st.h	\src,\temp_reg,0
	.endm

// ---------- Normalize ----------

	.macro NORM_2
	ld.bu	normTmp,buf,0
	slli.w	range,range,8
	slli.w	cod,cod,8
	or	cod,cod,normTmp
	addi.d	buf,buf,1
	.endm

	.macro TEST_HIGH_BYTE_range toLabel:req
	li.d	normTmp,kTopValue
	bgeu	range,normTmp,\toLabel
	.endm

	.macro NORM
	li.d	normTmp,kTopValue
	bgeu	range,normTmp,.Lnorm_done_\@
	NORM_2
.Lnorm_done_\@:
	.endm

	.macro NORM_WITH topReg:req
	bgeu	range,\topReg,.Lnorm_done_\@
	NORM_2
.Lnorm_done_\@:
	.endm

// ---------- Branch MACROS ----------

	.macro UPDATE_0__0
	sub.w	update,zero,probBranch
	.endm

	.macro UPDATE_0__1
	bstrpick.w	update,update,(kNumBitModelTotalBits - 1),kNumMoveBits
	add.w	update,update,probBranch
	.endm

	.macro UPDATE_0__2 probAddr:req
	PSTORE	update,\probAddr
	.endm

	.macro UPDATE_0 probAddr:req
	UPDATE_0__0
	UPDATE_0__1
	UPDATE_0__2 \probAddr
	or	range,bound,zero
	.endm

	.macro UPDATE_1 probAddr:req
	sub.w	cod,cod,bound
	sub.w	range,range,bound
	srli.w	update,probBranch,kNumMoveBits
	sub.w	update,probBranch,update
	PSTORE	update,\probAddr
	.endm

	.macro CMP_COD_BASE
	NORM
	srli.w	bound,range,kNumBitModelTotalBits
	mul.w	bound,bound,probBranch
	.endm

	.macro CMP_COD_BASE_WITH topReg:req
	NORM_WITH \topReg
	srli.w	bound,range,kNumBitModelTotalBits
	mul.w	bound,bound,probBranch
	.endm

	.macro CMP_COD_1 probsArray:req
	PLOAD	probBranch,\probsArray
	CMP_COD_BASE
	.endm

	.macro CMP_COD_3 probsArray:req, probOffset:req, probDisp:req
	.if \probDisp == 0
	alsl.d	probPtr,\probOffset,\probsArray,PSHIFT
	.else
	addi.d	probPtr,\probsArray,(\probDisp * PMULT)
	add.d	probPtr,probPtr,\probOffset
	.endif
	PLOAD	probBranch,probPtr
	CMP_COD_BASE
	.endm

	.macro IF_BIT_1_NOUP probsArray:req, probOffset:req, probDisp:req, toLabel:req
	CMP_COD_3 \probsArray,\probOffset,\probDisp
	bgeu	cod,bound,\toLabel
	.endm

	.macro IF_BIT_1 probsArray:req, probOffset:req, probDisp:req, toLabel:req
	IF_BIT_1_NOUP \probsArray,\probOffset,\probDisp,\toLabel
	UPDATE_0 probPtr
	.endm

	.macro IF_BIT_0_NOUP probsArray:req, probOffset:req, probDisp:req, toLabel:req
	CMP_COD_3 \probsArray,\probOffset,\probDisp
	bltu	cod,bound,\toLabel
	.endm

	.macro IF_BIT_0_NOUP_1 probsArray:req, toLabel:req
	CMP_COD_1 \probsArray
	bltu	cod,bound,\toLabel
	.endm

	.macro ADD_PROBS_BASE dest:req, offset:req
	.if ((\offset * PMULT) >= -2048) && ((\offset * PMULT) <= 2047)
	addi.d	\dest,probs_Spec,(\offset * PMULT)
	.elseif ((\offset * PMULT) >= -4096) && ((\offset * PMULT) < -2048)
	addi.d	\dest,probs_Spec,-2048
	addi.d	\dest,\dest,((\offset * PMULT) + 2048)
	.else
	li.d	\dest,(\offset * PMULT)
	add.d	\dest,probs_Spec,\dest
	.endif
	.endm

	.macro SET_PROBS offset:req
	ADD_PROBS_BASE probs,\offset
	.endm

	.macro SET_PROB_PTR offset:req, index:req
	ADD_PROBS_BASE probPtr,\offset
	alsl.d	probPtr,\index,probPtr,PSHIFT
	.endm

	.macro IF_BIT_0_PTR toLabel:req
	PLOAD	probBranch,probPtr
	CMP_COD_BASE
	bltu	cod,bound,.Lbit0_\@
	UPDATE_1 probPtr
	b	.Lbit_done_\@
.Lbit0_\@:
	UPDATE_0 probPtr
	b	\toLabel
.Lbit_done_\@:
	.endm

	.macro IF_BIT_1_PTR toLabel:req
	PLOAD	probBranch,probPtr
	CMP_COD_BASE
	bgeu	cod,bound,.Lbit1_\@
	UPDATE_0 probPtr
	b	.Lbit_done_\@
.Lbit1_\@:
	UPDATE_1 probPtr
	b	\toLabel
.Lbit_done_\@:
	.endm

	.macro IF_BIT_1_PTR_FALLTHROUGH toLabel:req
	PLOAD	probBranch,probPtr
	CMP_COD_BASE
	bgeu	cod,bound,\toLabel
	UPDATE_0 probPtr
	.endm

// ---------- CMOV-Free Decode Primitives ----------

	.macro TREE_BIT probBase:req
	alsl.d	probPtr,sym,\probBase,PSHIFT
	PLOAD	probBranch,probPtr
	CMP_COD_BASE
	bgeu	cod,bound,.Ltree_bit1_\@
	UPDATE_0 probPtr
	slli.w	sym,sym,1
	b	.Ltree_done_\@
.Ltree_bit1_\@:
	UPDATE_1 probPtr
	slli.w	sym,sym,1
	ori	sym,sym,1
.Ltree_done_\@:
	.endm

	.macro TREE_BIT_BL topReg:req
	alsl.d	probPtr,sym,probs,PSHIFT
	PLOAD	probBranch,probPtr
	CMP_COD_BASE_WITH \topReg
	sltu	t0,cod,bound
	sub.w	t1,cod,bound
	sub.w	t2,range,bound
	maskeqz	cod,cod,t0
	masknez	t1,t1,t0
	or	cod,cod,t1
	maskeqz	range,bound,t0
	masknez	t2,t2,t0
	or	range,range,t2
	xori	t2,t0,1
	alsl.w	sym,sym,t2,1
	srli.w	update,probBranch,kNumMoveBits
	sub.w	update,probBranch,update
	andi	t1,probBranch,((1 << kNumMoveBits) - 1)
	sltui	t1,t1,1
	addi.w	t1,t1,((kBitModelTotal >> kNumMoveBits) - 1)
	maskeqz	t1,t1,t0
	add.w	update,update,t1
	PSTORE	update,probPtr
	.endm

	.macro BIT_01
	.endm

	.macro BIT_0_R prob:req
	TREE_BIT probs
	.endm

	.macro BIT_1_R prob:req
	TREE_BIT probs
	.endm

	.macro BIT_2_R prob:req
	TREE_BIT probs
	.endm

#define BIT_0 BIT_0_R probBranch
#define BIT_1 BIT_1_R probBranch
#define BIT_2 BIT_2_R probBranch

	.macro LIT_TREE_BIT0 next_label:req, bit1_label:req
	alsl.d	probPtr,sym,probs,PSHIFT
	PLOAD	probBranch,probPtr
	CMP_COD_BASE
	bgeu	cod,bound,\bit1_label
	UPDATE_0 probPtr
	slli.w	sym,sym,1
\next_label:
	.endm

	.macro LIT_TREE_BIT1 next_label:req
	UPDATE_1 probPtr
	slli.w	sym,sym,1
	ori	sym,sym,1
	b	\next_label
	.endm

	.macro LIT_TREE_BIT_BL next_label:req
	alsl.d	probPtr,sym,probs,PSHIFT
	PLOAD	probBranch,probPtr
	CMP_COD_BASE_WITH len
	sltu	t0,cod,bound
	sub.w	t1,cod,bound
	sub.w	t2,range,bound
	maskeqz	cod,cod,t0
	masknez	t1,t1,t0
	or	cod,cod,t1
	maskeqz	range,bound,t0
	masknez	t2,t2,t0
	or	range,range,t2
	xori	t2,t0,1
	alsl.w	sym,sym,t2,1
	srli.w	update,probBranch,kNumMoveBits
	sub.w	update,probBranch,update
	andi	t1,probBranch,((1 << kNumMoveBits) - 1)
	sltui	t1,t1,1
	addi.w	t1,t1,((kBitModelTotal >> kNumMoveBits) - 1)
	maskeqz	t1,t1,t0
	add.w	update,update,t1
	PSTORE	update,probPtr
\next_label:
	.endm

	.macro TREE_BIT_PRELOAD_BL topReg:req
	CMP_COD_BASE_WITH \topReg
	sltu	t0,cod,bound
	srli.w	update,probBranch,kNumMoveBits
	sub.w	update,probBranch,update
	andi	t1,probBranch,((1 << kNumMoveBits) - 1)
	sltui	t1,t1,1
	addi.w	t1,t1,((kBitModelTotal >> kNumMoveBits) - 1)
	maskeqz	t1,t1,t0
	add.w	update,update,t1
	PSTORE	update,probPtr
	slli.w	sym,sym,1
	alsl.d	probPtr,sym,probs,PSHIFT
	ld.hu	probBranch,probPtr,0
	ld.hu	update,probPtr,PMULT
	sub.w	t1,cod,bound
	sub.w	t2,range,bound
	maskeqz	cod,cod,t0
	masknez	t1,t1,t0
	or	cod,cod,t1
	maskeqz	range,bound,t0
	masknez	t2,t2,t0
	or	range,range,t2
	xori	t2,t0,1
	add.w	sym,sym,t2
	alsl.d	probPtr,t2,probPtr,PSHIFT
	maskeqz	probBranch,probBranch,t0
	masknez	update,update,t0
	or	probBranch,probBranch,update
	.endm

	.macro TREE_BIT_PRELOAD_LAST_BL topReg:req
	CMP_COD_BASE_WITH \topReg
	sltu	t0,cod,bound
	sub.w	t1,cod,bound
	sub.w	t2,range,bound
	maskeqz	cod,cod,t0
	masknez	t1,t1,t0
	or	cod,cod,t1
	maskeqz	range,bound,t0
	masknez	t2,t2,t0
	or	range,range,t2
	xori	t2,t0,1
	alsl.w	sym,sym,t2,1
	srli.w	update,probBranch,kNumMoveBits
	sub.w	update,probBranch,update
	andi	t1,probBranch,((1 << kNumMoveBits) - 1)
	sltui	t1,t1,1
	addi.w	t1,t1,((kBitModelTotal >> kNumMoveBits) - 1)
	maskeqz	t1,t1,t0
	add.w	update,update,t1
	PSTORE	update,probPtr
	.endm

// ---------- MATCHED LITERAL ----------

#define matchByte  t0
#define offs       t1
#define bit        t2
#define litmTmp    update

	.macro LITM_STEP
	slli.w	matchByte,matchByte,1
	and	bit,offs,matchByte
	add.w	litmTmp,bit,offs
	add.w	litmTmp,litmTmp,sym
	alsl.d	probPtr,litmTmp,probs,PSHIFT
	PLOAD	probBranch,probPtr
	CMP_COD_BASE
	bgeu	cod,bound,.Llitm_bit1_\@
	UPDATE_0 probPtr
	slli.w	sym,sym,1
	xor	offs,offs,bit
	b	.Llitm_done_\@
.Llitm_bit1_\@:
	or	offs,bit,zero
	UPDATE_1 probPtr
	slli.w	sym,sym,1
	ori	sym,sym,1
.Llitm_done_\@:
	.endm

	.macro LITM_TREE_BIT0 next_label:req, bit1_label:req
	slli.w	matchByte,matchByte,1
	and	bit,offs,matchByte
	add.w	litmTmp,bit,offs
	add.w	litmTmp,litmTmp,sym
	alsl.d	probPtr,litmTmp,probs,PSHIFT
	PLOAD	probBranch,probPtr
	CMP_COD_BASE_WITH len
	bgeu	cod,bound,\bit1_label
	xor	offs,offs,bit
	slli.w	sym,sym,1
	UPDATE_0 probPtr
\next_label:
	.endm

	.macro LITM_TREE_BIT1 next_label:req
	or	offs,bit,zero
	UPDATE_1 probPtr
	slli.w	sym,sym,1
	ori	sym,sym,1
	b	\next_label
	.endm

	.macro LITM_TREE_BIT_BL
	slli.w	matchByte,matchByte,1
	and	bit,offs,matchByte
	add.w	litmTmp,bit,offs
	add.w	litmTmp,litmTmp,sym
	alsl.d	probPtr,litmTmp,probs,PSHIFT
	PLOAD	probBranch,probPtr
	CMP_COD_BASE_WITH len
	sltu	litmTmp,cod,bound
	maskeqz	offs,offs,litmTmp
	xor	offs,offs,bit
	xori	bit,litmTmp,1
	alsl.w	sym,sym,bit,1
	masknez	bit,bound,litmTmp
	sub.w	cod,cod,bit
	sub.w	bit,range,bound
	maskeqz	range,bound,litmTmp
	masknez	bit,bit,litmTmp
	or	range,range,bit
	srli.w	bit,probBranch,kNumMoveBits
	sub.w	bit,probBranch,bit
	andi	bound,probBranch,((1 << kNumMoveBits) - 1)
	sltui	bound,bound,1
	addi.w	bound,bound,((kBitModelTotal >> kNumMoveBits) - 1)
	maskeqz	bound,bound,litmTmp
	add.w	bit,bit,bound
	PSTORE	bit,probPtr
	.endm

	.macro LITM_PRELOAD
	slli.w	matchByte,matchByte,1
	and	bit,offs,matchByte
	add.w	litmTmp,bit,offs
	add.w	litmTmp,litmTmp,sym
	alsl.d	probPtr,litmTmp,probs,PSHIFT
	PLOAD	probBranch,probPtr
	.endm

	.macro LITM_TREE_BIT_PRELOAD_BL
	CMP_COD_BASE_WITH len
	sltu	litmTmp,cod,bound
	maskeqz	offs,offs,litmTmp
	xor	offs,offs,bit
	xori	bit,litmTmp,1
	alsl.w	sym,sym,bit,1
	masknez	bit,bound,litmTmp
	sub.w	cod,cod,bit
	sub.w	bit,range,bound
	maskeqz	range,bound,litmTmp
	masknez	bit,bit,litmTmp
	or	range,range,bit
	srli.w	bit,probBranch,kNumMoveBits
	sub.w	bit,probBranch,bit
	andi	bound,probBranch,((1 << kNumMoveBits) - 1)
	sltui	bound,bound,1
	addi.w	bound,bound,((kBitModelTotal >> kNumMoveBits) - 1)
	maskeqz	bound,bound,litmTmp
	add.w	bit,bit,bound
	PSTORE	bit,probPtr
	LITM_PRELOAD
	.endm

	.macro LITM_TREE_BIT_PRELOAD_LAST_BL
	CMP_COD_BASE_WITH len
	sltu	litmTmp,cod,bound
	xori	bit,litmTmp,1
	alsl.w	sym,sym,bit,1
	masknez	bit,bound,litmTmp
	sub.w	cod,cod,bit
	sub.w	bit,range,bound
	maskeqz	range,bound,litmTmp
	masknez	bit,bit,litmTmp
	or	range,range,bit
	srli.w	bit,probBranch,kNumMoveBits
	sub.w	bit,probBranch,bit
	andi	bound,probBranch,((1 << kNumMoveBits) - 1)
	sltui	bound,bound,1
	addi.w	bound,bound,((kBitModelTotal >> kNumMoveBits) - 1)
	maskeqz	bound,bound,litmTmp
	add.w	bit,bit,bound
	PSTORE	bit,probPtr
	.endm

	.macro LITM_0
	LITM_STEP
	.endm

	.macro LITM
	LITM_STEP
	.endm

	.macro LITM_2
	LITM_STEP
	.endm

// ---------- REVERSE BITS ----------

#define rev_i  sym
#define rev_m  t1

	.macro REV_BIT_VAR probBase:req
	alsl.d	probPtr,rev_i,\probBase,PSHIFT
	PLOAD	probBranch,probPtr
	CMP_COD_BASE
	sltu	t2,cod,bound
	sub.w	update,range,bound
	maskeqz	range,bound,t2
	masknez	update,update,t2
	or	range,range,update
	masknez	update,bound,t2
	sub.w	cod,cod,update
	srli.w	update,probBranch,kNumMoveBits
	sub.w	update,probBranch,update
	andi	bound,probBranch,((1 << kNumMoveBits) - 1)
	sltui	bound,bound,1
	addi.w	bound,bound,((kBitModelTotal >> kNumMoveBits) - 1)
	maskeqz	bound,bound,t2
	add.w	update,update,bound
	PSTORE	update,probPtr
	add.w	rev_i,rev_i,rev_m
	masknez	update,rev_m,t2
	slli.w	rev_m,rev_m,1
	add.w	rev_i,rev_i,update
	.endm

// ---------- LITERAL PROBS ----------

	.macro LIT_PROBS
	SET_PROBS Literal
	srli.d	t2,litProps,32
	slli.w	t1,processedPos,8
	add.w	t1,t1,sym
	and	t1,t1,litProps
	sll.w	t1,t1,t2
	alsl.wu	t1,t1,t1,1
	alsl.d	probs,t1,probs,PSHIFT
	addi.w	processedPos,processedPos,1
	.endm

// ---------- State / Limit Helpers ----------

	.macro IsMatchBranch_Pre
	and	t1,processedPos,pbMaskReg
	slli.w	t1,t1,4
	add.w	pbPos,t1,state
	alsl.d	probPtr,pbPos,probs_IsMatch,PSHIFT
	PLOAD	probBranch,probPtr
	.endm

	.macro CheckLimits toLabel:req
	bgeu	buf,bufLimit,\toLabel
	bgeu	dicPos,limit,\toLabel
	.endm

// ---------- Decode Helpers ----------

	.macro TREE_3_TO_SYM
	addi.w	sym,zero,1
	TREE_BIT probs
	TREE_BIT probs
	TREE_BIT probs
	.endm

	.macro TREE_3_TO_SYM_SPLIT
	addi.w	sym,zero,1
	alsl.d	probPtr,sym,probs,PSHIFT
	PLOAD	probBranch,probPtr
	CMP_COD_BASE
	bgeu	cod,bound,.Ltree3_bit1_0_\@
	UPDATE_0 probPtr
	slli.w	sym,sym,1
.Ltree3_1_\@:
	alsl.d	probPtr,sym,probs,PSHIFT
	PLOAD	probBranch,probPtr
	CMP_COD_BASE
	bgeu	cod,bound,.Ltree3_bit1_1_\@
	UPDATE_0 probPtr
	slli.w	sym,sym,1
.Ltree3_2_\@:
	alsl.d	probPtr,sym,probs,PSHIFT
	PLOAD	probBranch,probPtr
	CMP_COD_BASE
	bgeu	cod,bound,.Ltree3_bit1_2_\@
	UPDATE_0 probPtr
	slli.w	sym,sym,1
	b	.Ltree3_done_\@
.Ltree3_bit1_0_\@:
	UPDATE_1 probPtr
	slli.w	sym,sym,1
	ori	sym,sym,1
	b	.Ltree3_1_\@
.Ltree3_bit1_1_\@:
	UPDATE_1 probPtr
	slli.w	sym,sym,1
	ori	sym,sym,1
	b	.Ltree3_2_\@
.Ltree3_bit1_2_\@:
	UPDATE_1 probPtr
	slli.w	sym,sym,1
	ori	sym,sym,1
.Ltree3_done_\@:
	.endm

	.macro TREE_3_TO_SYM_BL topReg:req
	addi.w	sym,zero,1
	TREE_BIT_BL \topReg
	TREE_BIT_BL \topReg
	TREE_BIT_BL \topReg
	.endm

	.macro TREE_3_TO_SYM_PRELOAD_BL topReg:req
	addi.w	sym,zero,1
	alsl.d	probPtr,sym,probs,PSHIFT
	PLOAD	probBranch,probPtr
	TREE_BIT_PRELOAD_BL \topReg
	TREE_BIT_PRELOAD_BL \topReg
	TREE_BIT_PRELOAD_LAST_BL \topReg
	.endm

	.macro TREE_6_TO_SYM
	addi.w	sym,zero,1
	TREE_BIT probs
	TREE_BIT probs
	TREE_BIT probs
	TREE_BIT probs
	TREE_BIT probs
	TREE_BIT probs
	addi.w	sym,sym,-64
	.endm

	.macro TREE_6_TO_SYM_PRELOAD_BL topReg:req
	addi.w	sym,zero,1
	alsl.d	probPtr,sym,probs,PSHIFT
	PLOAD	probBranch,probPtr
	TREE_BIT_PRELOAD_BL \topReg
	TREE_BIT_PRELOAD_BL \topReg
	TREE_BIT_PRELOAD_BL \topReg
	TREE_BIT_PRELOAD_BL \topReg
	TREE_BIT_PRELOAD_BL \topReg
	TREE_BIT_PRELOAD_LAST_BL \topReg
	addi.w	sym,sym,-64
	.endm

	.macro TREE_6_POS_SLOT_PRELOAD_BL topReg:req, prefixReg:req
	addi.w	sym,zero,1
	alsl.d	probPtr,sym,probs,PSHIFT
	PLOAD	probBranch,probPtr
	TREE_BIT_PRELOAD_BL \topReg
	TREE_BIT_PRELOAD_BL \topReg
	TREE_BIT_PRELOAD_BL \topReg
	TREE_BIT_PRELOAD_BL \topReg
	TREE_BIT_PRELOAD_BL \topReg
	or	\prefixReg,sym,zero
	TREE_BIT_PRELOAD_LAST_BL \topReg
	.endm

	.macro TREE_8_TO_SYM
	addi.w	sym,zero,1
	TREE_BIT probs
	TREE_BIT probs
	TREE_BIT probs
	TREE_BIT probs
	TREE_BIT probs
	TREE_BIT probs
	TREE_BIT probs
	TREE_BIT probs
	addi.w	sym,sym,-256
	.endm

	.macro TREE_8_TO_SYM_BL topReg:req
	addi.w	sym,zero,1
	TREE_BIT_BL \topReg
	TREE_BIT_BL \topReg
	TREE_BIT_BL \topReg
	TREE_BIT_BL \topReg
	TREE_BIT_BL \topReg
	TREE_BIT_BL \topReg
	TREE_BIT_BL \topReg
	TREE_BIT_BL \topReg
	addi.w	sym,sym,-256
	.endm

	.macro TREE_8_TO_SYM_PRELOAD_BL topReg:req
	addi.w	sym,zero,1
	alsl.d	probPtr,sym,probs,PSHIFT
	PLOAD	probBranch,probPtr
	TREE_BIT_PRELOAD_BL \topReg
	TREE_BIT_PRELOAD_BL \topReg
	TREE_BIT_PRELOAD_BL \topReg
	TREE_BIT_PRELOAD_BL \topReg
	TREE_BIT_PRELOAD_BL \topReg
	TREE_BIT_PRELOAD_BL \topReg
	TREE_BIT_PRELOAD_BL \topReg
	TREE_BIT_PRELOAD_LAST_BL \topReg
	addi.w	sym,sym,-256
	.endm

	.macro DIRECT_DISTANCE_BIT
	NORM
	srli.w	range,range,1
	sub.w	probBranch,cod,range
	srai.w	probPtr,probBranch,31
	and	bound,range,probPtr
	add.w	cod,probBranch,bound
	addi.w	probPtr,probPtr,1
	alsl.w	sym,sym,probPtr,1
	.endm

	.macro DIRECT_BIT_OPT done_label:req
	srli.w	range,range,1
	addi.w	t0,t0,-1
	sltu	probPtr,cod,range
	xori	t1,probPtr,1
	alsl.w	sym,sym,t1,1
	masknez	probPtr,range,probPtr
	sub.w	cod,cod,probPtr
	beqz	t0,\done_label
	.endm

	.macro DIRECT_8_OPT done_label:req, after_label:req
	DIRECT_BIT_OPT \done_label
	bltu	range,probs,\after_label
	DIRECT_BIT_OPT \done_label
	bltu	range,probs,\after_label
	DIRECT_BIT_OPT \done_label
	bltu	range,probs,\after_label
	DIRECT_BIT_OPT \done_label
	bltu	range,probs,\after_label
	DIRECT_BIT_OPT \done_label
	bltu	range,probs,\after_label
	DIRECT_BIT_OPT \done_label
	bltu	range,probs,\after_label
	DIRECT_BIT_OPT \done_label
	bltu	range,probs,\after_label
	DIRECT_BIT_OPT \done_label
	b	\after_label
	.endm

	.macro REV_ALIGN_CONST step:req
	alsl.d	probPtr,t2,probs,PSHIFT
	PLOAD	probBranch,probPtr
	CMP_COD_BASE
	bgeu	cod,bound,.Lrev_align1_\@
	UPDATE_0 probPtr
	addi.w	t2,t2,\step
	b	.Lrev_align_done_\@
.Lrev_align1_\@:
	UPDATE_1 probPtr
	addi.w	t2,t2,(\step * 2)
.Lrev_align_done_\@:
	.endm

	.macro REV_ALIGN_CONST_BL step:req, bitShift:req
	alsl.d	probPtr,t2,probs,PSHIFT
	PLOAD	probBranch,probPtr
	CMP_COD_BASE
	sltu	t0,cod,bound
	sub.w	t1,cod,bound
	sub.w	update,range,bound
	maskeqz	cod,cod,t0
	masknez	t1,t1,t0
	or	cod,cod,t1
	maskeqz	range,bound,t0
	masknez	update,update,t0
	or	range,range,update
	addi.w	t1,zero,(\step * 2)
	.if \bitShift != 0
	slli.w	update,t0,\bitShift
	sub.w	t1,t1,update
	.else
	sub.w	t1,t1,t0
	.endif
	add.w	t2,t2,t1
	srli.w	update,probBranch,kNumMoveBits
	sub.w	update,probBranch,update
	andi	t1,probBranch,((1 << kNumMoveBits) - 1)
	sltui	t1,t1,1
	addi.w	t1,t1,((kBitModelTotal >> kNumMoveBits) - 1)
	maskeqz	t1,t1,t0
	add.w	update,update,t1
	PSTORE	update,probPtr
	.endm

	.macro REV_ALIGN_CONST_BL_WITH probBase:req, topReg:req, step:req, bitShift:req
	alsl.d	probPtr,t2,\probBase,PSHIFT
	PLOAD	probBranch,probPtr
	CMP_COD_BASE_WITH \topReg
	sltu	t0,cod,bound
	sub.w	t1,cod,bound
	sub.w	update,range,bound
	maskeqz	cod,cod,t0
	masknez	t1,t1,t0
	or	cod,cod,t1
	maskeqz	range,bound,t0
	masknez	update,update,t0
	or	range,range,update
	addi.w	t1,zero,(\step * 2)
	.if \bitShift != 0
	slli.w	update,t0,\bitShift
	sub.w	t1,t1,update
	.else
	sub.w	t1,t1,t0
	.endif
	add.w	t2,t2,t1
	srli.w	update,probBranch,kNumMoveBits
	sub.w	update,probBranch,update
	andi	t1,probBranch,((1 << kNumMoveBits) - 1)
	sltui	t1,t1,1
	addi.w	t1,t1,((kBitModelTotal >> kNumMoveBits) - 1)
	maskeqz	t1,t1,t0
	add.w	update,update,t1
	PSTORE	update,probPtr
	.endm

	.macro REV_ALIGN_LAST
	alsl.d	probPtr,t2,probs,PSHIFT
	PLOAD	probBranch,probPtr
	CMP_COD_BASE
	bgeu	cod,bound,.Lrev_align_last1_\@
	UPDATE_0 probPtr
	addi.w	t2,t2,-8
	b	.Lrev_align_last_done_\@
.Lrev_align_last1_\@:
	UPDATE_1 probPtr
.Lrev_align_last_done_\@:
	.endm

	.macro REV_ALIGN_LAST_BL
	alsl.d	probPtr,t2,probs,PSHIFT
	PLOAD	probBranch,probPtr
	CMP_COD_BASE
	sltu	t0,cod,bound
	sub.w	t1,cod,bound
	sub.w	update,range,bound
	maskeqz	cod,cod,t0
	masknez	t1,t1,t0
	or	cod,cod,t1
	maskeqz	range,bound,t0
	masknez	update,update,t0
	or	range,range,update
	slli.w	t1,t0,3
	sub.w	t2,t2,t1
	srli.w	update,probBranch,kNumMoveBits
	sub.w	update,probBranch,update
	andi	t1,probBranch,((1 << kNumMoveBits) - 1)
	sltui	t1,t1,1
	addi.w	t1,t1,((kBitModelTotal >> kNumMoveBits) - 1)
	maskeqz	t1,t1,t0
	add.w	update,update,t1
	PSTORE	update,probPtr
	.endm

	.macro REV_ALIGN_LAST_BL_WITH probBase:req, topReg:req
	alsl.d	probPtr,t2,\probBase,PSHIFT
	PLOAD	probBranch,probPtr
	CMP_COD_BASE_WITH \topReg
	sltu	t0,cod,bound
	sub.w	t1,cod,bound
	sub.w	update,range,bound
	maskeqz	cod,cod,t0
	masknez	t1,t1,t0
	or	cod,cod,t1
	maskeqz	range,bound,t0
	masknez	update,update,t0
	or	range,range,update
	slli.w	t1,t0,3
	sub.w	t2,t2,t1
	srli.w	update,probBranch,kNumMoveBits
	sub.w	update,probBranch,update
	andi	t1,probBranch,((1 << kNumMoveBits) - 1)
	sltui	t1,t1,1
	addi.w	t1,t1,((kBitModelTotal >> kNumMoveBits) - 1)
	maskeqz	t1,t1,t0
	add.w	update,update,t1
	PSTORE	update,probPtr
	.endm

	.macro UPDATE_STATE_MATCH
	sltui	t0,state,(kStateNonRepFlag + kNumLitStates)
	addi.w	t1,zero,3
	masknez	t1,t1,t0
	addi.w	state,zero,kNumLitStates
	add.w	state,state,t1
	.endm

	.macro UPDATE_STATE_REP
	sltui	t0,state,kNumLitStates
	addi.w	state,zero,-3
	maskeqz	state,state,t0
	addi.w	state,state,11
	.endm

	.macro UPDATE_STATE_REP0_SHORT
	sltui	t0,state,kNumLitStates
	addi.w	state,zero,-2
	maskeqz	state,state,t0
	addi.w	state,state,11
	.endm

// ---------- CLzmaDec Loads / Stores ----------

	.macro LOAD_LZMA_VAR reg:req, struct_offs:req
	ld.d	\reg,lzma,\struct_offs
	.endm

	.macro LOAD_LZMA_BYTE reg:req, struct_offs:req
	ld.bu	\reg,lzma,\struct_offs
	.endm

	.macro LOAD_LZMA_U32 reg:req, struct_offs:req
	ld.wu	\reg,lzma,\struct_offs
	.endm

	.macro STORE_LZMA_VAR reg:req, struct_offs:req
	st.d	\reg,lzma,\struct_offs
	.endm

	.macro STORE_LZMA_U32 reg:req, struct_offs:req
	st.w	\reg,lzma,\struct_offs
	.endm

// ---------- Draft Prologue / Literal Segment ----------

	.macro DECODE_REAL_PROLOGUE
	addi.d	sp,sp,-144
	st.d	ra,sp,0
	st.d	$r22,sp,8
	st.d	$r23,sp,16
	st.d	$r24,sp,24
	st.d	$r25,sp,32
	st.d	$r26,sp,40
	st.d	$r27,sp,48
	st.d	$r28,sp,56
	st.d	$r29,sp,64
	st.d	$r30,sp,72
	st.d	$r31,sp,80

	or	lzma,PARAM_lzma,zero
	st.d	lzma,sp,112
	or	bufLimit,PARAM_bufLimit,zero

	LOAD_LZMA_VAR dic,offset_dic
	LOAD_LZMA_VAR dicBufSize,offset_dicBufSize
	LOAD_LZMA_VAR dicPos,offset_dicPos
	add.d	limit,PARAM_limit,dic
	add.d	dicPos,dicPos,dic

	LOAD_LZMA_VAR buf,offset_buf
	// Keep range/code sign-extended like LoongArch W arithmetic results, so
	// 64-bit unsigned branches preserve UInt32 order after mul.w/sub.w/slli.w.
	ld.w	range,lzma,offset_range
	ld.w	cod,lzma,offset_code
	LOAD_LZMA_U32 processedPos,offset_processedPos
	LOAD_LZMA_U32 checkDicSize,offset_checkDicSize
	LOAD_LZMA_U32 state,offset_state
	LOAD_LZMA_VAR probs_Spec,offset_probs_1664
	addi.d	probs_IsMatch,probs_Spec,(IsMatch * PMULT)

	LOAD_LZMA_U32 rep0,offset_rep0
	LOAD_LZMA_U32 rep1,offset_rep1
	LOAD_LZMA_U32 rep2,offset_rep2
	LOAD_LZMA_U32 t0,offset_rep3
	st.w	t0,sp,88

	LOAD_LZMA_BYTE t0,offset_pb
	addi.w	t1,zero,1
	sll.w	t3,t1,t0
	addi.w	t3,t3,-1

	LOAD_LZMA_BYTE t0,offset_lp
	addi.w	t1,zero,0x100
	sll.w	t0,t1,t0
	LOAD_LZMA_BYTE t2,offset_lc
	addi.w	t1,zero,0x100
	srl.w	t1,t1,t2
	sub.w	t0,t0,t1
	or	litProps,t0,zero
	bstrins.d	litProps,t2,39,32
	or	pbMaskReg,t3,zero

	or	len,zero,zero
	or	sym,zero,zero
	or	t0,processedPos,checkDicSize
	beqz	t0,.Lprev_byte_ready_\@
	addi.d	t0,dicPos,-1
	bne	dicPos,dic,.Lprev_byte_load_\@
	add.d	t0,dic,dicBufSize
	addi.d	t0,t0,-1
.Lprev_byte_load_\@:
	ld.bu	sym,t0,0
.Lprev_byte_ready_\@:
	.endm

	.macro UPDATE_STATE_LITERAL
	addi.w	t0,zero,1
	slli.w	t0,t0,2
	bltu	state,t0,.Lstate_lit_zero_\@
	addi.w	state,state,-3
	b	.Lstate_lit_done_\@
.Lstate_lit_zero_\@:
	or	state,zero,zero
.Lstate_lit_done_\@:
	.endm

	.macro DECODE_REAL_EPILOGUE status:req
	ld.d	lzma,sp,112
	sub.d	dicPos,dicPos,dic
	STORE_LZMA_VAR buf,offset_buf
	STORE_LZMA_U32 range,offset_range
	STORE_LZMA_U32 cod,offset_code
	STORE_LZMA_VAR dicPos,offset_dicPos
	STORE_LZMA_U32 processedPos,offset_processedPos
	STORE_LZMA_U32 len,offset_remainLen
	STORE_LZMA_U32 rep0,offset_rep0
	STORE_LZMA_U32 rep1,offset_rep1
	STORE_LZMA_U32 rep2,offset_rep2
	ld.wu	t1,sp,88
	STORE_LZMA_U32 t1,offset_rep3
	STORE_LZMA_U32 state,offset_state

	or	$r4,\status,zero
	ld.d	ra,sp,0
	ld.d	$r22,sp,8
	ld.d	$r23,sp,16
	ld.d	$r24,sp,24
	ld.d	$r25,sp,32
	ld.d	$r26,sp,40
	ld.d	$r27,sp,48
	ld.d	$r28,sp,56
	ld.d	$r29,sp,64
	ld.d	$r30,sp,72
	ld.d	$r31,sp,80
	addi.d	sp,sp,144
	jr	ra
	.endm

	.globl LZMADEC_SYMBOL
	.type LZMADEC_SYMBOL, @function
LZMADEC_SYMBOL:
	DECODE_REAL_PROLOGUE

	// Complete branchful decode skeleton.  It is deliberately kept in the same
	// section order as x64/arm64 so each block can be rescheduled independently.
.Lmain_loop:
	IsMatchBranch_Pre
.Lmain_loop_have_match_prob:
	CMP_COD_BASE
	bgeu	cod,bound,IsMatch_label
	UPDATE_0 probPtr

// ---------- LITERAL ----------

lit_start:
	li.d	t0,kNumLitStates
	bgeu	state,t0,lit_matched_end
	UPDATE_STATE_LITERAL
lit_start_2:
	LIT_PROBS
	li.d	len,kTopValue
	addi.w	sym,zero,1
	alsl.d	probPtr,sym,probs,PSHIFT
	PLOAD	probBranch,probPtr
MY_ALIGN_FOR_LOOP
lit_loop:
	TREE_BIT_PRELOAD_BL len
	TREE_BIT_PRELOAD_BL len
	TREE_BIT_PRELOAD_BL len
	TREE_BIT_PRELOAD_BL len
	TREE_BIT_PRELOAD_BL len
	TREE_BIT_PRELOAD_BL len
	TREE_BIT_PRELOAD_BL len
	TREE_BIT_PRELOAD_LAST_BL len
.Llit_norm_done:
lit_end:
	IsMatchBranch_Pre
	st.b	sym,dicPos,0
	addi.d	dicPos,dicPos,1
	andi	sym,sym,0xff
	or	len,zero,zero
	CheckLimits fin_OK
	b	.Lmain_loop_have_match_prob
// ---------- MATCHES ----------

MY_ALIGN_FOR_ENTRY
IsMatch_label:
	UPDATE_1 probPtr
	SET_PROB_PTR IsRep,state
	IF_BIT_1_PTR_FALLTHROUGH IsRep_label

.Lnon_rep_match:
	ori	state,state,kStateNonRepFlag
	SET_PROBS LenCoder
	b	len_decode

// ---------- REP ----------

MY_ALIGN_FOR_ENTRY
IsRep_label:
	UPDATE_1 probPtr
	addi.d	probPtr,probPtr,((IsRepG0 - IsRep) * PMULT)
	IF_BIT_0_PTR IsRepG0_label

	addi.d	probPtr,probPtr,((IsRepG1 - IsRepG0) * PMULT)
	IF_BIT_0_PTR IsRepG1_label

	addi.d	probPtr,probPtr,((IsRepG2 - IsRepG1) * PMULT)
	IF_BIT_0_PTR IsRepG2_label

	ld.wu	t0,sp,88
	st.w	rep2,sp,88
	or	rep2,rep1,zero
	or	rep1,rep0,zero
	or	rep0,t0,zero
	b	.Lrep_len_ready

IsRepG2_label:
	or	t0,rep2,zero
	or	rep2,rep1,zero
	or	rep1,rep0,zero
	or	rep0,t0,zero
	b	.Lrep_len_ready

IsRepG1_label:
	or	t0,rep1,zero
	or	rep1,rep0,zero
	or	rep0,t0,zero
	b	.Lrep_len_ready

IsRepG0_label:
	and	t0,processedPos,pbMaskReg
	slli.w	t0,t0,4
	addi.d	probPtr,probPtr,-2048
	addi.d	probPtr,probPtr,(((IsRep0Long - IsRepG0) * PMULT) + 2048)
	alsl.d	probPtr,t0,probPtr,PSHIFT
	IF_BIT_0_PTR IsRep0Short_label

.Lrep_len_ready:
	UPDATE_STATE_REP
	SET_PROBS RepLenCoder
	b	len_decode

// ---------- REP 0 LITERAL ----------

IsRep0Short_label:
	UPDATE_STATE_REP0_SHORT
	sub.d	t0,dicPos,dic
	sub.d	t0,t0,rep0
	bge	t0,zero,.Lrep0_src_ready
	add.d	t0,t0,dicBufSize
.Lrep0_src_ready:
	add.d	t0,dic,t0
	ld.bu	sym,t0,0
	addi.w	processedPos,processedPos,1
	IsMatchBranch_Pre
	st.b	sym,dicPos,0
	addi.d	dicPos,dicPos,1
	or	len,zero,zero
	CheckLimits fin_OK
	b	.Lmain_loop_have_match_prob

// ---------- LEN DECODE ----------

MY_ALIGN_FOR_ENTRY
len_decode:
	and	t0,processedPos,pbMaskReg
	slli.w	t0,t0,4
	li.d	len,kTopValue
	PLOAD	probBranch,probs
	CMP_COD_BASE_WITH len
	bgeu	cod,bound,.Llen_choice1
	UPDATE_0 probs
	alsl.d	probs,t0,probs,PSHIFT
	TREE_3_TO_SYM_PRELOAD_BL len
	addi.w	len,sym,-8
	b	.Llen_done

.Llen_choice1:
	UPDATE_1 probs
	addi.d	probPtr,probs,(LenChoice2 * PMULT)
	PLOAD	probBranch,probPtr
	CMP_COD_BASE_WITH len
	bgeu	cod,bound,.Llen_high
	UPDATE_0 probPtr
	addi.w	t0,t0,kLenNumLowSymbols
	alsl.d	probs,t0,probs,PSHIFT
	TREE_3_TO_SYM_PRELOAD_BL len
	or	len,sym,zero
	b	.Llen_done

.Llen_high:
	UPDATE_1 probPtr
	addi.d	probs,probs,(LenHigh * PMULT)
	TREE_8_TO_SYM_PRELOAD_BL len
	addi.w	len,sym,(kLenNumLowSymbols * 2)

.Llen_done:
	andi	t0,state,kStateNonRepFlag
	beqz	t0,copy_match

// ---------- DECODE DISTANCE ----------

	addi.w	t0,zero,(kNumLenToPosStates - 1)
	bgeu	len,t0,.Llen_to_pos_clamped
	or	t0,len,zero
.Llen_to_pos_clamped:
	slli.w	t0,t0,kNumPosSlotBits
	SET_PROBS PosSlot
	alsl.d	probs,t0,probs,PSHIFT
	st.w	len,sp,104
	li.d	len,kTopValue
	TREE_6_POS_SLOT_PRELOAD_BL len,probs
	ld.wu	len,sp,104
	andi	sym,sym,3
	addi.w	t2,zero,(32 + (kStartPosModelIndex >> 1) - 1)
	bgeu	t2,probs,decode_dist_end
	addi.w	t0,probs,-(32 + 1)
	ori	sym,sym,2
	addi.w	t2,zero,(32 + (kEndPosModelIndex >> 1))
	bgeu	probs,t2,direct_loop_setup

// ---------- SPEC SHORT DISTANCE ----------

	sll.w	sym,sym,t0
	addi.w	sym,sym,1
	ADD_PROBS_BASE probs,SpecPos
	addi.w	t1,zero,1
spec_loop:
	REV_BIT_VAR probs
	addi.w	t0,t0,-1
	bnez	t0,spec_loop
	sub.w	sym,sym,t1
	b	decode_dist_end

// ---------- DIRECT DISTANCE ----------

direct_loop_setup:
	addi.w	t0,t0,-kNumAlignBits
	li.d	probs,kTopValue
MY_ALIGN_FOR_LOOP
direct_loop:
	bltu	range,probs,.Ldirect_norm
	DIRECT_8_OPT direct_end,direct_loop
.Ldirect_norm:
	ld.bu	t1,buf,0
	slli.w	cod,cod,8
	addi.d	buf,buf,1
	slli.w	range,range,8
	or	cod,cod,t1
	DIRECT_BIT_OPT direct_end
	DIRECT_BIT_OPT direct_end
	DIRECT_BIT_OPT direct_end
	DIRECT_BIT_OPT direct_end
	DIRECT_BIT_OPT direct_end
	DIRECT_BIT_OPT direct_end
	DIRECT_BIT_OPT direct_end
	DIRECT_BIT_OPT direct_end
	b	direct_loop

MY_ALIGN_FOR_ENTRY
direct_end:
	slli.w	sym,sym,kNumAlignBits
	addi.w	t2,zero,1
	REV_ALIGN_CONST_BL_WITH probs_Spec,probs,1,0
	REV_ALIGN_CONST_BL_WITH probs_Spec,probs,2,1
	REV_ALIGN_CONST_BL_WITH probs_Spec,probs,4,2
	REV_ALIGN_LAST_BL_WITH probs_Spec,probs
	or	sym,sym,t2
	addi.w	t0,zero,-1
	bne	sym,t0,decode_dist_end
	addi.w	len,zero,kMatchSpecLenStart
	andi	state,state,(kStateNonRepFlag - 1)
	b	fin_OK

decode_dist_end:
	or	t0,checkDicSize,zero
	bnez	checkDicSize,.Ldist_limit_ready
	or	t0,processedPos,zero
.Ldist_limit_ready:
	bltu	sym,t0,.Ldist_ok
	addi.w	len,len,(kMatchSpecLen_Error_Data + kMatchMinLen)
	b	fin
.Ldist_ok:
	st.w	rep2,sp,88
	or	rep2,rep1,zero
	or	rep1,rep0,zero
	addi.w	rep0,sym,1
	UPDATE_STATE_MATCH
	b	copy_match

// ---------- COPY MATCH ----------

MY_ALIGN_FOR_ENTRY
copy_match:
	addi.w	len,len,kMatchMinLen
	sub.d	t0,limit,dicPos
	beqz	t0,fin_OK
	or	t1,len,zero
	bgeu	t0,t1,.Lcur_len_ready
	or	t1,t0,zero
.Lcur_len_ready:
	add.w	processedPos,processedPos,t1
	sub.w	len,len,t1
	sub.d	t2,dicPos,dic
	sub.d	t0,t2,rep0
	bgeu	t2,rep0,.Lcopy_src_ready
	add.d	t0,t0,dicBufSize
.Lcopy_src_ready:
	add.d	probPtr,dicPos,t1
	sub.d	t2,dicBufSize,t0
	bltu	t2,t1,.Lcopy_cross
	add.d	probs,dic,t0
	sub.d	probBranch,probs,dicPos
	addi.d	bound,t1,-1
	addi.w	sym,zero,14
	addi.d	update,dicPos,-1
	sub.d	update,update,probs
	bleu	bound,sym,.Lcopy_short
	bleu	update,sym,.Lcopy_overlap
	addi.w	sym,zero,30
	bleu	update,sym,.Lcopy_lsx16_setup
	bleu	bound,sym,.Lcopy_lsx16_setup
	addi.w	sym,zero,62
	bleu	update,sym,.Lcopy_lsx32_setup
	bleu	bound,sym,.Lcopy_lsx32_setup
	bstrpick.d	bound,t1,35,6
	slli.d	bound,bound,6
	add.d	bound,dicPos,bound
.Lcopy_lsx64:
	vld	$vr0,probs,0
	vld	$vr1,probs,16
	vst	$vr0,dicPos,0
	vst	$vr1,dicPos,16
	vld	$vr2,probs,32
	vld	$vr3,probs,48
	addi.d	probs,probs,64
	vst	$vr2,dicPos,32
	vst	$vr3,dicPos,48
	addi.d	dicPos,dicPos,64
	bne	dicPos,bound,.Lcopy_lsx64
	sub.d	bound,probPtr,dicPos
	bstrpick.d	bound,bound,35,5
	beqz	bound,.Lcopy_lsx32_tail
	slli.d	bound,bound,5
	add.d	bound,dicPos,bound
	b	.Lcopy_lsx32
.Lcopy_lsx32_setup:
	bstrpick.d	bound,t1,35,5
	slli.d	bound,bound,5
	add.d	bound,dicPos,bound
.Lcopy_lsx32:
	vld	$vr0,probs,0
	vld	$vr1,probs,16
	addi.d	probs,probs,32
	vst	$vr0,dicPos,0
	vst	$vr1,dicPos,16
	addi.d	dicPos,dicPos,32
	bne	dicPos,bound,.Lcopy_lsx32
.Lcopy_lsx32_tail:
	beq	dicPos,probPtr,.Lcopy_done
	addi.d	bound,dicPos,16
	bltu	probPtr,bound,.Lcopy_tail_ptr
	vld	$vr0,probs,0
	vst	$vr0,dicPos,0
	addi.d	dicPos,dicPos,16
	beq	dicPos,probPtr,.Lcopy_done
.Lcopy_tail_ptr:
	or	update,dicPos,zero
	b	.Lcopy_tail_bytes
.Lcopy_lsx16_setup:
	bstrpick.d	bound,t1,35,4
	slli.d	bound,bound,4
	or	update,zero,zero
.Lcopy_lsx16:
	vldx	$vr0,probs,update
	vstx	$vr0,dicPos,update
	addi.d	update,update,16
	bne	update,bound,.Lcopy_lsx16
	beq	update,t1,.Lcopy_done_set
	add.d	update,dicPos,update
	b	.Lcopy_tail_bytes
.Lcopy_overlap:
	beqz	update,.Lcopy_repl_b
	addi.w	t2,zero,1
	beq	update,t2,.Lcopy_repl_h
	addi.w	t2,zero,3
	beq	update,t2,.Lcopy_repl_w
	addi.w	t2,zero,7
	bne	update,t2,.Lcopy_bytes
	vldrepl.d	$vr0,dicPos,-8
	b	.Lcopy_repl_vec
.Lcopy_repl_w:
	vldrepl.w	$vr0,dicPos,-4
	b	.Lcopy_repl_vec
.Lcopy_repl_h:
	vldrepl.h	$vr0,dicPos,-2
	b	.Lcopy_repl_vec
.Lcopy_repl_b:
	vldrepl.b	$vr0,dicPos,-1
.Lcopy_repl_vec:
	addi.d	bound,zero,-16
	and	bound,t1,bound
	add.d	update,dicPos,bound
.Lcopy_repl_loop:
	vst	$vr0,dicPos,0
	addi.d	dicPos,dicPos,16
	bne	dicPos,update,.Lcopy_repl_loop
	beq	bound,t1,.Lcopy_done
	b	.Lcopy_bytes
.Lcopy_short:
	bgeu	update,bound,.Lcopy_short_nonoverlap
	b	.Lcopy_bytes
.Lcopy_short_nonoverlap:
	addi.w	sym,zero,8
	bgeu	t1,sym,.Lcopy_short_8
	addi.w	sym,zero,4
	bgeu	t1,sym,.Lcopy_short_4
	addi.w	sym,zero,2
	bgeu	t1,sym,.Lcopy_short_2
	ldx.bu	t2,dicPos,probBranch
	st.b	t2,dicPos,0
	or	sym,t2,zero
	or	dicPos,probPtr,zero
	b	.Lcopy_done_have_sym
.Lcopy_short_8:
	ld.d	update,probs,0
	addi.d	t2,t1,-8
	st.d	update,dicPos,0
	ldx.d	update,probs,t2
	stx.d	update,dicPos,t2
	bstrpick.d	sym,update,63,56
	or	dicPos,probPtr,zero
	b	.Lcopy_done_have_sym
.Lcopy_short_4:
	ld.wu	update,probs,0
	addi.d	t2,t1,-4
	st.w	update,dicPos,0
	ldx.wu	update,probs,t2
	stx.w	update,dicPos,t2
	bstrpick.d	sym,update,31,24
	or	dicPos,probPtr,zero
	b	.Lcopy_done_have_sym
.Lcopy_short_2:
	ld.hu	update,probs,0
	addi.d	t2,t1,-2
	st.h	update,dicPos,0
	ldx.hu	update,probs,t2
	stx.h	update,dicPos,t2
	bstrpick.d	sym,update,15,8
	or	dicPos,probPtr,zero
	b	.Lcopy_done_have_sym
.Lcopy_bytes:
	ldx.bu	t2,dicPos,probBranch
	st.b	t2,dicPos,0
	addi.d	dicPos,dicPos,1
	beq	probPtr,dicPos,.Lcopy_done_t2
	ldx.bu	t2,dicPos,probBranch
	st.b	t2,dicPos,0
	addi.d	dicPos,dicPos,1
	beq	probPtr,dicPos,.Lcopy_done_t2
	ldx.bu	t2,dicPos,probBranch
	st.b	t2,dicPos,0
	addi.d	dicPos,dicPos,1
	beq	probPtr,dicPos,.Lcopy_done_t2
	ldx.bu	t2,dicPos,probBranch
	st.b	t2,dicPos,0
	addi.d	dicPos,dicPos,1
	bne	probPtr,dicPos,.Lcopy_bytes
.Lcopy_done_t2:
	or	sym,t2,zero
	b	.Lcopy_done_have_sym
.Lcopy_done:
	ld.bu	sym,dicPos,-1
.Lcopy_done_have_sym:
	IsMatchBranch_Pre
	bgeu	dicPos,limit,fin_OK
	bgeu	buf,bufLimit,fin_OK
	b	.Lmain_loop_have_match_prob

.Lcopy_tail_bytes:
	ldx.bu	t2,update,probBranch
	st.b	t2,update,0
	addi.d	update,update,1
	beq	probPtr,update,.Lcopy_done_set_t2
	ldx.bu	t2,update,probBranch
	st.b	t2,update,0
	addi.d	update,update,1
	beq	probPtr,update,.Lcopy_done_set_t2
	ldx.bu	t2,update,probBranch
	st.b	t2,update,0
	addi.d	update,update,1
	beq	probPtr,update,.Lcopy_done_set_t2
	ldx.bu	t2,update,probBranch
	st.b	t2,update,0
	addi.d	update,update,1
	bne	probPtr,update,.Lcopy_tail_bytes
.Lcopy_done_set_t2:
	or	dicPos,probPtr,zero
	or	sym,t2,zero
	b	.Lcopy_done_have_sym
.Lcopy_done_set:
	or	dicPos,probPtr,zero
	b	.Lcopy_done
.Lcopy_cross:
	ldx.bu	t2,dic,t0
	addi.d	t0,t0,1
	addi.d	dicPos,dicPos,1
	st.b	t2,dicPos,-1
	bne	t0,dicBufSize,.Lcopy_cross_no_wrap
	or	t0,zero,zero
.Lcopy_cross_no_wrap:
	bne	dicPos,probPtr,.Lcopy_cross
	or	sym,t2,zero
	b	.Lcopy_done_have_sym

// ---------- LITERAL MATCHED ----------

lit_matched_end:
	sub.d	t2,dicPos,dic
	sub.d	t2,t2,rep0
	bge	t2,zero,.Llitm_src_ready
	add.d	t2,t2,dicBufSize
.Llitm_src_ready:
	add.d	t2,dic,t2
	slti	t0,state,10
	slli.w	t1,t0,1
	add.w	t0,t0,t1
	addi.w	state,state,-6
	add.w	state,state,t0
	ld.bu	matchByte,t2,0
	li.d	len,kTopValue
	LIT_PROBS
	addi.w	offs,zero,0x100
	addi.w	sym,zero,1
MY_ALIGN_FOR_LOOP
litm_loop:
	LITM_PRELOAD
	LITM_TREE_BIT_PRELOAD_BL
	LITM_TREE_BIT_PRELOAD_BL
	LITM_TREE_BIT_PRELOAD_BL
	LITM_TREE_BIT_PRELOAD_BL
	LITM_TREE_BIT_PRELOAD_BL
	LITM_TREE_BIT_PRELOAD_BL
	LITM_TREE_BIT_PRELOAD_BL
	LITM_TREE_BIT_PRELOAD_LAST_BL
.Llitm_done:
	IsMatchBranch_Pre
	st.b	sym,dicPos,0
	addi.d	dicPos,dicPos,1
	andi	sym,sym,0xff
	or	len,zero,zero
	CheckLimits fin_OK
	b	.Lmain_loop_have_match_prob

fin_OK:
fin:
	NORM
	addi.w	t1,zero,(kMatchSpecLen_Error_Data - 1)
	sltu	t0,t1,len
	DECODE_REAL_EPILOGUE t0
	.size LZMADEC_SYMBOL, .-LZMADEC_SYMBOL

	.section .note.GNU-stack,"",@progbits
