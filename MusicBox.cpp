#include "MusicBox.h"

Player *pMainPlayer;

MusicBox::MusicBox()
{
}

void MusicBox::init()
{
	PORTB = 0b001101; //Initalize Port B
	DDRB = 0b000111;
	pMainPlayer = &this->mainPlayer;

	PlayerInit(&this->mainPlayer,&synthForAsm);
}

void MusicBox::play(const unsigned char *score)
{
	DDRB |= 0b000110;

	TCCR1A = 0b10100001;
	//ICNC1 ICES1 – WGM13 WGM12 CS12 CS11 CS10 ; Fast PWM pclk/1
	TCCR1B = 0b00001001;

	OCR0A = 62; //Initalize TC0 in 32 kHz interval timer ( pclk=16M )
	TCCR0A = 0b00000010;
	TCCR0B = 0b00000010;  //pclk/8
	TIMSK0 = 1 << OCIE0A; //Enable timer interrupt

	PlayerPlay(&this->mainPlayer, score);
	sei();
}

void MusicBox::stop()
{
	cli();
	TIMSK0 &= ~(1 << OCIE0A); //Enable timer interrupt
	sei();
}

void MusicBox::process()
{
	PlayerProcess(&this->mainPlayer);
}
