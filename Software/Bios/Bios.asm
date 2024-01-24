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
ZP_Math_3
ZP_Math_4
ZP_Pointer_LSB
ZP_Pointer_MSB






ZP_Interupt_Stat					; b7= timer b6= Serial     b0=Newkey
ZP_Key_Buffer_Pointer
ZP_Key_Buffer_Read_Pointer
ZP_Bios_Error						;b7=keyboard buffer overflow		b0=timer source 0=cpuclk 1=clk2
ZP_INT_BSR_MIRROR
ZP_INT_TIE_MIRROR
ZP_INT_SCRATCH_1
ZP_INT_PANIC_1						; Not reserved per say, but will be destroyed if B_Panic is called. 

;************************************
;*				Main  				*
;************************************
Entrypoint:	
	SEI
	LDA #$C1		;Clock gen id read
	LDX #03
	JSR B_I2C
	ROR
	ROR
	BCC Entrypoint_Warm
Entrypoint_Cold
	LDX #$FF
	TXS				;Init Stack Pointer
	STX R_GPIO		;Init Gpio to output POSTCODE
	LDA #b00000100
	STA R_GPIO_CTRL
	STA R_BANK_SEL	;Conviniently dont have to load a different value
	INC R_GPIO		;DEBUG 01
Entrypoint_Cold_Serial_Setup	;sets serial to 9600 8 E 1
	LDA #b00001011	;DIV_LATCH enable, No tx break, no force parity, Even parity, Yes Parity, 1 stop bit, 8 bit word
	STA R_COMM_LINE_CTRL
	LDA #14
	JSR B_COMM_Set_Speed
	INC R_GPIO		;DEBUG 02
	LDA #b00000111
	STA R_COMM_FIFO_CTRL
	LDA #b00100010
	STA R_COMM_MODM_CTRL
	INC R_GPIO		;DEBUG 03
	LDX #$00
	LDY #$00
	LDA #$5A
Entrypoint_MEMTEST_ZP: ;tests zp with patterns $5A $A5 $FF $00, also indirectly clears memory by filling  w/ $00 last
@Loop_STA
	STA $00, X
	INX
	BNE @Loop_STA	;done storing set value
@Loop_CMP
	CMP $00, X
	BNE @Error
	INX
	BNE @Loop_CMP
	INY
	CMP #$04		
	BEQ Entrypoint_MEMTEST_ZP_Done
	LDA Entrypoint_MEMTEST_Values, Y
	BRA Entrypoint_MEMTEST_ZP
@Error
			;will write later

Entrypoint_MEMTEST_ZP_Done:		;Prints RamCount and ZP_ok prompt
	INC R_GPIO		;Debug 04
	LDA <Entrypoint_Memtest_Splash
	STA ZP_Pointer_LSB
	LDA >Entrypoint_Memtest_Splash
	STA ZP_Pointer_MSB
	JSR B_COMM_TX_Str
	LDA #$00
	JSR	Entrypoint_MEMTEST_Print_Page
	LDX #01
	LDY #03
	JSR B_COMM_MoveCsr
	LDA <Entrypoint_MEMTEST_Prompt_zp
	STA ZP_Pointer_LSB
	LDA >Entrypoint_MEMTEST_Prompt_zp
	STA ZP_Pointer_MSB
	JSR B_COMM_TX_Str
	INC R_GPIO		;Debug 05
	LDA #b00000100				;Set ram bank to 1 for ram test
	STA ZP_INT_BSR_MIRROR
	STA R_BANK_SEL
	LDA $01
	STA ZP_Pointer_MSB
	STZ ZP_Pointer_LSB
	LDA $5A
	LDY #$00
	LDX #$00
Entrypoint_MEMTEST:
@Loop_STA 
	STA (ZP_Pointer_LSB)		
	INC (ZP_Pointer_LSB)
	BNE @Loop_STA
