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
;*				Main  				*
;************************************
Entrypoint_Warm:
	JMP Mon
Entrypoint:	
	SEI
	LDA #$C1		;Clock gen id read
	LDX #03
	JSR B_I2C
	ROR
	ROR
	BCC Entrypoint_Warm
Entrypoint_Cold:
	LDX #$FF
	TXS				;Init Stack Pointer
	STX R_PIA_GPIO		;Init Gpio to output POSTCODE
	LDA #%00000100
	STA R_PIA_GPIO_CTRL
	STA R_BANK_SEL	;Conviniently dont have to load a different value
	INC R_PIA_GPIO		;DEBUG 01
Entrypoint_Cold_Serial_Setup:	;sets serial to 9600 8 E 1
	LDA #%00001011	;DIV_LATCH enable, No tx break, no force parity, Even parity, Yes B_Parity, 1 stop bit, 8 bit word
	STA R_COMM_LINE_CTRL
	LDA #14
	JSR B_COMM_Set_Speed
	INC R_PIA_GPIO		;DEBUG 02
	LDA #%00000111
	STA R_COMM_FIFO_CTRL
	LDA #%00100010
	STA R_COMM_MODM_CTRL
	INC R_PIA_GPIO		;DEBUG 03
	LDX #$00
	LDY #$00
	LDA #$5A
Entrypoint_MEMTEST_ZP: ;tests zp with patterns $5A $A5 $FF $00, also indirectly clears memory by filling  w/ $00 last
@Loop_STA:
	STA $00, X
	INX
	BNE @Loop_STA	;done storing set value
@Loop_CMP:
	CMP $00, X
	BNE @Error
	INX
	BNE @Loop_CMP
	INY
	CMP #$04		
	BEQ Entrypoint_MEMTEST_ZP_Done
	LDA Entrypoint_MEMTEST_Values, Y
	BRA Entrypoint_MEMTEST_ZP
@Error:
			;will write later

Entrypoint_MEMTEST_ZP_Done:		;Prints RamCount and ZP_ok prompt
	INC R_PIA_GPIO		;Debug 04
	LDA #<Entrypoint_Memtest_Splash
	STA ZP_Pointer1_LSB
	LDA #>Entrypoint_Memtest_Splash
	STA ZP_Pointer1_MSB
	JSR B_COMM_TX_Str
	LDA #$00
	JSR	Entrypoint_MEMTEST_Print_B_Page
	LDX #01
	LDY #03
	JSR B_COMM_MoveCsr
	LDA #<Entrypoint_MEMTEST_Prompt_zp
	STA ZP_Pointer1_LSB
	LDA #>Entrypoint_MEMTEST_Prompt_zp
	STA ZP_Pointer1_MSB
	JSR B_COMM_TX_Str
	INC R_PIA_GPIO		;Debug 05
	LDA #%00000100				;Set ram bank to 1 for ram test
	STA ZP_INT_BSR_MIRROR
	STA R_BANK_SEL
	LDA $01
	STA ZP_Pointer1_MSB
	STZ ZP_Pointer1_LSB
	LDA #$5A
	LDY #$00
	LDX #$00
Entrypoint_MEMTEST:
@Loop_STA:
	STA (ZP_Pointer1_LSB)		
	INC ZP_Pointer1_LSB
	BNE @Loop_STA
@Loop_CMP:
	CMP (ZP_Pointer1_LSB)
	BNE @Error
	INC ZP_Pointer1_LSB
	BNE @Loop_CMP
	INY
	CPY #$04
	BEQ @Entrypoint_MEMTEST_Next_B_Page
@Return:
	LDA Entrypoint_MEMTEST_Values, Y
	BRA Entrypoint_MEMTEST
	
	
@Entrypoint_MEMTEST_Next_B_Page:	;Add offset to RamCount if necisary
	LDA ZP_Pointer1_MSB
	BBR3 ZP_INT_BSR_MIRROR, @No_Add
	CLC
	BBS2 ZP_INT_BSR_MIRROR, @Add_40h
	ADC #$20
	.byte $2C
@Add_40h:
	ADC #$40
@No_Add:
	JSR Entrypoint_MEMTEST_Print_B_Page
	INC ZP_Pointer1_MSB	;check if 
	LDA #$40
	CMP ZP_Pointer1_MSB
	BNE @No_Bankswitch
	STA ZP_Pointer1_MSB
	LDA ZP_INT_BSR_MIRROR
	CLC 
	ADC #%00000100
	CMP #%00010000
	BEQ @Done
	STA ZP_INT_BSR_MIRROR
@No_Bankswitch:
	LDY #$00
	BRA @Return

@Error:
	LDA #$F0
	STA R_PIA_GPIO
	LDX ZP_Pointer1_LSB
	LDY ZP_Pointer1_LSB
	LDA #<Entrypoint_MEMTEST_Prompt_Badram
	STA ZP_Pointer1_LSB
	LDA #>Entrypoint_MEMTEST_Prompt_Badram
	STA ZP_Pointer1_MSB
	JSR B_COMM_TX_Str
	TXA
	JSR B_Data_Hex2ASC
	JSR B_COMM_TX_Char
	TXA 
	JSR B_COMM_TX_Char	
	TYA
	JSR B_Data_Hex2ASC
	JSR B_COMM_TX_Char
	TXA 
	JSR B_COMM_TX_Char
	STP
	
	
@Done:
	INC R_PIA_GPIO		;Debug 06
	LDA #<Entrypoint_MEMTEST_Prompt_ram
	STA ZP_Pointer1_LSB
	LDA #>Entrypoint_MEMTEST_Prompt_ram
	STA ZP_Pointer1_MSB
	LDX #01
	LDY #04
	JSR B_COMM_MoveCsr
	JSR B_COMM_TX_Str
	
Entrypoint_Test_CLK:
	
@Enable_Clk2:
	INC R_PIA_GPIO		;Debug 07
	LDA #$C0		;Clock gen id write
	LDX #03
	LDY #$02 		;Make sure CLK2 is disabled before checking which clock is used by timer
	JSR B_I2C
	LDA #$FF
	TAX
	JSR B_TIME_Delay
	LDA #%11100010	;Readback Status For Counter 0
	STA R_TIME_CTRL
	BIT R_TIME_0
	BVC @Using_CPU_CLK
	LDA #%00000001
	TSB ZP_Bios_Error	;using CLK2
@Using_CPU_CLK:
	LDA #%00110000			;Disable counting
	STA R_TIME_CTRL
	INC R_PIA_GPIO		;Debug 08	
	LDA #$C0		;Start CLK2
	LDX #03
	LDY #$00
	JSR B_I2C
@Check_Bad_Timer:	;if both reads return Null Count, Timer Bad
	LDA #$ff
	TAX
	JSR B_TIME_Delay
	LDA #%11100010	;Readback Status For Counter 0
	STA R_TIME_CTRL
	BIT R_TIME_0
	BVC @Timer_Ok
	LDA #<Entrypoint_Prompt_BadTimer
	STA ZP_Pointer1_LSB
	LDA #>Entrypoint_Prompt_BadTimer
	STA ZP_Pointer1_MSB
	JSR B_COMM_TX_Str
	STP
@Timer_Ok:
	LDA #%00110000
	STA R_TIME_CTRL
	INC R_PIA_GPIO		;Debug 09
	LDA #<Entrypoint_Prompt_Timer_OK
	STA ZP_Pointer1_LSB
	LDA #>Entrypoint_Prompt_Timer_OK
	STA ZP_Pointer1_MSB
	JSR B_COMM_TX_Str
	
Entrypoint_Done:
	JSR B_COMM_ClsScr
	LDA #<Entrypoint_Prompt_Done
	STA ZP_Pointer1_LSB
	LDA #>Entrypoint_Prompt_Done
	STA ZP_Pointer1_MSB
	JSR B_COMM_TX_Str
	JMP Mon
















Entrypoint_MEMTEST_Print_B_Page:
	PHA
	LDX #1
	LDY #2
	JSR B_COMM_MoveCsr
	LDA #$24		;$
	JSR B_COMM_TX_Char
	PLA
	JSR B_Data_Hex2ASC
	JSR B_COMM_TX_Char
	TXA
	JSR B_COMM_TX_Char
	LDA #$30
	JSR B_COMM_TX_Char
	RTS
	
	
