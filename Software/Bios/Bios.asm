;************************************************************************************
;*																					*
;*								VMC Bios for Rev 1									*
;*																					*
;*		By Jake Donovan			started on 1/3/2024									*
;*																					*
;************************************************************************************

; features
;
; --------hardware---------
;




























;************************************
;*				Memory				*
;************************************
ZP_Math_1
ZP_Math_2
ZP_INT_BSR_MIRROR
ZP_INT_TIE_MIRROR
ZP_INT_SCRATCH_1
ZP_Pointer_LSB
ZP_Pointer_MSB
ZP_Interupt_Stat					; b7= timer







;************************************
;*				Main  				*
;************************************

entrypoint:	
SEI
LDA B_INT


; write control word to prevent out from going low


; ======Video=====
; 
; Set mode 
;				(initiallize screen to specific settings
; chram copy
;		 point to a location and copy into chram at a specific location in chram. 
;		header is optional, compression is optional (likely rle)
; smooth scroll
; 		vertical and horizontal. will need to be called once per frame
;		https://www.cpcwiki.eu/index.php/Programming:Hardware_scrolling_the_screen_using_the_CRTC
; vid bank swap CPU
;		switches what bank is visible to cpu. currently only vram, can be updated to include chram
; vid bank swap crtc
;		same as above, just for crtc
;

; ======Keyboard=======
; readkey
;		read currently pressed key, not irq
;
; ======timer=====
; Timer setup
;	 	enable, and start timer of certain length
B_TIME_Delay ; start delay with LSB of A and MSB of X cycles. returns 5 cycles into the count due to the RTS instruction. 
			;39 cycles 19.5 us @2mhz  (+ 10 cycles to set up 5us @2mhz for a total of 24.5us)
	PHA   					;3
	LDA #b00110000			;2
	STA R_TIME_CTRL			;4
	ROR ZP_INT_TIE_MIRROR	;5
	SEC						;2
	ROL ZP_INT_TIE_MIRROR	;5
	PLA						;4
	STA R_TIME_0			;4
	STX R_TIME_0			;4
	RTS						;6
	

; pulse
;		specifiy frequency and period for one or both channels
; pulse mute
;		mute one or both channels
;
;
; ======Serial=======
B_COMM_RX_Char: ;Receives Character in A register. Clobbers Carry: Carry Set when succsessful, CLeared when failed
	LDA R_COMM_LINE_STAT
	ROR
	BCS OK
	RTS
@OK:	
	LDA R_COMM_TXRX
	RTS

; rx n char
;		 recive n charecters, destination set in command or from table
B_COMM_RX_Str: ;Recives String From ZP_Pointer with Offset of A. terminates on Nul or CR. returns with length in A register
@Loop:
	PHY
	PHX
	LDX #$00
	TAY
	LDA R_COMM_LINE_STAT
	ROR
	BCC Loop
	LDA R_COMM_TXRX
	STA (ZP_Pointer_LSB), Y
	BEQ Done
	CMP #$0d
	BEQ Done
	INY
	INX
	BRA Loop
@Done:
	TXA
	PLX
	PLY
	RTS
	

	
	
@End:

B_COMM_TX_Char: ;sends Character in A register. Clobbers Carry: Carry Set when succsessful, Cleared when failed
	;check serial status
	BIT R_COMM_LINE_STAT
	BVS OK ;full
	CLC
	RTS
@OK:
	STA R_COMM_TXRX
	SEC
	RTS
	
; tx n char
;		send n char from location specified in command or in table

B_COMM_TX_Str ; terminates on 0
	PHY
	TYA
@Loop:
	LDA (ZP_Pointer_LSB), Y
	BEQ End
@Loop2:
	BIT R_COMM_LINE_STAT
	BVC	Loop2 ;full
	STA R_COMM_TXRX
	INY
	BRA Loop
	
@End:
	PLY
	RTS
	
B_COMM_Set_Speed: 	;Sets speed based on value A in table. if Carry Clear and A=/=FF, value larger than table
	PHX				;If Carry Clear and A=FF, Speed not possible. If Carry Set, sucsessful
	TAX
	CMP #18 ;Value should be length of table.
	BCS @BAD
	LDA #$FF ;Check if speed is invalid
	CMP COMM_Speed_Low, X
	BNE @OK
	CMP COMM_Speed_Hi, X
	BNE @OK
	CLC
@BAD:
	RTS
@OK:
	LDA #$80
	ADC R_COMM_LINE_CTRL
	STA R_COMM_LINE_CTRL
	LDA COMM_Speed_Low, X
	STA R_COMM_DIV_LSB
	LDA COMM_Speed_Hi, X
	STA R_COMM_DIV_MSB
	LDA R_COMM_LINE_CTRL
	SEC
	SBC #$80
	STA R_COMM_LINE_CTRL
	PLX
	RTS
		

COMM_Speed_Low: .byte	$00, $00, $17, $59, $00, $80, $C0, $60, $40, $3A, $30, $20, $18, $10, $0C, $06, $03, $02
COMM_Speed_Hi 	.byte	$08, $06, $04, $03, $03, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
;Kb/s 					.05, .075, .11, .1345, .15, .3, .6, 1.2, 2.0, 2.4, 2.8, 3.6, 4.8, 7.2, 9.6, 19.2, 38.4, 56 

; flow control settings
; fifo setings

; =====i2c=====
; 			A=ID X=Register Y=Value  
;			SCL=PB6 SDA=PB7
;			Access DDRB, Write b00000000. Access read, Write b00000100
;			Send 0 when Output, send 1 when input (opposite to DDR)
I2C_Init:
	STA ZP_INT_SCRATCH_1
	ROR 
	CLC
	ROL
	PHA
	LDA #b00000100 			;Access R/W @ R_PIA_I2C
	STA R_PIA_I2C_CTRL 	
	STZ R_PIA_I2C			;set all pins to output 0 when in Output mode)
	STZ R_PIA_I2C_CTRL		;Access DDR @ R_PIA_I2C
	PLA
