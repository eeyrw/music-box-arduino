#include "SynthCore.h"
#include "AsmCommon.h"

.section .bss
.global currentTick
currentTick:
.skip 4
.global decayGenTick
decayGenTick:
.skip 1  
.section .text 

UpdateTick: 
    sec
	lds t0l,currentTick
	adc t0l,zero
	sts currentTick,t0l
	lds t0l,currentTick+1
	adc t0l,zero
	sts currentTick+1,t0l
	lds t0l,currentTick+2
	adc t0l,zero
	sts currentTick+2,t0l
	lds t0l,currentTick+3
	adc t0l,zero
	sts currentTick+3,t0l

	lds t0l,decayGenTick
	cpi t0l,DECAY_TIME_FACTOR
	brsh updateDecayGenTickEnd ; BRSH – Branch if Same or Higher (Unsigned)
	inc t0l
	sts decayGenTick,t0l
	updateDecayGenTickEnd: