; Ultrasonic.inc
; 
; Prof. Allen
; Library implements measurements from an Ultrasonic sensor
;
; GPIO Pins - modify as needed
;   Example uses Port-D pins 0, 2, and 3
.equ USDir  = DDRD				        ; data direction register for US pins
.equ USOut  = PORTD				        ; output register for US pins
.equ USIn   = PIND				        ; input register for US pins
.equ USTrig = 6					        ; trigger pin for starting a measurement
.equ USEcho = 7					        ; echo pin signals completion of a measurement
;
; 
; Call UltrasonicInit from your main to setup the GPIO for the US
;      Uses GPIO Port/Pins defined above
;      Uses Timer2
; call UltrasonicCycle to take a measurement
;      returns distance in whole inches in GPR R0
; ---------------------------------------------------------

; Configure GPIO for the Ultrasonic sensor pins
; ---------------------------------------------------------
UltrasonicInit:

          sbi       USDir,USTrig        ; set trigger output
          cbi       USOut,USTrig        ; set trigger off (low)
									    
          cbi       USDir,USEcho        ; set echo input
          cbi       USOut,USEcho        ; high-impedance
	      
          ret

; Start a new measurement cycle
; @return R0 - measurement in inches
; ---------------------------------------------------------
UltrasonicCycle:
          clr       r0                  ; inch counter
     
          call      UltrasonicTrigger


SCycleStart:                            ; wait for echo pin to go high
          sbis      USIn,USEcho
          rjmp      SCycleStart        ; cycles started


    ;      sbis USIn, USEcho
     ;     dec r16
      ;    brne SCycleStart
       ;   rjmp USCycleRet


USCycleEcho:                		    ; while (echo high) {
          sbis      USIn,USEcho         ;   if (echo low) 
          rjmp 	    USCycleRet          ;       break
                   
                ;   else
          call      UltrasonicTimer     ;       wait 148us
          inc  	    r0                  ;     add 1 inch

 
                                        ;       
          breq 	    USCycleRet          ;     if (overflow)
                                        ;           break
          rjmp 	    USCycleEcho         ; } 
 
USCycleRet:
          ret                                 ; R0


; Send a 10us pulse on the trigger pin to start a new 
; timing cycle
; 10us / (1/16MHz) / 5cycles = 32
; ---------------------------------------------------------
UltrasonicTrigger:
          clr       r16
          cbi       USOut,USTrig
          nop                           ; 1 cycle
          nop                           ; 1 cycle
          sbi       USOut,USTrig        ; set trigger pin high
			       
          ldi       r16,32              ; 32 * 5
USTriggerWait:
          nop                           ; 1 cycle
          nop                           ; 1 cycle
          dec       r16                 ; 1 cycle
          brne      USTriggerWait       ; 2 cycle
			         
          cbi       USOut,USTrig        ; clear trigger pin low
	      
          ret     

; Measurement timer 148us/inch
; ---------------------------------------------------------
UltrasonicTimer:
          clr       r20
          sts       TCNT2,r20           ; clear counter
			        
          ldi       r20,36
          sts       OCR2A,r20           ; 148us @ clk/64
			        
          ldi       r20,(1<<WGM21)
          sts       TCCR2A,r20          ; ctc mode
			        
          ldi       r20,(1<<CS22)
          sts       TCCR2B,r20          ; clk/64

USTimerWait:
          sbis      TIFR2,OCF2A         ; wait for match
          rjmp      USTimerWait
			        
          sbi       TIFR2,OCF2A         ; reset flag
			        
          clr       r20
          sts       TCCR2B, r20         ; stop timer    
         
          ret
     