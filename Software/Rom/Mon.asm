.EXPORT Mon



; Main loop
;		get line
;				parse line
;				Jump table




;R
; 	Read: 	(B)xx.yy 
;			(B)xxxx.yyyy
;			(B)r
;			B is optional and reports in bits instead of bytes]
;			xx/xxxx is byte/start byte 
;			yy/yyyy is end byte
;			r is register where r= A, X, Y, P, SP, PC
;W		Write:
;			(xx)xx yy (zz)
;			x= write address y= byte to be written (additional bytes follow and are seperate by space)
;J		Jump:
;			xxxx 
;			x= address to jump to
;B		Bankswitch;
;		Xyy
;		X= thing to bank (Ram, rOm, Vram, Chram, Accsess v/chram
	
;Q		Quit to bios
;X		rEset
;A		Assemble
;C		Clear screen
;D		Disasm
;H		Help


Mon:		;save registers without clobbering stack
	STA ZP_Mon_Bak_A
	STX ZP_Mon_Bak_X
	STY ZP_Mon_Bak_Y
	TSX
	STX ZP_Mon_Bak_SP
	INX 
	LDY	$0100, X ;N, Z Clobbered
	PHP
	SEI
	PLA
	STA ZP_Mon_Bak_P
	PHY
	BCS @C0
	SMB1 ZP_Mon_Bak_P
	BRA @Skip1
@C0
	RMB1 ZP_Mon_Bak_P
@Skip1
	BPL @N0
	SMB7 ZP_Mon_Bak_P
	BRA Mon_Mainloop
@N0
	RMB7 ZP_Mon_Bak_P


Mon_Mainloop:
	STZ ZP_Key_Buffer_Pointer
	STZ ZP_Key_Buffer_Read_Pointer
	JSR B_COMM_RX_Str
	BBS7 ZP_Bios_Error, Mon_Overflow
	LDX ZP_Key_Buffer_Read_Pointer
	LDA $0200, X
@Jumptable
	BEQ 
	CMP #$0A			; LF?
	BEQ Mon_Jumptable_LF
	CMP #$0d			; CR?
	BEQ Mon_Jumptable_CR
	CMP	#$41			; A(semble)?
	BEQ Mon_Jumptable_Assemble
	CMP	#$42			; B(anksel)?
	BEQ Mon_Jumptable_Banksel
	CMP #$43
	BEQ Mon_Jumptable_Clearscreen
	CMP #$44			; D(isasm)?
	BEQ Mon_Jumptable_Disasm
	CMP	#$45			;rEset?
	BEQ Mon_Jumptable_Reset
	CMP #$48			;Help?
	BEQ Mon_Jumptable_Help
	CMP	#$74			;Jump?
	BEQ Mon_Jumptable_Jump
	CMP #$81
	BEQ Mon_Jumptable_Jump
	CMP #$82			;Read?
	BEQ Mon_Jumptable_Read
	CMP #$87			;Write?
	BEQ Mon_Jumptable_Write
@Invalid
	LDA #$01
	JSR Mon_String
	BRA Mon_Mainloop
	
	
	
	












Mon_String:
PHX
TAX
LDA Mon_String_Table_Lo, X
STA ZP_String1_LSB
LDA Mon_String_Table_Hi, X
STA ZP_String1_MSB
LDA #$00
JSR B_COMM_TX_Str
PLX
RTS












Mon_String_Table_Lo:
.Byte <Mon_String_Invalid, 
Mon_String_Table_Hi:
.Byte >Mon_String_Invalid, 


Mon_String_Invalid:			;$00
.asciiz "ERROR: Invalid Command. H for Help"