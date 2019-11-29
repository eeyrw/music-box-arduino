#include "SynthCore.h"
#include "WaveTable.h"
#include "AsmCommon.h"

.global NoteOnAsm
.global GenDecayEnvlopeAsm

.text
GenDecayEnvlopeAsm:
push yl
push yh
push loopIndex
clr loopIndex
ldi yl,lo8(synthForAsm)
ldi yh,hi8(synthForAsm)
loopGeDecayEnvlope:
	cpi loopIndex,POLY_NUM
	breq loopGenDecayEnvlope_end
;    SoundUnitUnion* soundUnionList=&(synth->SoundUnitUnionList[0]);
;	for (uint8_t i = 0; i < POLY_NUM; i++)
;	{
;		if(soundUnionList[i].combine.wavetablePos_int >= WAVETABLE_ATTACK_LEN &&
;				soundUnionList[i].combine.envelopePos < sizeof(EnvelopeTable)-1)
;		{
;			soundUnionList[i].combine.envelopeLevel = EnvelopeTable[soundUnionList[i].combine.envelopePos];
;			soundUnionList[i].combine.envelopePos += 1;
;		}
;	}
	ldd t0l,Y+pWavetablePos_int_l ; 
	ldd t0h,Y+pWavetablePos_int_h
	cpi t0l,lo8(WAVETABLE_ATTACK_LEN)
	ldi t1l,hi8(WAVETABLE_ATTACK_LEN)
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
ldi yl,lo8(synthForAsm)
ldi yh,hi8(synthForAsm)
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

ldi t0l,SoundUnitSize
cli
ldd t0h,Y+pLastSoundUnit
mul t0l,t0h
add yl,r0
adc yh,r1
clr r1 ; Always keep r1=0
sei
mov t0l,arg0l
lsl t0l
ldi zl,lo8(WaveTable_Increment)
ldi zh,hi8(WaveTable_Increment)
add zl,t0l
adc zh,zero
lpm t1l,Z+
lpm t1h,Z
cli
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
ldi yl,lo8(synthForAsm)
ldi yh,hi8(synthForAsm)
std Y+pLastSoundUnit,t0h

pop yh
pop yl

ret
.end