I2C_Main:
	JSR I2C_Start
	PHX						;ID Byte
	JSR I2C_Write
	JSR I2C_Read_Ack
	PLA
	JSR I2C_Write			;Register location
	JSR I2C_Read_Ack
	ROR ZP_INT_SCRATCH_1	;Check if Read or Write
	BCS @Read
	TYA						;Byte to write
	JSR I2C_Write
	JSR I2C_Read_Ack
	JSR I2C_Stop
	RTS
@Read:	
	ROL ZP_INT_SCRATCH_1						; Might move to before branch, depends on timing
	LDA ZP_INT_SCRATCH_1
	JSR I2C_Start
	JSR I2C_Write
	JSR I2C_Read_Ack
	JSR I2C_Read
	PHA
	LDA #$00
	JSR I2C_Write_Ack
	PLA
	JSR I2C_Stop
	


I2C_Start:
	PHA
	LDA #b00000000			;SDA Hi SCL Hi
	STA R_PIA_I2C
	LDA #b10000000			;SDA Hi SCL Lo
	STA R_PIA_I2C
	LDA #b11000000			;SDA Lo SCL Lo
	STA R_PIA_I2C
	PLA
	RTS

I2C_Ack_Nack_Write: ;LDA #$00 for Ack, LDA #$01 for Nack
	LDX #$01
	.byte $2C	;Bit trick to Skip LDX $#08
I2C_Write:
	LDX #$08
@Loop:
	ASL						;Shift current bit to send into carry
	PHA
	BCC @I2C_Write_0		;Checks what the current bit is
@I2C_Write_1:
	LDA #b01000000 			;SDA Hi SCL Lo
	STA R_PIA_I2C
	LDA #b00000000			;SDA Hi SCL Hi
	STA R_PIA_I2C
	;Add wait?
	LDA #b01000000 			;SDA Hi SCL Lo
	STA R_PIA_I2C
	BRA @Skip
@I2C_Write_0:
	LDA #b11000000 			;SDA Lo SCL Lo
	STA R_PIA_I2C
	LDA #b10000000			;SDA Lo SCL Hi
	STA R_PIA_I2C
	;Add wait?
	LDA #b11000000 			;SDA Lo SCL Lo
	STA R_PIA_I2C
@Skip:
	PLA
	DEX
	BNE Loop
	RTS
	
;I2C_Ack_Read:
;	PHA
;	STZ R_PIA_I2C
;	LDA #b00000100
;	STA R_PIA_I2C_CTRL
;	BIT R_PIA_I2C
;	;ADD wait?
;	BNE ACK
	;make it obv that NACK
;@ACK
;	STZ R_PIA_I2C_CTRL
;	RTS
	
I2C_Read_Ack
	LDX #$01
	.byte $2C ;bit trick
I2C_Read:
	LDX #$08
@Loop:
	PHA
	LDA #b01000000			;Here, Setting Clock to Lo and SDA to 1 (unasserted)
	STA R_PIA_I2C
	STZ R_PIA_I2C			;Clock is now Hi
	LDA #b00000100			;Access R/W @ R_PIA_I2C
	STA R_PIA_I2C_CTRL
	; add wait?
	PLA
	BIT R_PIA_I2C			;Check SDA
	BNE I2C_Read_0
@I2C_Read_1:
	SEC
	.byte #$24
@I2C_Read_0:
	CLC
	ROL 					
	STZ R_PIA_I2C_CTRL		;Access DDR @ R_PIA_I2C
	PHA
	LDA #b01000000
	STA R_PIA_I2C			
	DEX
	BNE Loop
	RTS
	
; ======clock======
; set cpu speed
; set video speed (might not be its own thing due to trying to avoid doing that)
; set clk2 speed

;************************************
;*			Bankswitching			*
;************************************
B_BANKSW_RAM: 	;changes bank to bank selected in A. Carry Cleared if invalid bank selected
	CMP #$04 ;check if bank invalid
	BCC @OK
	RTS
@OK:
	ROL
	ROL
	PHA
	LDA #b11110011
	AND ZP_INT_BSR_MIRROR
	PLA 
	CLC
	ADC ZP_INT_BSR_MIRROR
	STA ZP_INT_BSR_MIRROR
	STA R_BANK_SEL
	SEC
	RTS