@Loop_CMP
	CMP $(ZP_Pointer_LSB)
	BNE @Error
	INC (ZP_Pointer_LSB)
	BNE @Loop_CMP
	INY
	CPY #$04
	BEQ Entrypoint_MEMTEST_Next_Page
@Return
	LDA Entrypoint_MEMTEST_Values, Y
	BRA Entrypoint_MEMTEST
	
	
@Entrypoint_MEMTEST_Next_Page:	;Add offset to RamCount if necisary
	LDA ZP_Pointer_MSB
	BBR3 ZP_INT_BSR_MIRROR, @No_Add
	CLC
	BBS2 ZP_INT_BSR_MIRROR, @Add_$40
	ADC #$20
	.byte $2C
@ADD_$40
	ADC #$40
@No_Add
	JSR Entrypoint_MEMTEST_Print_Page
	INC ZP_Pointer_MSB	;check if 
	LDA #$40
	CMP ZP_Pointer_MSB
	BNE @No_Bankswitch
	STA ZP_Pointer_MSB
	LDA ZP_INT_BSR_MIRROR
	CLC 
	ADC #b00000100
	CMP #b00010000
	BEQ @Done
	STA ZP_INT_BSR_MIRROR
@No_Bankswitch
	LDY #$00
	BRA @Return

@Error	
	LDA #$F0
	STA R_GPIO
	LDX ZP_Pointer_LSB
	LDY ZP_Pointer_LSB
	LDA <Entrypoint_MEMTEST_Prompt_Badram
	STA ZP_Pointer_LSB
	LDA >Entrypoint_MEMTEST_Prompt_Badram
	STA ZP_Pointer_MSB
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
	
	
@Done
	INC R_GPIO		;Debug 06
	LDA <Entrypoint_MEMTEST_Prompt_ram
	STA ZP_Pointer_LSB
	LDA >Entrypoint_MEMTEST_Prompt_ram
	STA ZP_Pointer_MSB
	LDX #01
	LDY #04
	JSR B_COMM_MoveCsr
	JSR B_COMM_TX_Str
	
Entrypoint_Test_CLK:
	
@Enable_Clk2
	INC R_GPIO		;Debug 07
	LDA #$C0		;Clock gen id write
	LDX #03
	LDY #$02 		;Make sure CLK2 is disabled before checking which clock is used by timer
	JSR B_I2C
	LDA #$FF
	TAX
	JSR B_TIME_Delay
	LDA #b11100010	;Readback Status For Counter 0
	STA R_TIME_CTRL
	BIT R_TIME_0
	BVC @Using_CPU_CLK
	LDA #b00000001
	TSB ZP_Bios_Error	;using CLK2
@Using_CPU_CLK	
	LDA #b00110000			;Disable counting
	STA R_TIME_CTRL
	INC R_GPIO		;Debug 08	
	LDA #$C0		;Start CLK2
	LDX #03
	LDY #$00
	JSR B_I2C
@Check_Bad_Timer	;if both reads return Null Count, Timer Bad
	LDA #$ff
	TAX
	JSR B_TIME_Delay
	LDA #b11100010	;Readback Status For Counter 0
	STA R_TIME_CTRL
	BIT R_TIME_0
	BVC @Timer_Ok
	LDA <Entrypoint_Prompt_BadTimer
	STA ZP_Pointer_LSB
	LDA >Entrypoint_Prompt_BadTimer
	STA ZP_Pointer_MSB
	JSR B_COMM_TX_Str
	STP
@Timer_Ok	
	LDA #b00110000
	STA R_TIME_CTRL
	INC R_GPIO		;Debug 09
	LDA <Entrypoint_Prompt_Timer_OK
	STA ZP_Pointer_LSB
	LDA >Entrypoint_Prompt_Timer_OK
	STA ZP_Pointer_MSB
	JSR B_COMM_TX_Str
	