Entrypoint_MEMTEST_Values:
.byte $5A, $A5, $FF, $00
Entrypoint_Memtest_Splash:
.asciiz "VMC RomBIOS 1.0\t2024 Jake Donovan\tTurn on local echo!"
Entrypoint_MEMTEST_Prompt_zp:
.asciiz	"ZP OK!"
Entrypoint_MEMTEST_Prompt_ram:
.asciiz "Ram OK!"
Entrypoint_MEMTEST_Prompt_Badram:
.asciiz "Bad Ram @$"
Entrypoint_Prompt_BadTimer:
.asciiz "Bad TIMER"
Entrypoint_Prompt_Timer_OK:
.asciiz "TIMER OK!"
Entrypoint_Prompt_Done:
.asciiz "System Ready"


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
BI_ReadKey:
	PHX
	LDX ZP_Key_Buffer_Read_Pointer
	CPX ZP_Key_Buffer_Pointer
	CLC 
	BNE @OK
	PLX
	SEC
	RTS
@OK:
	LDA $0200, X
	INC ZP_Key_Buffer_Read_Pointer
	RTS
	
	
	
;
; ======timer=====
; Timer setup
;	 	enable, and start timer of certain length
BI_TIME_Delay: ; start delay with LSB of A and MSB of X cycles. returns 5 cycles into the count due to the RTS instruction. 
			;39 cycles  19.5us @2mhz  (+ 10 cycles to set up 5us @2mhz for a total of 24.5us)
	PHA   					;3
	LDA #%00110000			;2
	STA R_TIME_CTRL			;4
	LDA	ZP_INT_TIE_MIRROR	;3
	ORA #%00000001			;2
	STA ZP_INT_TIE_MIRROR	;3
	STA R_TIE				;4
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
BI_COMM_RX_Char: ;Receives Character in A register. Clobbers Carry: Carry Set when succsessful, CLeared when failed
	LDA R_COMM_LINE_STAT
	ROR
	BCS @OK
	RTS
@OK:	
	LDA R_COMM_TXRX
	RTS


BI_COMM_RX_Str: ;Recives String From ZP_Pointer with Offset of A. terminates on Nul or CR. returns with length in A register
@Loop:
	PHY
	PHX
	LDX #$00
	TAY
	LDA R_COMM_LINE_STAT
	ROR
	BCC @Loop
	LDA R_COMM_TXRX
	STA (ZP_Pointer1_LSB), Y
	BEQ @Done
	CMP #$0d
	BEQ @Done
	INY
	INX
	BRA @Loop
@Done:
	TXA
	PLX
	PLY
	RTS
	


BI_COMM_TX_Char: ;sends Character in A register. 
	;check serial status 
	
	BIT R_COMM_LINE_STAT
	BVC BI_COMM_TX_Char ;full
	STA R_COMM_TXRX
	RTS


BI_COMM_TX_Str: ; terminates on 0
	PHY
	TYA
@Loop:
	LDA (ZP_Pointer1_LSB), Y
	BEQ @End
@Loop2:
	BIT R_COMM_LINE_STAT
	BVC	@Loop2 ;full
	STA R_COMM_TXRX
	INY
	BRA @Loop
	
@End:
	PLY
	RTS
	
	
	
BI_COMM_MoveCsr:		;Move cursor to X,Y
	PHA
	LDA #27			;ESC
	JSR B_COMM_TX_Char
	LDA #$5b		;[
	JSR B_COMM_TX_Char
	TXA
	JSR B_COMM_TX_Char
	LDA #$3b		;;
	JSR B_COMM_TX_Char
	TYA
	JSR B_COMM_TX_Char
	LDA #$48		;H
	JSR B_COMM_TX_Char
	RTS
	
BI_COMM_ClsScr:	;VT100 Clear Screen
	PHA
	LDA #<@String
	STA ZP_Pointer1_LSB
	LDA #>@String
	STA ZP_Pointer1_MSB
	JSR B_COMM_TX_Str
	PLA
	RTS
@String:
.asciiz "^[[2J"
	
BI_COMM_Set_Speed: 	;Sets speed based on value A in table. if Carry Clear and A=/=FF, value larger than table
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
	PLX
	RTS
@OK:
	LDA #%10000000
	TSB R_COMM_LINE_CTRL
	LDA COMM_Speed_Low, X
	STA R_COMM_DIV_LSB
	LDA COMM_Speed_Hi, X
	STA R_COMM_DIV_MSB
	LDA #%10000000
	TRB R_COMM_LINE_CTRL
	PLX
	RTS
		

