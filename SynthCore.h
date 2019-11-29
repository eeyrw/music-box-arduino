#ifndef __SYNTH_CORE_H__
#define __SYNTH_CORE_H__

#ifdef __cplusplus
extern "C" {
#endif

#define POLY_NUM 5
#define ENVELOP_LEN 256

#define SoundUnitSize 10

#define pIncrement_int 1
#define pIncrement_frac 0
#define pWavetablePos_frac 2
#define pWavetablePos_int_h 4
#define pWavetablePos_int_l 3
#define pEnvelopeLevel 5
#define pEnvelopePos 6
#define pVal 7
#define pSampleVal 9

#define pMixOut SoundUnitSize*POLY_NUM
#define pLastSoundUnit (SoundUnitSize*POLY_NUM+2)

#ifndef __ASSEMBLER__
#include <stdint.h>
typedef struct _SoundUnit
{
	uint16_t increment;
	uint8_t  wavetablePos_frac;
	uint16_t  wavetablePos_int;
	uint8_t envelopeLevel;
	uint8_t envelopePos;
	int16_t val;
	int8_t sampleVal;
} SoundUnit;

typedef struct _SoundUnitSplit
{
	uint8_t increment_frac;
	uint8_t increment_int;
	uint8_t  wavetablePos_frac;
	uint16_t  wavetablePos_int;
	uint8_t envelopeLevel;
	uint8_t envelopePos;
	int16_t val;
	int8_t sampleVal;
} SoundUnitSplit;


typedef union _SoundUnitUnion
{
	SoundUnit combine;
	SoundUnitSplit split; 
}SoundUnitUnion;


typedef struct _Synthesizer
{
    SoundUnitUnion SoundUnitUnionList[POLY_NUM];
	int16_t mixOut;
    uint8_t lastSoundUnit;
}Synthesizer;

extern const uint8_t EnvelopeTable[];

extern void SynthInit(Synthesizer* synth);

#ifdef RUN_TEST
extern void NoteOnC(uint8_t note);
extern void SynthC(void);
extern void GenDecayEnvlopeC(void);
#endif

extern void NoteOnAsm(uint8_t note);
extern void GenDecayEnvlopeAsm(void);
extern void SynthAsm(void);

extern const uint8_t EnvelopeTable[ENVELOP_LEN];

#ifdef RUN_TEST
extern Synthesizer synthForC;
#endif

extern Synthesizer synthForAsm;
#else
.extern	EnvelopeTable
.extern synthForAsm
#endif

#ifdef __cplusplus
} //end extern "C"
#endif
#endif