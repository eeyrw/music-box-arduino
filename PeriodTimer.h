#ifndef __PERIOD_TIMER_H__
#define __PERIOD_TIMER_H__

#ifndef __ASSEMBLER__
extern uint32_t currentTick;
extern uint8_t decayGenTick;
#else
.extern currentTick
.extern decayGenTick
#endif

#endif