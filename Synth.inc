#include "WaveTable.h"
#include "SynthCore.h"
#include "AsmCommon.h"

.section .text 
	SynthAsm: ; Register usage: t0l,t0h:r18,r19 t1l,t1h:r20,r21 zl,zh:r30,r31
	push yl
	push yh
	push loopIndex
	push mixOutl
	push mixOuth
	push mixOute	
	clr loopIndex
	clr mixOutl
	clr mixOuth
	clr mixOute	
	clr zero
	ldi yl,lo8(synthForAsm)
	ldi yh,hi8(synthForAsm)
	loopSynth:
		cpi loopIndex,POLY_NUM
		breq loopSynth_end
		ldd t1h,Y+pEnvelopeLevel ; Load evnvlopelevel to t1h	
		cp t1h,zero
		breq loopSynthContinue	
		ldd zl,Y+pWavetablePos_int_l ; Get a sample by pWavetablePos_int and save to t0l
		ldd zh,Y+pWavetablePos_int_h


		ldd t0l,Y+pIncrement_frac
		ldd t0h,Y+pWavetablePos_frac 
		add t0l,t0h
		std Y+pWavetablePos_frac,t0l

		ldd t0l,Y+pIncrement_int
		adc t0l,zl

		mov t0h,zh
		adc t0h,zero

		cpi t0l,lo8(WAVETABLE_LEN)
		ldi t1l,hi8(WAVETABLE_LEN)
		cpc t0h,t1l
		brlo branch0_end
		subi t0l,lo8(WAVETABLE_LOOP_LEN)
		ldi t1l,hi8(WAVETABLE_LOOP_LEN)
		sbc t0h,t1l
		branch0_end:
		std Y+pWavetablePos_int_l,t0l
		std Y+pWavetablePos_int_h,t0h



		ldi t0l,lo8(WaveTable)
		ldi t0h,hi8(WaveTable)
		add zl,t0l
		adc zh,t0h
		lpm t0l,Z
	#ifdef RUN_TEST
		std Y+pSampleVal,t0l
	#endif
		mulsu t0l,t1h ;r1:r0=sample*evnvlopelevel
		; clr r0 ;(r1:r0)/255
		; sbrc r1,7 ;skip if bit 7(sign bit of signed 16) of r1 is 0
		; com r0 ;~r0=0xFF
	#ifdef RUN_TEST	
		std Y+pVal,r1
		std Y+(pVal+1),r0
	#endif	
		clr t0l ;(r1:r0)/255
		sbrc r1,7 ;skip if bit 7(sign bit of signed 16) of r1 is 0
		com t0l ;~r0=0xFF	
		add mixOutl,r0 ; mixOut+=(r1:r0)>>8
		adc mixOuth,r1			
		adc mixOute,t0l
		clr r1 ; Always keep r1(zero)=0			


	loopSynthContinue:						
	inc loopIndex
	ldi t0l,SoundUnitSize
	add yl,t0l
	adc yh,zero
	rjmp loopSynth

	loopSynth_end:

	mov mixOutl,mixOuth
	mov mixOuth,mixOute
	;clr mixOuth ;(r1:r0)/255
	;sbrc mixOutl,7 ;skip if bit 7(sign bit of signed 16) of r1 is 0
	;com mixOuth ;~r0=0xFF

	#ifdef RUN_TEST
	sts synthForAsm+pMixOut,mixOutl
	sts synthForAsm+pMixOut+1,mixOuth
	#endif

	asr mixOuth
	ror mixOutl

	ldi	t0l, lo8(253)			;Clip it between -255 to 253
	ldi t0h, hi8(253)
	cp mixOutl,t0l
	cpc mixOuth,t0h
	brlt	higherBoundSatisfied			;
	movw	mixOutl, t0l			;
	higherBoundSatisfied:
	ldi	t0l, lo8(-255)			;
	ldi t0h, hi8(-255)
	cp mixOutl,t0l
	cpc mixOuth,t0h	;
	brge	lowerBoundSatisfied			;
	movw	mixOutl, t0l			;/
	lowerBoundSatisfied:
	asr mixOuth ; Set it to PWM modulator ： 把16位的T2带符号位右移一位，除以2，最低位移到Carrier 
	ror mixOutl			
	ror	mixOuth				; 把T2H的高位右移，Carrier进到T2H的第七位
	mov	t0l, mixOutl			; 复制T2L到EL
	subi t0l, 0x80	; EL=EL-0x80
	mov	t0h, t0l			; 
	com	t0h				; EH取反
	sbrc mixOuth, 7		; 如果T2H的第七位是0就跳过下面一行
	inc	t0l				; EL++
	sts OCR1AL,t0l
	sts OCR1BL,t0h

	pop mixOute	
	pop mixOuth
	pop mixOutl
	pop loopIndex
	pop yh
	pop yl