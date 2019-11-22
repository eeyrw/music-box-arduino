#include <avr/io.h>
.text
.global SynthAsm
.global NoteOnAsm
.global GenDecayEnvlopeAsm

;typedef struct _SoundUnit
;{
;	uint8_t increment_frac;
;	uint8_t increment_int;
;	uint8_t  wavetablePos_frac;
;	uint16_t  wavetablePos_int;
;	uint8_t envelopeLevel;
;	uint8_t envelopePos;
;	int16_t val;
;	int8_t sampleVal;
;} SoundUnit;


;typedef struct _Synthesizer
;{
;    SoundUnitUnion SoundUnitUnionList[POLY_NUM];
;	int16_t mixOut;
;    uint8_t lastSoundUnit;
;}Synthesizer;

SoundUnitSize=10

pIncrement_int=1
pIncrement_frac=0
pWavetablePos_frac=2
pWavetablePos_int_h=4
pWavetablePos_int_l=3
pEnvelopeLevel=5
pEnvelopePos=6
pVal=7
pSampleVal=9

pMixOut=SoundUnitSize*POLY_NUM
pLastSoundUnit=SoundUnitSize*POLY_NUM+2


ENVELOP_LEN=256
POLY_NUM=5
WAVETABLE_CELESTA_C5_ATTACK_LEN=1998
WAVETABLE_CELESTA_C5_LEN=2608
WAVETABLE_CELESTA_C5_LOOP_LEN=(WAVETABLE_CELESTA_C5_LEN - WAVETABLE_CELESTA_C5_ATTACK_LEN)




#define xl r26
#define xh r27
#define yl r28
#define yh r29
#define zl r30
#define zh r31
#define zero r1
#define t0l r18
#define t0h r19
#define t1l r20
#define t1h r21
#define t2l r22
#define t2h r23
#define mixOutl r14
#define mixOuth r15
#define loopIndex r16

#define arg0l r24
#define arg0h r25
#define arg1l r22
#define arg1h r23

.extern	WaveTable_Celesta_C5
.extern	EnvelopeTable
.extern WaveTable_Celesta_C5_Increment

SynthAsm:
push yl
push yh
push loopIndex
push mixOutl
push mixOuth
clr loopIndex
clr mixOutl
clr mixOuth
movw yl,arg0l
loopSynth:
	cpi loopIndex,POLY_NUM
	breq loopSynth_end
	ldd t2l,Y+pEnvelopeLevel ; Load evnvlopelevel to t2l
#ifdef RUN_TEST	
	cp t2l,zero
	breq loopSynthContinue
#endif		
	ldd zl,Y+pWavetablePos_int_l ; Get a sample by pWavetablePos_int and save to t0l
	ldd zh,Y+pWavetablePos_int_h
	ldi t0l,lo8(WaveTable_Celesta_C5)
	ldi t0h,hi8(WaveTable_Celesta_C5)
	add zl,t0l
	adc zh,t0h
	lpm t0l,Z
#ifdef RUN_TEST
	std Y+pSampleVal,t0l
#endif
	mulsu t0l,t2l ;r1:r0=sample*evnvlopelevel
	clr r0 ;(r1:r0)/255
	sbrc r1,7 ;skip if bit 7(sign bit of signed 16) of r1 is 0
	com r0 ;~r0=0xFF
#ifdef RUN_TEST	
	std Y+pVal,r1
	std Y+(pVal+1),r0
#endif	
	add mixOutl,r1 ; mixOut+=(r1:r0)>>8
	clr r1 ; Always keep r1(zero)=0
	adc mixOuth,r0


	ldd t0l,Y+pIncrement_frac
	ldd t0h,Y+pWavetablePos_frac 
	add t0l,t0h
	std Y+pWavetablePos_frac,t0l

	ldd t0l,Y+pIncrement_int
	ldd t0h,Y+pWavetablePos_int_l
	adc t0l,t0h

	ldd t0h,Y+pWavetablePos_int_h
	adc t0h,zero

	cpi t0l,lo8(WAVETABLE_CELESTA_C5_LEN+1) ; "+1" is to realize "<="
	ldi t1l,hi8(WAVETABLE_CELESTA_C5_LEN+1)
	cpc t0h,t1l
	brlo branch0_end
	subi t0l,lo8(WAVETABLE_CELESTA_C5_LOOP_LEN)
	ldi t1l,hi8(WAVETABLE_CELESTA_C5_LOOP_LEN)
	sbc t0h,t1l
	branch0_end:
	std Y+pWavetablePos_int_l,t0l
	std Y+pWavetablePos_int_h,t0h
loopSynthContinue:						
inc loopIndex
ldi t0l,SoundUnitSize
add yl,t0l
adc yh,zero
rjmp loopSynth

