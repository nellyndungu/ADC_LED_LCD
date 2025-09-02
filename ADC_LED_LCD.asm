;
; ADC-LED-LCD.asm
; Author : NELLANJIMMS
;
.include "m328pdef.inc"

.cseg
.org  0x0000		;Reset system vector
rjmp  start


start:
	;LED output 
	ldi  r16, (1<<PORTB0) |(1<<PORTB1)
	out  DDRB, r16
    ;Initialize/set-up the ADC
	ldi  r16, (1<<REFS0) | (1<<ADLAR) 
	sts	 ADMUX, r16			;AVcc with external capacitor, left adjusted
	ldi  r16, (1<<ADEN) | (1<<ADPS2) | (1<<ADPS1)| (1<<ADPS0)
	sts  ADCSRA, r16		;Enable ADC, prescaler=128
	sei						;Enable global interrupts

ADC_conversion: 
	ldi  r16, (1<<ADSC)
	sts  ADCSRA, r16		;Start conversion
	rjmp ADC_wait

ADC_wait: 
	sbi  PORTB, 0			;Turn on LED to indicate checking complete convesion
	call delay_short
	lds  r16, ADCSRA
	sbrs r16, 4
	rjmp ADC_wait			;Check if ADIF=set/ conversion complete
	cbi  PORTB, 0
	sbi  PORTB, 1			;Show end of conversion
	call delay_short
	lds  r17, ADCH			;Read higher bytes of conversion
	lds  r18, ADCL			;Read lower bytes of conversion
	cbi  PORTB, 1
	rjmp ADC_conversion

delay_short:
	ldi  r19, 255
lp1: 
	ldi  r20, 200
lp2: 
	dec  r19
	brne lp2
	dec  r20
	brne lp1
	ret