Entrypoint_Done:
	JSR B_COMM_ClsScr
	LDA <Entrypoint_Prompt_Done
	STA ZP_Pointer_LSB
	LDA >Entrypoint_Prompt_Done
	STA ZP_Pointer_MSB
	JSR B_COMM_TX_Str
	JMP MON
















Entrypoint_MEMTEST_Print_Page:
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
.asciiz "VMC RomBIOS 1.0\T2024 Jake Donovan\TTurn on local echo!"
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
B_ReadKey:
	PHX
	LDX ZP_Key_Buffer_Read_Pointer
	CPX ZP_Key_Buffer_Pointer
	CLC 
	BNE @OK
	PLX
	SEC
	RTS
@OK
	LDA $0200, X
	INC ZP_Key_Buffer_Read_Pointer
	RTS
	
	
	
;
; ======timer=====
; Timer setup
;	 	enable, and start timer of certain length
B_TIME_Delay ; start delay with LSB of A and MSB of X cycles. returns 5 cycles into the count due to the RTS instruction. 
			;39 cycles  19.5us @2mhz  (+ 10 cycles to set up 5us @2mhz for a total of 24.5us)
	PHA   					;3
	LDA #b00110000			;2
	STA R_TIME_CTRL			;4
	LDA	ZP_INT_TIE_MIRROR	;3
	ORA #b00000001			;2
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
	


B_COMM_TX_Char: ;sends Character in A register. Clobbers Carry: Carry Set when succsessful, Cleared when failed
	;check serial status 
	
	BIT R_COMM_LINE_STAT
	BVC B_COMM_TX_Char ;full
	STA R_COMM_TXRX
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
	
	
	
B_COMM_MoveCsr:		;Move cursor to X,Y
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
	
B_COMM_ClsScr		;VT100 Clear Screen
	PHA
	LDA <@String
	STA ZP_Pointer_LSB
	LDA >@String
	STA ZP_Pointer_MSB
	JSR B_COMM_TX_Str
	PLA
	RTS
@String
.asciiz "^[[2J"
	
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
	PLX
	RTS
@OK:
	LDA #b10000000
	TSB R_COMM_LINE_CTRL
	LDA COMM_Speed_Low, X
	STA R_COMM_DIV_LSB
	LDA COMM_Speed_Hi, X
	STA R_COMM_DIV_MSB
	LDA #b10000000
	TRB R_COMM_LINE_CTRL
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
B_I2C:
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
	RTS
	
	
	


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
	PLA	
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
B_Add_16:		;Math_1-2 + Math_3-4. Stored In Math_1-2. carry is valid Little Endian
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
	
B_Sub_16:		;Math_1-2 - Math_3-4. Stored In Math_1-2. carry is valid Little Endian
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
B_Data_Hex2ASC: ;A in, A hi nybble X lo Nybble
	CLD
	PHY
	TAY
	AND #b00001111
	CMP #$0A
	BCC @Nums
	CLC
	ADC #$37
.byte $2C
@Nums
	ADC #$30
	TAX
	TYA
	AND #b11110000
	ROR
	ROR
	ROR
	ROR
	CMP #$0A
	BCC @Nums
	CLC
	ADC #$37
.byte $2C
@Nums
	ADC #$30
	PLY
	RTS
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


;routine that clobbers mem
Panic:
	STA $0200 ;A
Panic_Get_P_No_PHP: ;44 bytes
	BMI @N		;If no branch, /N
		BEQ @/NZ		
			LDA #b00000000 ; /N/V/Z
			BRA @Done
			@/NZ:
			LDA #b00000010
			BRA @Done
	@N
		BEQ @NZ		
			LDA #b10000000 ; /N/V/Z
			BRA @Done
			@NZ:
			LDA #b10000010
			BRA @Done

Panic_Get_Registers
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
	LDA #b10000010
	TRB $0204
	TYA
	TSB $0204	;P
	CLD
Panic_Send_Prompt:
	LDX #$00
	LDA Panic_Prompts, X
	BEQ @Done	