B_BANKSW_VRAM: 	;changes bank to bank selected in A. Carry Cleared if invalid bank selected
	CMP #$04 ;check if bank invalid
	BCC @OK
	RTS
@OK:
	JSR B_Nybble_Swap
	PHA
	LDA #b11001111
	AND ZP_INT_BSR_MIRROR
	PLA 
	CLC
	ADC ZP_INT_BSR_MIRROR
	STA ZP_INT_BSR_MIRROR
	STA R_BANK_SEL
	SEC
	RTS
	
B_BANKSW_V/CHRAM: 	;VRAM if A=0, CHRAM if A=1
	CMP #$02
	BCC @OK
	RTS
@OK:
	ROR
	ROR
	PHA
	LDA #b01111111
	AND ZP_INT_BSR_MIRROR
	PLA
	ADC ZP_INT_BSR_MIRROR
	STA ZP_INT_BSR_MIRROR
	STA R_BANK_SEL
	SEC
	RTS
	
B_BANKSW_CHRAM: 	;changes bank to bank selected in A. Carry Cleared if invalid bank selected
	CMP #$02
	BCC @OK
	RTS
@OK:
	ROR
	ROR
	ROR
	PHA
	LDA #b10111111
	AND ZP_INT_BSR_MIRROR
	PLA
	ADC ZP_INT_BSR_MIRROR
	STA ZP_INT_BSR_MIRROR
	STA R_BANK_SEL
	SEC
	RTS	
	
B_BANKSW_ROM:		;set 0 to enable rom; b0 = High Rom, b1 = Low Rom
	CMP #$04
	BCC @OK
	RTS
@OK:
	PHA
	LDA #b11111100
	AND ZP_INT_BSR_MIRROR
	PLA
	ADC ZP_INT_BSR_MIRROR
	STA ZP_INT_BSR_MIRROR
	STA R_BANK_SEL
	SEC
	RTS	


;************************************
;*			Local Routine 			*
;************************************
; ======8bit======
.scope
B_Mult_8:  ;ZP_Math_1 is multiplied by ZP_Math_2.
		    ;Answer is LE word in ZP_Math_1 and ZP_Math_2
			;Loop from Leif Stensson
PHA
PHX
LDA #0
LDX #$8
LSR ZP_Math_1
@Loop:
BCC no_add
CLC
ADC ZP_Math_2
@no_add:
ROR
ROR ZP_Math_1
DEX
BNE Loop
STA ZP_Math_2
PLX
PLA
RTS

.endscope

.scope
B_Div_8	;ZP_Math_1 is divided by ZP_Math_2
		;Quotient in ZP_Math_1, Remainder in ZP_Math_2
		;from http://6502org.wikidot.com/software-math-intdiv, slightly modified by me
PHA
PHX
LDA #0
LDX #$8
ASL ZP_Math_1
@Loop:
ROL
CMP ZP_Math_2
BCC no_sub
SBC ZP_Math_2
@no_sub:
ROL ZP_Math_1
DEX
BNE Loop
STA ZP_Math_2
PHX
PHA
RTS

B_Nybble_Swap ; by David Galloway
	ASL
	ADC #$80
	ROL
	ASL
	ADC #$80
	ROL
	RTS
;
;  ======16bit======
; 
;   16bit add/sub
;   16bit multiply
;   16bit divide
;
; =======data tools=======
; rle encode
; rle decode
; lzs encode
; lzs decode
;  copy
; ROM UPDATE
;
; =======system info=======
B_VER:		;returns computer version and bios version in A register, $FF reserved
LDA #$00
RTS
;0=VMC Rev 1
;0= bios major Rev 1

;************************************
;*				PANIC				*
;************************************

;future routine when something crashes or goes wrong
;will provide register, stack, zp and internal values. will also include entry reason


;************************************
;*				IRQ 				*
;************************************

;priority
;1. timing
;2. serial
;3. i2c/gpio
;4. joy
;5. external

.scope
IRQ_Entrypoint:
PHA
LDA ZP_INT_TIE_MIRROR ; start checking timer irq
LSR
BCC NotTimer
LDA #b11100010
STA R_TIME_CTRL
BIT R_TIME_0
BNE NotTimer
IRQ_Timer ; done in line for speed reasons. 49 cycles 24.5 us response
LDA #b11111110
AND ZP_INT_TIE_MIRROR
STA ZP_INT_TIE_MIRROR
LDA #$80
STA	ZP_Interupt_Stat
PLA
RTI
NotTimer: ; Check timer
PHX
PHY
LDA R_COMM_IRQ_STAT
LSR
BCC IRQ_COMM
NotComm:
BIT R_PIA_GPIO_CTRL
BCS IRQ_GPIO_A
BVS IRQ_GPIO_B
BIT R_PIA_JOY_CTRL
BCS IRQ_KEY
BVS IRQ_TP22
NotPIA:
;write ext later
LDA #$
JSR PANIC
IRQ_Done:
PLY
PLX
PLA
RTI
.endscope





;7 3 2 2 2 4 4 2 2 3 3 2 3 4 6