COMM_Speed_Low: .byte	$00, $00, $17, $59, $00, $80, $C0, $60, $40, $3A, $30, $20, $18, $10, $0C, $06, $03, $02
COMM_Speed_Hi: 	.byte	$08, $06, $04, $03, $03, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
;Kb/s 					.05, .075, .11, .1345, .15, .3, .6, 1.2, 2.0, 2.4, 2.8, 3.6, 4.8, 7.2, 9.6, 19.2, 38.4, 56 

BI_COMM_Setup:
BI_COMM_Setup_Fifo:
BI_COMM_Setup_Modm:

; fifo setings

; =====i2c=====
; 			A=ID X=Register Y=Value  
;			SCL=PB6 SDA=PB7
;			Access DDRB, Write b00000000. Access read, Write b00000100
;			Send 0 when Output, send 1 when input (opposite to DDR)
BI_I2C:
	STA ZP_INT_SCRATCH_1
	ROR 
	CLC
	ROL
	PHA
	LDA #%00000100 			;Access R/W @ R_PIA_I2C
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
	JSR I2C_Ack_Nack_Write
	PLA
	JSR I2C_Stop
	RTS
	
	
	


I2C_Start:
	PHA
	LDA #%00000000			;SDA Hi SCL Hi
	STA R_PIA_I2C
	LDA #%10000000			;SDA Hi SCL Lo
	STA R_PIA_I2C
	LDA #%11000000			;SDA Lo SCL Lo
	STA R_PIA_I2C
	PLA
	RTS

I2C_Stop:
	PHA
	LDA #%11000000			;SDA Hi SCL Hi
	STA R_PIA_I2C
	LDA #%10000000			;SDA Hi SCL Lo
	STA R_PIA_I2C
	LDA #%00000000			;SDA Lo SCL Lo
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
	LDA #%01000000 			;SDA Hi SCL Lo
	STA R_PIA_I2C
	LDA #%00000000			;SDA Hi SCL Hi
	STA R_PIA_I2C
	;Add wait?
	LDA #%01000000 			;SDA Hi SCL Lo
	STA R_PIA_I2C
	BRA @Skip
@I2C_Write_0:
	LDA #%11000000 			;SDA Lo SCL Lo
	STA R_PIA_I2C
	LDA #%10000000			;SDA Lo SCL Hi
	STA R_PIA_I2C
	;Add wait?
	LDA #%11000000 			;SDA Lo SCL Lo
	STA R_PIA_I2C
@Skip:
	PLA
	DEX
	BNE @Loop
	RTS
	
;I2C_Ack_Read:
;	PHA
;	STZ R_PIA_I2C
;	LDA #%00000100
;	STA R_PIA_I2C_CTRL
;	BIT R_PIA_I2C
;	;ADD wait?
;	BNE ACK
	;make it obv that NACK
;@ACK
;	STZ R_PIA_I2C_CTRL
;	RTS
	
I2C_Read_Ack:
	LDX #$01
	.byte $2C ;bit trick
I2C_Read:
	LDX #$08
@Loop:
	PHA
	LDA #%01000000			;Here, Setting Clock to Lo and SDA to 1 (unasserted)
	STA R_PIA_I2C
	STZ R_PIA_I2C			;Clock is now Hi
	LDA #%00000100			;Access R/W @ R_PIA_I2C
	STA R_PIA_I2C_CTRL
	; add wait?
	PLA
	BIT R_PIA_I2C			;Check SDA
	BNE @I2C_Read_0
@I2C_Read_1:
	SEC
	.byte $24
@I2C_Read_0:
	CLC
	ROL 					
	STZ R_PIA_I2C_CTRL		;Access DDR @ R_PIA_I2C
	PHA
	LDA #%01000000
	STA R_PIA_I2C	
	PLA	
	DEX
	BNE @Loop
	RTS
	
; ======clock======
; set cpu speed
; set video speed (might not be its own thing due to trying to avoid doing that)
; set clk2 speed

;************************************
;*			Bankswitching			*
;************************************
BI_BANKSW_RAM: 	;changes bank to bank selected in A. Carry Cleared if invalid bank selected
	CMP #$04 ;check if bank invalid
	BCC @OK
	RTS
