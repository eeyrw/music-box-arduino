#ifndef MusicBox_h
#define MusicBox_h

#if ARDUINO >= 100
#include "Arduino.h"
#else
#include "WProgram.h"
#include "pins_arduino.h"
#include "WConstants.h"
#endif

#include <avr/io.h>
#include <stdio.h>
#include <avr/interrupt.h>
#include "Player.h"

class MusicBox
{
public:
  MusicBox();
  void play(const unsigned char *score);
  void stop();
  void process();

private:
  Player mainPlayer;
  bool needHwInit;
};

#endif