#include <avr/io.h>

#define PeriodTimerHandler TIMER0_COMPA_vect

.section .text
.global PeriodTimerHandler
PeriodTimerHandler:
	sbi _SFR_IO_ADDR(PORTB),0
	in	r0, _SFR_IO_ADDR(SREG)
	push r0
	push r18
	push r19
	push r20
	push r21	
	push r30
	push r31
    #include "Synth.inc"
    #include "UpdateTick.inc"
	pop r31
	pop r30
	pop r21	
	pop r20
	pop r19
	pop r18
	pop r0
	out	_SFR_IO_ADDR(SREG), r0
	cbi _SFR_IO_ADDR(PORTB),0
	reti