@OK:
	ROL
	ROL
	PHA
	LDA #%11110011
	AND ZP_INT_BSR_MIRROR
	PLA 
	CLC
	ADC ZP_INT_BSR_MIRROR
	STA ZP_INT_BSR_MIRROR
	STA R_BANK_SEL
	SEC
	RTS
BI_BANKSW_VRAM: 	;changes bank to bank selected in A. Carry Cleared if invalid bank selected
	CMP #$04 ;check if bank invalid
	BCC @OK
	RTS
@OK:
	JSR B_MATH8_Nybble_Swap
	PHA
	LDA #%11001111
	AND ZP_INT_BSR_MIRROR
	PLA 
	CLC
	ADC ZP_INT_BSR_MIRROR
	STA ZP_INT_BSR_MIRROR
	STA R_BANK_SEL
	SEC
	RTS
	
BI_BANKSW_V_CHRAM: 	;VRAM if A=0, CHRAM if A=1
	CMP #$02
	BCC @OK
	RTS
@OK:
	ROR
	ROR
	PHA
	LDA #%01111111
	AND ZP_INT_BSR_MIRROR
	PLA
	ADC ZP_INT_BSR_MIRROR
	STA ZP_INT_BSR_MIRROR
	STA R_BANK_SEL
	SEC
	RTS
	
BI_BANKSW_CHRAM: 	;changes bank to bank selected in A. Carry Cleared if invalid bank selected
	CMP #$02
	BCC @OK
	RTS
@OK:
	ROR
	ROR
	ROR
	PHA
	LDA #%10111111
	AND ZP_INT_BSR_MIRROR
	PLA
	ADC ZP_INT_BSR_MIRROR
	STA ZP_INT_BSR_MIRROR
	STA R_BANK_SEL
	SEC
	RTS	
	
BI_BANKSW_ROM:		;set 0 to enable rom; b0 = High Rom, b1 = Low Rom
	CMP #$04
	BCC @OK
	RTS
@OK:
	PHA
	LDA #%11111100
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

BI_MATH8_Mult:  ;ZP_Math_1 is multiplied by ZP_Math_2.
		    ;Answer is LE word in ZP_Math_1 and ZP_Math_2
			;Loop from Leif Stensson
	PHA
	PHX
	LDA #0
	LDX #$8
	LSR ZP_Math_1
@Loop:
	BCC @no_add
	CLC
	ADC ZP_Math_2
@no_add:
	ROR
	ROR ZP_Math_1
	DEX
	BNE @Loop
	STA ZP_Math_2
	PLX
	PLA
	RTS




BI_MATH8_Div:	;ZP_Math_1 is divided by ZP_Math_2
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
	BCC @no_sub
	SBC ZP_Math_2
@no_sub:
	ROL ZP_Math_1
	DEX
	BNE @Loop
	STA ZP_Math_2
	PHX
	PHA
	RTS

BI_MATH8_Nybble_Swap: ; by David Galloway Affects A
	ASL
	ADC #$80
	ROL
	ASL
	ADC #$80
	ROL
	RTS
;
;  ======16bit======
BI_MATH16_Add:		;Math_1-2 + Math_3-4. Stored In Math_1-2. carry is valid Little Endian
	PHA
	CLC
	LDA ZP_Math_1
	ADC ZP_Math_3
	STA ZP_Math_1
	LDA ZP_Math_2
	ADC ZP_Math_4
	STA ZP_Math_2
	PLA
	RTS
	
BI_MATH16_Sub:		;Math_1-2 - Math_3-4. Stored In Math_1-2. carry is valid Little Endian
	PHA
	SEC
	LDA ZP_Math_1
	SBC ZP_Math_3
	STA ZP_Math_1
	LDA ZP_Math_2
	SBC ZP_Math_4
	STA ZP_Math_2
	PLA
	RTS
	
BI_MATH16_Multi:	;Multiplier in Math 1/2		Multiplicand in 3/4 https://codebase64.org/doku.php?id=base:6502_6510_maths
	PHA				;Answer in Math1-4 
	PHX
	STZ ZP_INT_SCRATCH_3
	STZ ZP_INT_SCRATCH_4
	ldx	#$10		; set binary count to 16 