@Wait
	BIT R_COMM_LINE_STAT
	BVC @Wait
	STA R_COMM_TXRX
	RTS
	INX
@Done:
	LDX #$FF
@JumpB:	INX
	CPX #$05
	BEQ Panic_Mem_Copy
	LDA $0200, X
	JMP Print_ASCII
	
Panic_Mem_Copy:
	LDX #$00
@Loop
	LDA Panic_Prompts_ZP , X
	BEQ @Done
@Wait
	BIT R_COMM_LINE_STAT
	BVC @Wait
	STA R_COMM_TXRX
	INX
	BRA @Loop
	STZ $0200
	STZ $0201
@Loop2	
	LDA ($0200)
		PLY  ; Maintain stack
	STY $0205
	PLY
	STY $0206
	JSR Panic_Print_ASCII
	LDY $0206
	PHY
	LDY $0205
	PHY
@JumpC	INC $0200
	BNE @Inc_skip
	INC $0201
	LDA #$02
	CMP $0201
	
@Wait
	BIT R_COMM_LINE_STAT
	BVC @Wait2
	STA R_COMM_TXRX
@Inc_skip	
	INX
	CMP #$10
	BNE @Loop
	LDA #$0d
@Wait5
	BIT R_COMM_LINE_STAT
	BVC @Wait5
	STA R_COMM_TXRX
	LDA #$0A
@Wait6
	BIT R_COMM_LINE_STAT
	BVC @Wait6
	STA R_COMM_TXRX
	LDX #$00
	BRA @Loop2
	
	
	
	

	

	
	
	
	
Panic_Print_ASCII:
	TAY
	CLC
	AND #b11110000
	ROR
	ROR
	ROR
	ROR
	CMP $09
	BCS @ABCDEF
	ADC #$30
	.byte $2C
@ABCDEF	
	ADC #$37
@Wait2
	BIT R_COMM_LINE_STAT
	BVC @Wait2
	STA R_COMM_TXRX
	TYA
	AND #b00001111
	CMP $09
	BCS @ABCDEF2
	ADC #$30
   .byte $2C
@ABCDEF2
	ADC #$37
@Wait3
	BIT R_COMM_LINE_STAT
	BVC @Wait3
	STA R_COMM_TXRX
	LDA #$20
@Wait4
	BIT R_COMM_LINE_STAT
	BVC @Wait4
	STA R_COMM_TXRX
	JMP ($0205)
	
	
	
	
	
	


	
	
	
Panic_Prompts:
.asciiz "PANIC!\r\nA  X  Y  SP P\r\n"
Panic_Prompts_ZP:
.asciiz "ZP\r\n\n"
Panic_Prompts_Stack:
.asciiz "\r\n
	
;************************************
;*				IRQ 				*
;************************************

IRQ_Disable













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
	BCS IRQ_KEY
	BVS IRQ_TP22
NotPIA:
;write ext later
	LDA #$
	JSR B_Panic
IRQ_Done:
	PLX
	PLA
	RTI
.endscope





;7 3 2 2 2 4 4 2 2 3 3 2 3 4 6

IRQ_COMM:
	TRB #b11111100
	BEQ IRQ_COMM_MODM_STAT
	;fall thru
IRQ_COMM_LINE_STAT:
	LDA R_COMM_LINE_STAT
	


IRQ_COMM_MODM_STAT:	








IRQ_GPIO_A:

IRQ_GPIO_B

IRQ_Key:
	LDA #b00000001
	TSB ZP_Interupt_Stat
	LDX ZP_Key_Buffer_Pointer
	CPX ZP_Key_Buffer_Read_Pointer
	BNE @Not_Overflow
	LDA #b10000000
	TSB ZP_Bios_Error
@Not_Overflow
	INX
	STX ZP_Key_Buffer_Pointer
	LDA R_KEYB
	STA $0200, X
	BRA IRQ_Done
	

