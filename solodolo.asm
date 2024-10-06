;
; Mark_John.asm
;
; Author : Mark Schwartz, John Holik and Ryley Wright
;

; new timer
.equ DELAY_CNT = 34286
 
.equ DELAY_S = 8

.org 0x0000
          jmp       main

.org INT0addr                           ; Ext Int 0 for Blue LED Button
          jmp       blue_led_btn_ISR

#include "Ultrasonic.inc"

; ------------------------------------------------------------
main:
; main application method
;         one-time setup & configuration
; ------------------------------------------------------------
       
          ; Place 1-time setup code here
          sbi       DDRB, DDB3          ; setting first LED pin to output (pin 11)
          cbi       PORTB, PB3          ; turn first LED off (pin 11)

          sbi       DDRB, DDB0          ; setting second LED pin to output (pin 8)
          cbi       PORTB, PB0          ; turn second LED off (pin 11)

          sbi       DDRB, DDB1          ; configuring third LED to output (pin 9)
          cbi       PORTB, PB1          ; turn third LED off (pin 9)

          sbi       DDRD, DDD3          ; setting Buzzer to output (pin 3)
          cbi       PORTD, PD3          ; turn Buzzer off (pin 3)

          cbi       DDRD,DDD2           ; set arm/disarm button to input (d2)
          sbi       PORTD,PD2           ; engage pull-up mode
          sbi       EIMSK,INT0          ; enable interrupt 0 for arm/disarm button
          ldi       r20,0b00000010      ; set falling edge sense bits for ext int 0
          sts       EICRA,r20

          ldi       r23, 0              ; using this to check and toggle modes on button press

          sei                           ; enable interrupts
          call      UltrasonicInit      ; setup the motion sensor



main_loop:
          ; Measure distance
          call      delay_ms
          cbi       PORTB, PB0
          cbi       PORTB, PB1
          cbi       PORTB, PB3
          cbi       PORTD, PD3
             
          call      UltrasonicCycle
          clr       r30
          mov       r30, r0             ; Move distance measurement to register r30
    
    ; perform checks on the distances and toggle respective lights
          cpi       r30, 4                
          brlt      two_inches          ; if distance < 4 inches, turn all 3 on 

          cpi       r30, 8
          brlt      four_inches         ; if distance < 8 inches, turn 2 led on
  
          cpi       r30, 10
          brlt      six_inches          ; If distance is less than 10 inches (this is the furthest range our hypothetical system will
                                        ; turn a light on for), turn one LED on
          
          rjmp      continue_loop       ; Continue the loop

six_inches:
          sbi       PORTB, PB3          ; Turn one LED on 
          sbi       PORTD, PD3          ; turn buzzer on
          call      delay_ms
          call      delay_ms          
          cbi       PORTD,PD3           ; turn buzzer off
          call      delay_ms
          call      delay_ms
          rjmp      continue_loop

four_inches:                            ; turn two LEDs on
          sbi       PORTB, PB3         
          sbi       PORTB, PB0        
          sbi       PORTD,PD3           ; turn buzzer on
          call      delay_ms            ; sleep
          cbi       PORTD, PD3          ; turn buzzer off
          call      delay_ms            ; sleep
          rjmp      continue_loop

two_inches:                             ; turn 3 LEDs on
          sbi       PORTB, PB3         
          sbi       PORTB, PB0         
          sbi       PORTB, PB1  
          call      delay_tm1  
          sbi       PORTD, PD3          ; Turn Buzzer on
          rjmp      continue_loop

continue_loop:   
          rjmp      main_loop           ; Repeat the main loop indefinitely

; external interrupt for arm/disarm button button
blue_led_btn_ISR:
          cpi       r23, 1              ; check if the mode was 'on' when the button was pressed
          breq      disable_system      ; if it was, go here to disable the system
          sbi       PORTB, PB5          ; else, turn on light and motion sensor system
                                        
          sbi       DDRD,6              ; set trigger output
          cbi       PORTD,6             ; set trigger off (low)
          cbi       DDRD,7              ; set echo input
          cbi       PORTD,7             ; high-impedance

          ldi       r23,1               ; and toggle this register to indicate new mode
          reti

disable_system:                         ; turn off security system if it was on when button was pressed
          ldi       r23, 0              ; toggle to update that system is now off

  ; this section disables the motion sensor as to disable the system
          cbi       DDRD,6              ; Set trigger pin as input
          cbi       PORTD,6             ; Disable pull-up on trigger pin
    
          cbi       DDRD, 7             ; Set echo pin as input
          cbi       PORTD, 7            ; Disable pull-up on echo pin
  
          cbi       PORTB, PB5
          reti


    ; Timer1 has reached the compare match value
          ret

delay_ms:
; creates a timed delay using multiple nested loops
; ------------------------------------------------------------
          ldi       r18,DELAY_S
delay_ms_1:

          ldi       r17,200
delay_ms_2:

          ldi       r16,250
delay_ms_3:
          nop
          nop
          dec       r16
          brne      delay_ms_3          

          dec       r17
          brne      delay_ms_2          

          dec       r18
          brne      delay_ms_1          
dealy_ms_end:
          ret


; ------------------------------------------------------------
delay_tm1:
; creates a timed delay using timer1
; ------------------------------------------------------------
          ; set timer counter
          ldi       r19, HIGH(DELAY_CNT)
          sts       TCNT1H, r19
          ldi       r19, LOW(DELAY_CNT)
          sts       TCNT1L, r19

          clr       r19                 ; set to normal mode
          sts       TCCR1A, r19

          ldi       r19, (1<<CS12)    ; normal mode, clk/256
          sts       TCCR1B, r19         ; clock is started

delay_tov1:        
          sbis      TIFR1, TOV1        ; wait for timer1 overflow flag, once that happens, the below instruction will be skipped and we leave the loop 

          clr       r19
          sts       TCCR1B, r19         ; stop the timer

          sbi       TIFR1, TOV1         ; write 1 to reset overflow flag (set a 1 to this <- register at that -> bit)
          ldi       r19,0
          sts       TCNT1H, r19          
          sts       TCNT1L, r19
          ret