@shift_r:	
	lsr ZP_Math_2	; divide multiplier by 2 
	ror	ZP_Math_1
	bcc	@rotate_r 
	lda	ZP_INT_SCRATCH_3	; get upper half of product and add multiplicand
	clc
	adc	ZP_Math_3
	sta	ZP_INT_SCRATCH_3
	lda	ZP_INT_SCRATCH_4
	adc	ZP_Math_4
@rotate_r:
	ror			; rotate partial product 
	sta	ZP_INT_SCRATCH_4
	ror	ZP_INT_SCRATCH_3
	ror	ZP_INT_SCRATCH_2 
	ror	ZP_INT_SCRATCH_1
	dex
	bne	@shift_r 
	LDX #$04
@Copy_Loop:
	LDA ZP_INT_SCRATCH_1-1
	STA ZP_Math_1-1
	DEX
	BNE @Copy_Loop
	PLX
	PLA
	rts
	
	
BI_MATH16_Div: 		;Dividend in ZP_Math_1/2	Divisor in ZP_MATH_3/4 https://codebase64.org/doku.php?id=base:6502_6510_maths
	PHA				;Result in Math 1/2 		Remainder in Math 3/4
	PHX
	PHY
	LDA #0	        ;preset remainder to 0
	STA ZP_INT_SCRATCH_1
	STA ZP_INT_SCRATCH_2
	LDA #16	        ;repeat for each bit: ...

@divloop:	
	asl ZP_Math_1	;dividend lb & hb*2, msb -> Carry
	rol ZP_Math_2	
	rol ZP_INT_SCRATCH_1	;remainder lb & hb * 2 + msb from carry
	rol ZP_INT_SCRATCH_2
	lda ZP_INT_SCRATCH_1
	sec
	sbc ZP_Math_3	;substract divisor to see if it fits in
	tay	        ;lb result -> Y, for we may need it later
	lda ZP_INT_SCRATCH_2
	sbc ZP_Math_4
	bcc @skip	;if carry=0 then divisor didn't fit in yet

	sta ZP_INT_SCRATCH_2	;else save substraction result as new remainder,
	sty ZP_INT_SCRATCH_1	
	inc ZP_Math_1	;and INCrement result cause divisor fit in 1 times

@skip:
	dex
	bne @divloop
	LDA ZP_INT_SCRATCH_1
	STA ZP_Math_3
	LDA ZP_INT_SCRATCH_2
	STA ZP_Math_4
	PHY
	PLX
	PLA
	rts
; =======data tools=======
BI_DATA_RLE_Encode:
STP
BI_DATA_RLE_Decode:
.INCLUDE		"../RLE/RLE.asm"
BI_DATA_LZS_Encode:
BI_DATA_LZS_Decode:
STP
BI_DATA_Copy:	 ;Copies Data From ZP_Pointer1 to ZP_Pointer2 with a length of XY
	PHA
@Loop:
	LDA (ZP_Pointer1_LSB)
	STA (ZP_Pointer2_LSB)
	INC ZP_Pointer1_LSB
	INC ZP_Pointer1_LSB
	DEY
	BNE @Loop
			;Decrease high byte
	CPX #$00
	BEQ @Done
	INC ZP_Pointer1_MSB
	INC ZP_Pointer2_MSB
	DEX
	BRA @Loop
@Done:
	PLA
	
	
BI_DATA_EEPROM_Write: 	;Copy from Pointer1 to Pointer2 with length of XY little edian
	STP
	PHA
	STX ZP_INT_SCRATCH_1	;copy length to Temp var
	STY ZP_INT_SCRATCH_2	
	LDA #$00
	JSR B_BANKSW_ROM		;Make sure all rom is accsesable
	LDA #$AA				;Start with unlock
	STA $D555
	LDA #$55
	STA $AAAA
	LDA #$80
	STA $D555
	LDA #$AA				
	STA $D555
	LDA #$55
	STA $AAAA
	LDA #$20
	STA $D555				;Unlock Done
@Copy:
	LDA (ZP_Pointer1_LSB)
	STA (ZP_Pointer2_LSB)
	CMP (ZP_Pointer2_LSB)
	
	
	
	
	
	
	
@Lock:
	LDA #$AA				;Relock EEPROM
	STA $D555
	LDA #$55
	STA $AAAA
	LDA #$A0
	STA $D555
	PLA
	RTS

