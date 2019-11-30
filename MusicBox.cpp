#include "MusicBox.h"

Player *pMainPlayer;

MusicBox::MusicBox()
{
	needHwInit = false;
	pMainPlayer = &this->mainPlayer;
	PlayerInit(&this->mainPlayer, &synthForAsm);
}

void MusicBox::play(const unsigned char *score)
{
	needHwInit = true;
	PlayerPlay(&this->mainPlayer, score);
}

void MusicBox::stop()
{
	cli();
	TIMSK2 &= ~(1 << OCIE2A); //Enable timer interrupt
	sei();
}

void MusicBox::process()
{
	if (needHwInit && mainPlayer.status == STATUS_PLAYING)
	{
		DDRB |= 0b000111;

		TCCR1A = 0b10100001;
		//ICNC1 ICES1 – WGM13 WGM12 CS12 CS11 CS10 ; Fast PWM pclk/1
		TCCR1B = 0b00001001;

		TCCR2A = 0b00000010;
		TCCR2B = 0b00000010;  //pclk/8
		TIMSK2 = 1 << OCIE2A; //Enable timer interrupt
		OCR2A = 62;			  //Initalize TC0 in 32 kHz interval timer ( pclk=16M )
		needHwInit = false;
		sei();
	}
	PlayerProcess(&this->mainPlayer);
}