loopSynth_end:
movw yl,arg0l
std Y+pMixOut,mixOutl
std Y+pMixOut+1,mixOuth

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

pop mixOuth
pop mixOutl
pop loopIndex
pop yh
pop yl
ret

GenDecayEnvlopeAsm:
push yl
push yh
push loopIndex
clr loopIndex
movw yl,arg0l
loopGeDecayEnvlope:
	cpi loopIndex,POLY_NUM
	breq loopGenDecayEnvlope_end
;    SoundUnitUnion* soundUnionList=&(synth->SoundUnitUnionList[0]);
;	for (uint8_t i = 0; i < POLY_NUM; i++)
;	{
;		if(soundUnionList[i].combine.wavetablePos_int >= WAVETABLE_CELESTA_C5_ATTACK_LEN &&
;				soundUnionList[i].combine.envelopePos < sizeof(EnvelopeTable)-1)
;		{
;			soundUnionList[i].combine.envelopeLevel = EnvelopeTable[soundUnionList[i].combine.envelopePos];
;			soundUnionList[i].combine.envelopePos += 1;
;		}
;	}
	ldd t0l,Y+pWavetablePos_int_l ; 
	ldd t0h,Y+pWavetablePos_int_h
	cpi t0l,lo8(WAVETABLE_CELESTA_C5_ATTACK_LEN)
	ldi t1l,hi8(WAVETABLE_CELESTA_C5_ATTACK_LEN)
	cpc t0h,t1l
	brlo envelopUpdateEnd ;t0h<t1l

	ldd t0l,Y+pEnvelopePos ; Get envelopePos and save to t0l
	cpi t0l,lo8(ENVELOP_LEN-1)
	brsh envelopUpdateEnd ;t0l>=ENVELOP_LEN-1

	ldi zl,lo8(EnvelopeTable)
	ldi zh,hi8(EnvelopeTable)
	add zl,t0l
	adc zh,zero
	lpm t0h,Z ; Get envelope level and save to t0h
	std Y+pEnvelopeLevel,t0h
	inc t0l
	std Y+pEnvelopePos,t0l
envelopUpdateEnd:	
inc loopIndex
ldi t0l,SoundUnitSize
add yl,t0l
adc yh,zero
rjmp loopGeDecayEnvlope
loopGenDecayEnvlope_end:
pop loopIndex
pop yh
pop yl
ret

NoteOnAsm:
push yl
push yh
movw yl,arg0l
; 	ldw y,(0x03, sp) 		; Load sound unit pointer to register Y. (0x03, sp) is synthesizer object's address.
; 	;void NoteOn(Synthesizer* synth,uint8_t note)
; 	;{
; 	;	uint8_t lastSoundUnit = synth->lastSoundUnit;

; 	;	disable_interrupts();
; 	;	synth->SoundUnitUnionList[lastSoundUnit].combine.increment = PitchIncrementTable[note&0x7F];
; 	;	synth->SoundUnitUnionList[lastSoundUnit].combine.wavetablePos_frac = 0;
; 	;	synth->SoundUnitUnionList[lastSoundUnit].combine.wavetablePos_int = 0;
; 	;	synth->SoundUnitUnionList[lastSoundUnit].combine.envelopePos = 0;
; 	;	synth->SoundUnitUnionList[lastSoundUnit].combine.envelopeLevel = 255;
; 	;	enable_interrupts();

; 	;	lastSoundUnit++;

; 	;	if (lastSoundUnit== POLY_NUM)
; 	;		lastSoundUnit = 0;

; 	;	synth->lastSoundUnit=lastSoundUnit;
; 	;}
cli
ldi t0l,SoundUnitSize
ldd t0h,Y+pLastSoundUnit
mul t0l,t0h
add yl,r0
adc yh,r1
clr r1 ; Always keep r1=0
ldi zl,lo8(WaveTable_Celesta_C5_Increment)
ldi zh,hi8(WaveTable_Celesta_C5_Increment)
mov t0l,arg1l
lsl t0l
add zl,t0l
adc zh,zero
lpm t1l,Z+
lpm t1h,Z
std Y+pIncrement_frac,t1l
std Y+pIncrement_int,t1h
std Y+pWavetablePos_frac,zero
std Y+pWavetablePos_int_l,zero
std Y+pWavetablePos_int_h,zero
std Y+pEnvelopePos,zero
ldi t0l,255
std Y+pEnvelopeLevel,t0l
sei
inc t0h
cpi t0h,POLY_NUM
brne lastSoundUnitUpdateEndNotEq
clr t0h
lastSoundUnitUpdateEndNotEq:
movw yl,arg0l
std Y+pLastSoundUnit,t0h

pop yh
pop yl

ret
.end