BI_DATA_EEPROM_Write_Page: 	;Copy from Pointer1+30h to Pointer2 with length of X (Max 64
	STP						;Pointer1 is location to copy program to
	PHA						;30h in length 			will need to be copyable into ram, 
	LDA #$00
	JSR B_BANKSW_ROM	
	LDA #$AA				;Unlock for page
	STA $D555
	LDA #$55
	STA $AAAA
	LDA #$A0
	STA $D555 				;Begin write page
@Loop:						;41 cycle: 20.5 us time @2mhz (cpuclk must be >.3mhz
	LDA (ZP_Pointer1_LSB)	;5
	STA (ZP_Pointer2_LSB)	;5
	DEX						;2
	BNE @Done				;2
	INC ZP_Pointer1_LSB		;5
	BNE @MSB_INC_SKIP_1		;2
	INC ZP_Pointer1_MSB		;5
@MSB_INC_SKIP_1:
	INC ZP_Pointer1_LSB		;5
	BNE @MSB_INC_SKIP_2		;2
	INC ZP_Pointer1_MSB		;5
@MSB_INC_SKIP_2:
	BRA @Loop				;3

@Done:
	CMP (ZP_Pointer2_LSB)	;Check to see if write is done
	BNE @Done
	PLA
	RTS
	
BI_Data_Hex2ASC: ;A in, A hi nybble X lo Nybble
	CLD
	PHY
	TAY
	AND #%00001111
	CMP #$0A
	BCC @Nums
	CLC
	ADC #$37
.byte $2C
@Nums:
	ADC #$30
	TAX
	TYA
	AND #%11110000
	ROR
	ROR
	ROR
	ROR
	CMP #$0A
	BCC @Nums2
	CLC
	ADC #$37
.byte $2C
@Nums2:
	ADC #$30
	PLY
	RTS
	

;
; =======system info=======
BI_VER:		;returns computer version and bios version in A register, $FF reserved
	LDA #$00
	RTS
;0=VMC Rev 1
;0= bios major Rev 1

;************************************
;*				PANIC				*
;************************************

;future routine when something crashes or goes wrong
;will provide register, stack, zp and internal values. will also include entry reason


;routine that clobbers mem
B_Panic:
	STA $0200 ;A
B_Panic_Get_P_No_PHP: ;44 bytes
	BMI @N		;If no branch, /N
		BEQ @notNZ		
			LDA #%00000000 ; /N/V/Z
			BRA @Done
			@notNZ:
			LDA #%00000010
			BRA @Done
	@N:
		BEQ @NZ		
			LDA #%10000000 ; /N/V/Z
			BRA @Done
			@NZ:
			LDA #%10000010
			BRA @Done
@Done:
B_Panic_Get_Registers:
	STA $0204	;partial P
	STX $0201	;X
	STY $0202	;Y
	TSX
	STA $0203	;SP
	PLX
	PHP
	PLY
	PHX
	LDA $0204
	STY $0204
	TAY
	LDA #%10000010
	TRB $0204
	TYA
	TSB $0204	;P
	CLD
B_Panic_Send_Prompt:
	LDX #$00
	LDA B_Panic_Prompts, X
	BEQ @Done	
@Wait:
	BIT R_COMM_LINE_STAT
	BVC @Wait
	STA R_COMM_TXRX
	RTS
	INX
@Done:
	LDX #$FF
@JumpB:	INX
	CPX #$05
	BEQ B_Panic_Mem_Copy
	LDA $0200, X
	JMP B_Panic_Print_ASCII
	
B_Panic_Mem_Copy:
	LDX #$00
@Loop:
	LDA B_Panic_Prompts_ZP , X
	BEQ @Done
@Wait:
	BIT R_COMM_LINE_STAT
	BVC @Wait
	STA R_COMM_TXRX
	BRA @Loop
@Done:
	INX
	PHY	; Maintain stack
	STY $0205
	PHY ; Maintain stack
	STY $0206
	LDA $00
	JSR B_Panic_Print_ASCII
	LDA $01
	JSR B_Panic_Print_ASCII
	LDY $0206
	PHY	; Maintain stack
	LDY $0205
	PHY	; Maintain stack
	STZ $01
	LDA $02
	STA $00
	BRA @Loop
@Loop2:
	LDA ($00)
	PLY  ; Maintain stack
	STY $0205
	PLY	; Maintain stack
	STY $0206
	JSR B_Panic_Print_ASCII
	LDY $0206
	PHY	; Maintain stack
	LDY $0205
	PHY	; Maintain stack
@JumpC:
	INC $0200
	BNE @Inc_skip
	INC $0201
	LDA #$02
	CMP $0201
	
@Wait2:
	BIT R_COMM_LINE_STAT
	BVC @Wait2
	STA R_COMM_TXRX
@Inc_skip:
	INX
	CMP #$10
	BNE @Loop
	LDA #$0d
@Wait5:
	BIT R_COMM_LINE_STAT
	BVC @Wait5
	STA R_COMM_TXRX
	LDA #$0A
@Wait6:
	BIT R_COMM_LINE_STAT
	BVC @Wait6
	STA R_COMM_TXRX
	LDX #$00
	BRA @Loop2
	
	
	
	

	

	
	
	
	
B_Panic_Print_ASCII:
	TAY
	CLC
	AND #%11110000
	ROR
	ROR
	ROR
	ROR
	CMP $09
	BCS @ABCDEF
	ADC #$30
	.byte $2C
@ABCDEF:
	ADC #$37
@Wait2:
	BIT R_COMM_LINE_STAT
	BVC @Wait2
	STA R_COMM_TXRX
	TYA
	AND #%00001111
	CMP $09
	BCS @ABCDEF2
	ADC #$30
   .byte $2C
@ABCDEF2:
	ADC #$37
@Wait3:
	BIT R_COMM_LINE_STAT
	BVC @Wait3
	STA R_COMM_TXRX
	LDA #$20
@Wait4:
	BIT R_COMM_LINE_STAT
	BVC @Wait4
	STA R_COMM_TXRX
	JMP ($0205)
	
	
	
	
	
	


	
	
	
B_Panic_Prompts:
.asciiz "PANIC!\r\nA  X  Y  SP P\r\n"
B_Panic_Prompts_ZP:
.asciiz "ZP\r\n\n"
B_Panic_Prompts_Stack:
.asciiz "\r\n"
	
;************************************
;*				IRQ 				*
;************************************

BI_IRQ_Disable:













;priority
;1. timing
;2. serial
;3. i2c/gpio
;4. joy
;5. external







IRQ_Entrypoint:
	PHA
	LDA ZP_INT_TIE_MIRROR ; start checking timer irq
	LSR
	BCC NotTimer
	LDA #%11100010
	STA R_TIME_CTRL
	BIT R_TIME_0
	BNE NotTimer
IRQ_Timer: ; done in line for speed reasons. 49 cycles 24.5 us response
	LDA #%11111110
	AND ZP_INT_TIE_MIRROR
	STA ZP_INT_TIE_MIRROR
	STA R_TIE
	LDA #$80
	STA	ZP_Interupt_Stat
	PLA
	RTI
NotTimer: ; Check timer
	PHX
	LDA R_COMM_IRQ_STAT
	LSR
	BCC IRQ_COMM
NotComm:
	BIT R_PIA_GPIO_CTRL
	BCS IRQ_GPIO_A
	BVS IRQ_GPIO_B
	BIT R_PIA_JOY_CTRL
	BCS IRQ_Key
	BVS IRQ_TP22
NotPIA:
;write ext later
;	LDA #$
	JSR B_Panic
IRQ_Done:
	PLX
	PLA
	RTI






;7 3 2 2 2 4 4 2 2 3 3 2 3 4 6

IRQ_COMM:
	AND #%00000011
	BEQ IRQ_COMM_MODM_STAT
	;fall thru
IRQ_COMM_LINE_STAT:
	LDA R_COMM_LINE_STAT
	


IRQ_COMM_MODM_STAT:	








IRQ_GPIO_A:

IRQ_GPIO_B:

IRQ_Key:
	LDA #%00000001
	TSB ZP_Interupt_Stat
	LDX ZP_Key_Buffer_Pointer
	CPX ZP_Key_Buffer_Read_Pointer
	BNE @Not_Overflow
	LDA #%10000000
	TSB ZP_Bios_Error
@Not_Overflow:
	INX
	STX ZP_Key_Buffer_Pointer
	LDA R_KEYB
	STA $0200, X
	BRA IRQ_Done
	

IRQ_TP22:

















