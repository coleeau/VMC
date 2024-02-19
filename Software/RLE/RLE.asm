;unpack from ZP_INT_Pointer1 to ZP_INT_Pointer2
;Max length ZP_INT_Scratch1-2

BI_RLE_Magic:
.ASCIIZ	"JDRLE"
BI_RLE_INC:
	PHA
	INC ZP_INT_Pointer1_LSB
	BNE @IncSkip
	INC ZP_INT_Pointer1_MSB
@IncSkip:
	LDA #$FF					;Dec Length
	DEC ZP_INT_SCRATCH_1
	CMP ZP_INT_SCRATCH_1
	BNE @DecSkip
	DEC ZP_INT_SCRATCH_2
	PLA
@DecSkip:
	RTS
BI_RLE_CheckOOB
	PHA
	LDA #$FF
	CMP ZP_INT_SCRATCH_1
	BNE @Ok
	CMP ZP_INT_SCRATCH_2
	BNE @Ok
	LDA #$04
	STA ZP_INT_SCRATCH_3
	PLA
	PLA
	JMP BI_RLE_Error_Exit
@Ok
	RTS
	
	
BI_RLE:			;Entrypoint
	PHA
	PHX
	PHY
	LDA ZP_INT_Pointer1_LSB ;Storing temp for csum calc
	PHA
	LDA ZP_INT_Pointer1_MSB
	PHA
	LDA ZP_INT_SCRATCH_1
	PHA
	LDA ZP_INT_SCRATCH_2
	PHA
	STZ ZP_INT_SCRATCH_3
	STZ ZP_INT_SCRATCH_4
	CLD
	
@CSum_Calc						;Add value to CSum location
	LDA (ZP_INT_Pointer1_LSB)
	CLC
	ADC ZP_INT_SCRATCH_3
	BCC @IncSkip
	INC ZP_INT_SCRATCH_4		;Inc Data Pointer
@IncSkip:						
	JSR BI_RLE_INC
	LDA #$FF
	CMP ZP_INT_SCRATCH_1		;Check if Length underflows
	BNE @CSum_Calc
	CMP ZP_INT_Scratch_2
	BNE @CSum_Calc
	PLA							;restore data pointer and length
	STA ZP_INT_SCRATCH_2
	PLA 
	STA ZP_INT_SCRATCH_1
	PLA
	STA ZP_INT_Pointer1_MSB
	PLA
	STA ZP_INT_Pointer1_LSB
	LDX #$00
BI_RLE_Magic_Check:
	LDA BI_RLE_Magic, X
	BEQ BI_RLE_Command
	CMP	(ZP_INT_Pointer1)
	BNE @Invalid
	JSR BI_RLE_INC
	BRA @Loop
@Invalid:
	LDA #$00
	STA ZP_Scratch_3
BI_RLE_Error_Exit:
	LDA #%01000000
	TSB ZP_Bios_Error
	PLY
	PLX
	PLA
	RTS
BI_RLE_Command:
	JSR BI_RLE_CheckOOB
	LDA (ZP_INT_Pointer1)
	PHA
	JSR B_MATH8_Nybble_Swap
	AND #%00001111
	TAX
	PLA
	LDY BI_RLE_Command_JumpTable_HI,X
	PHY
	LDY BI_RLE_Command_JumpTable_LO,X
	PHY
	RTS	;rts trick,Jumps to location stored in jump table
	
	
	
	
BI_RLE_Command_JumpTable_HI: 
.LOBYTE		BI_RLE_Command_EndOfFile, BI_RLE_Command_ChangeMode, BI_RLE_Command_Reserved, BI_RLE_Command_Reserved
.LOBYTE		BI_RLE_Command_Reserved, BI_RLE_Command_Reserved, BI_RLE_Command_Reserved, BI_RLE_Command_Reserved
.LOBYTE		BI_RLE_Command_Reserved, BI_RLE_Command_GlobalCSum, BI_RLE_Command_Reserved, BI_RLE_Command_Reserved
.LOBYTE		BI_RLE_Command_Reserved, BI_RLE_Command_Reserved, BI_RLE_Command_Reserved, BI_RLE_Command_Version

BI_RLE_Command_JumpTable_LO: 

.HIBYTE		BI_RLE_Command_EndOfFile, BI_RLE_Command_ChangeMode, BI_RLE_Command_Reserved, BI_RLE_Command_Reserved
.HIBYTE		BI_RLE_Command_Reserved, BI_RLE_Command_Reserved, BI_RLE_Command_Reserved, BI_RLE_Command_Reserved
.HIBYTE		BI_RLE_Command_Reserved, BI_RLE_Command_GlobalCSum, BI_RLE_Command_Reserved, BI_RLE_Command_Reserved
.HIBYTE		BI_RLE_Command_Reserved, BI_RLE_Command_Reserved, BI_RLE_Command_Reserved, BI_RLE_Command_Version
	
	


BI_RLE_Command_Reserved:
	STA ZP_INT_SCRATCH_4
	LDA #$01
	STA ZP_INT_SCRATCH_3
	JMP BI_RLE_Error_Exit
	
BI_RLE_Command_GlobalCSum:
	LDX #$02
@Loop
	JSR BI_RLE_INC
	LDA (ZP_INT_Pointer1)
	PHA
	SEC
	SBC ZP_INT_SCRATCH_3
	BCS @DecSkip
	DEC ZP_INT_SCRATCH_4
	DEX
	BNE @Loop
	PLA
	CMP ZP_INT_SCRATCH_4
	BNE @Invalid
	PLA 
	CMP ZP_INT_SCRATCH_3
	BEQ @OK
@Invalid
	
	LDA #$02
	STA ZP_INT_SCRATCH_3
	JMP BI_RLE_Error_Exit
@OK
	JSR BI_RLE_INC
	JMP BI_RLE_Command
	
	
BI_RLE_Command_Version:
	AND #%00001111
	CMP #$01
	BEQ @OK
	STA ZP_INT_SCRATCH_4
	LDA #$03
	STA ZP_INT_SCRATCH_3
	JMP BI_RLE_Error_Exit
@OK
	JSR BI_RLE_INC
	JMP BI_RLE_Command

	
BI_RLE_Command_ChangeMode:

BI_RLE_Command_EndOfFile:

	
	
	
	
	
	

	

	
	