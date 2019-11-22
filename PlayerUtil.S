#include <avr/io.h>
.text

.globl UpdateTick
.globl PlayNoteTimingCheck
.globl PlayUpdateNextScoreTick

; typedef struct _Player
; {
; 	uint8_t status;
;     uint32_t  currentTick;
; 	uint32_t  lastScoreTick;
; 	uint8_t  decayGenTick;
;     uint8_t* scorePointer;
;     Synthesizer mainSynthesizer;
; } Player;

.equ pStatus,0
.equ pCurrentTick_b0,1
.equ pCurrentTick_b1,2
.equ pCurrentTick_b2,3
.equ pCurrentTick_b3,4
.equ pLastScoreTick_b0,5
.equ pLastScoreTick_b1,6
.equ pLastScoreTick_b2,7
.equ pLastScoreTick_b3,8
.equ pDecayGenTick,9
.equ pScorePointer,10
.equ pMainSynthesizer,12

#define zl r30
#define zh r31
#define yl r28
#define yh r29
#define zero r1
#define t0l r18
#define t0h r19
#define t1l r20
#define t1h r21

#define arg0l r24
#define arg0h r25

UpdateTick:
; ; void Player32kProc(Player* player)
; ; {
; ;     Synth(&(player->mainSynthesizer));
; ;     player->currentTick++;
; ;     if(player->decayGenTick<200)
; ;         player->decayGenTick+=1;
; ; }
; Player* player r25:r24
movw zl,arg0l
sec
ldd t0l,Z+pCurrentTick_b0
adc t0l,zero
std Z+pCurrentTick_b0,t0l
ldd t0l,Z+pCurrentTick_b1
adc t0l,zero
std Z+pCurrentTick_b1,t0l
ldd t0l,Z+pCurrentTick_b2
adc t0l,zero
std Z+pCurrentTick_b2,t0l
ldd t0l,Z+pCurrentTick_b3
adc t0l,zero
std Z+pCurrentTick_b3,t0l

ldd t0l,Z+pDecayGenTick
cpi t0l,150
brsh updateDecayGenTickEnd ; BRSH – Branch if Same or Higher (Unsigned)
inc t0l
std Z+pDecayGenTick,t0l
updateDecayGenTickEnd:
ret

PlayNoteTimingCheck:
; ;if((player->currentTick>>8)>=player->lastScoreTick)
; 	ldw y,(0x03, sp) 		; Load sound unit pointer to register Y. (0x03, sp) is player object's address.
;     ld a,(pLastScoreTick_b2,y)
;     cp a,(pCurrentTick_b3,y) ;Set flag C is (pCurrentTick_b3,y)>(pLastScoreTick_b2,y)
;     jrc playNoteTimingCheckEndReturnTrue$
;     ldw x,y
;     ldw x,(pLastScoreTick_b1,x)
;     cpw x,(pCurrentTick_b2,y)
;     jrc playNoteTimingCheckEndReturnTrue$
;     clr a
;     ret
; playNoteTimingCheckEndReturnTrue$:
;     ld a,#0xff
; Player* player r25:r24
movw zl,arg0l
cli
ldd t0l,Z+pCurrentTick_b1
ldd t0h,Z+pLastScoreTick_b0
cp t0l,t0h
ldd t0l,Z+pCurrentTick_b2
ldd t0h,Z+pLastScoreTick_b1
cpc t0l,t0h
ldd t0l,Z+pCurrentTick_b3
ldd t0h,Z+pLastScoreTick_b2
cpc t0l,t0h
sei
clr arg0l
brlo playNoteTimingCheckEnd
com arg0l
playNoteTimingCheckEnd:
    ret

PlayUpdateNextScoreTick:
;         ;    tempU32=player->lastScoreTick;
;         ;     do
;         ;    {
;         ;        temp=*(player->scorePointer);
;         ;        player->scorePointer++;
;         ;        tempU32+=temp;
;         ;    } while (temp==0xFF);
;         ;    player->lastScoreTick=tempU32;
push yl
push yh
movw yl,arg0l
varTickAccumulateLoop:
ldd t0l,Y+pScorePointer
ldd t0h,Y+(pScorePointer+1)
movw zl,t0l
lpm t0l,Z
sec
adc zl,zero
adc zh,zero
std Y+pScorePointer,zl
std Y+(pScorePointer+1),zh

ldd t0h,Y+pLastScoreTick_b0
add t0h,t0l
std Y+pLastScoreTick_b0,t0h

ldd t0h,Y+pLastScoreTick_b1
adc t0h,zero
std Y+pLastScoreTick_b1,t0h

ldd t0h,Y+pLastScoreTick_b2
adc t0h,zero
std Y+pLastScoreTick_b2,t0h

ldd t0h,Y+pLastScoreTick_b3
adc t0h,zero
std Y+pLastScoreTick_b3,t0h

cpi t0l,0xff
breq varTickAccumulateLoop
pop yh
pop yl
    ret
.end

