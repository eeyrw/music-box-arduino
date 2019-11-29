#include "Player.h"
#include "AsmCommon.h"

.globl PlayNoteTimingCheck
.globl PlayUpdateNextScoreTick

.text
PlayNoteTimingCheck:
;if((currentTick>>8)>=player->lastScoreTick)
movw zl,arg0l
cli
lds t0l,(currentTick+1)
ldd t0h,Z+pLastScoreTick_b0
cp t0l,t0h
lds t0l,(currentTick+2)
ldd t0h,Z+pLastScoreTick_b1
cpc t0l,t0h
lds t0l,(currentTick+3)
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

