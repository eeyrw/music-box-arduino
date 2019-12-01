#ifndef __PLAYER_H__
#define __PLAYER_H__

#define pStatus 0
#define pLastScoreTick_b0 1
#define pLastScoreTick_b1 2
#define pLastScoreTick_b2 3
#define pLastScoreTick_b3 4
#define pScorePointer 5
#define pMainSynthesizer 7

#ifndef __ASSEMBLER__
#include <stdint.h>
#include "SynthCore.h"
#include <avr/pgmspace.h>

#ifdef __cplusplus
extern "C" {
#endif

enum PLAY_STATUS
{
    STATUS_STOP = 0,
    STATUS_REDAY_TO_PLAY = 1,
    STATUS_PLAYING = 2
};

typedef struct _Player
{
    uint8_t status;
    uint32_t lastScoreTick;
    uint8_t *scorePointer;
    Synthesizer *synthesizerPointer;
} Player;

extern void PlayerInit(Player *player, Synthesizer *synthesizer);
extern void PlayerProcess(Player *player);
extern void PlayerPlay(Player *player, uint8_t *score);
extern uint8_t PlayNoteTimingCheck(Player *player);
extern void PlayUpdateNextScoreTick(Player *player);

extern Player mainPlayer;

#ifdef __cplusplus
} //end extern "C"
#endif

#endif

#endif