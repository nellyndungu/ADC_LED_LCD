# INTEGRATING LCD, LED AND ADC USING ASSEMBLY AND ATMEGA328P
This assembly program:
1. Configures PORTB0 and PORTB1 as outputs (to drive LEDs).
2. Configures the ADC (Analog-to-Digital Converter):
- Reference voltage = AVcc (with external capacitor).
- Left-adjusted result (so ADCH holds the most significant 8 bits).
- ADC enabled with prescaler=128 (slows down ADC clock for accuracy).
3. Enters a loop where:
- It starts an ADC conversion.
- Lights LED on PORTB0 while waiting for conversion to complete.
- When conversion finishes:
    - Turns off LED0.
    - Lights LED on PORTB1 briefly to indicate conversion done.
- Reads the conversion result from ADCH/ADCL registers.
- Clears LED1 and repeats.

Essentially, the program visually shows the ADC conversion status:
- LED0 = “conversion in progress.”
- LED1 = “conversion complete.”

It continuously samples whatever analog input is selected in ADMUX (by default ADC0 / pin PC0 on Arduino Uno).
### Setup
```asm
.include "m328pdef.inc"
.cseg
.org 0x0000       ; Reset vector
rjmp start         ; Jump to program start
```
- Includes the ATmega328P register definitions.
- Puts code at reset vector (address 0).
- Jumps to start label when MCU resets.
### I/O Configuration
```asm
ldi r16, (1<<PORTB0) | (1<<PORTB1)
out DDRB, r16
```
* Loads r16 with binary 0000 0011.
* Writes it to DDRB.
* This makes PB0 and PB1 outputs (LEDs).
```asm
ldi r16, (1<<REFS0) | (1<<ADLAR)
sts ADMUX, r16
```
* REFS0=1 → ADC reference is AVcc.
* ADLAR=1 → Left-adjusts result (so ADCH holds 8 MSBs, easier for 8-bit reads).
* Stores into ADMUX.
```asm
ldi r16, (1<<ADEN) | (1<<ADPS2) | (1<<ADPS1) | (1<<ADPS0)
sts ADCSRA, r16
```
* ADEN=1 → Enables ADC.
* ADPS2:0=111 → Prescaler = 128 (ADC clock = F_CPU / 128).
* At 16 MHz clock → ADC runs at 125 kHz (within recommended 50–200 kHz).
```asm
sei
```
Enables global interrupts (though no ISR is used here — safe but unused).
### START ADC Conversion
```asm
ADC_conversion:
ldi r16, (1<<ADSC)
sts ADCSRA, r16     ; Start conversion
rjmp ADC_wait
```
* ADSC=1 starts a new conversion.
* Immediately jumps to the waiting loop.
### Wait Loop
```asm
ADC_wait:
sbi PORTB, 0        ; LED0 ON → show "conversion in progress"
call delay_short
lds r16, ADCSRA
sbrs r16, 4         ; Skip if ADIF=1
rjmp ADC_wait       ; Stay until conversion complete
cbi PORTB, 0        ; LED0 OFF
```
* Turns LED0 ON while waiting.
* Polls ADCSRA bit 4 (ADIF, ADC interrupt flag).
* Stays in loop until conversion completes.
* Turns LED0 OFF when done.
### End of conversion
```asm
sbi PORTB, 1        ; LED1 ON → show "conversion done"
call delay_short
lds r17, ADCH       ; Read high 8 bits
lds r18, ADCL       ; Read low 8 bits
cbi PORTB, 1        ; LED1 OFF
rjmp ADC_conversion ; Repeat forever
```
- Lights LED1 briefly to indicate conversion finished.
- Reads result:
    - ADCH = high 8 bits (important if left-adjusted).
    - ADCL = low 8 bits.
    - Turns off LED1.
- Goes back to start another conversion.
### Delay Routine
```asm
delay_short:
    ldi r19, 255
lp1:
    ldi r20, 200
lp2:
    dec r19
    brne lp2
    dec r20
    brne lp1
    ret
```
* Nested loops waste CPU cycles → artificial delay.
* Controls LED blink speed.
