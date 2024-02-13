
;********************************************************************************
;*																				*
;*							VMC Ram Load Program 1.0							*
;*																				*
;*				Sets up system to a minimally initialized state					*
;*	 Loads header into ram and uses it to figure out where to load things		*
;*				Transfers program into ram while checking checksum				*
;*					Jumps to program if checksum is correct						*
;*																				*
;*			Programed by Juren Donovan						11/30/23			*
;*																				*
;********************************************************************************


;************************************************
;*				      Setup						*
;************************************************

.include "../IO_DEF.ASM" ; standard io lib. current program is expecting initial revision.

;comment out for nmos
.pc02


;************************************************
;*				  Memory Layout					*
;************************************************

Z_StartLSB			:= $F8 ;Sent, LSB of where the first byte after header is stores. also used to jump to Program at end.
Z_StartMSB			:= $F9 ;Sent, MSB of Above ^
Z_Length_1LSB		:= $FA ;Sent, LSB of the length +1 of the transfer. Used to termitate Transfer
Z_Length_1MSB		:= $FB ;Sent, MSB of Above ^
Z_ChecksumLSB		:= $FC ;Sent, LSB of the Checksum for the sent data
Z_ChecksumMSB		:= $FD ;Sent, MSB of Above ^
Z_Signature_J		:= $FE ;Sent, First byte of the signature
Z_Signature_D		:= $FF ;Sent, Second byte of the signature
Z_CountLSB			:= $F4 ;Local, LSB of Where the current byte will be stored
Z_CountMSB			:= $F5 ;Local, MSB of Above ^
Z_CalcChecksumLSB	:= $F6 ;Local, LSB of the Checksum Calculation of every byte recived
Z_CalcChecksumMSB	:= $F7 ;Local, MSB of Above ^




.segment "CODE"
Entrypoint:				; General housekeeping, setting banks correctly
sei
	.ifpc02				; cld on cmos initialized on reset 
	.else
		cld				; stack not cleared bc it is unused
	.endif
ldy #%00000100 
sty R_BANK_SEL 			; Sets RAM1 to bank 1
	
	.ifpc02
		stz R_TIE
	.else
		lda #$00
		sta R_TIE 		; clear timer register
	.endif
Setup:				
lda #$80
ldx #%11000001
stx R_COMM_FIFO_CTRL 
sta R_COMM_LINE_CTRL 	; LCR (enable divisor accses)
ldx #12
stx R_COMM_DIV_LSB 		;(set baud to 9600)
	.ifpc02	
	.else
	asl	
	.endif
dex 					;ldx #%00001011 avoided as 1011 is 1 less than 12 (-1)
	.ifpc02
	stz R_COMM_DIV_MSB
	.else	
	sta R_COMM_DIV_MSB 
	.endif
stx R_COMM_LINE_CTRL 
						;sta $6071 ; IER (not neccisary as ier set to 00 on reset (-3)


	.ifpc02
		ldy StrVMC-Str ; (vmc)
		jsr Send_MSG
	.endif
					
RamClear:
.scope
lda #$00
sta $01
sta $00
ldy #$02
ldx #$40 				;adjusted to use x; 1 more so bne could be used (and beq would fall thu) (-2) 
Loop:
sta ($00), Y ;startLSB
iny
bne Loop
inc $01
cpx $01			
bne Loop  ;(jmp loop) main will fall thru (-4)


.endscope


;************************************************
;*					  Main						*
;************************************************

Main:


.scope	Header 			;copies header values only to zp
	lda #$f8 			;setting temporary write location for header
	sta Z_CountLSB		 ;stz Z_CountMSB not needed as ram was just zeroed
	ldy StrRDY-Str
	jsr Send_MSG				
	Loop:
	jsr Read
	inc Z_CountLSB ;lda cmp removed by switching write location to f8-ff
	bne Loop
	lda Z_StartLSB ; copy LOCATION to COUNT
	sta Z_CountLSB
	lda Z_StartMSB
	sta Z_CountMSB
	SignatureCompare:
	lda #$4A
	cmp Z_Signature_J
	bne Invalid
	lda #$44
	cmp Z_Signature_D
	beq Skip2
	Invalid:
	ldy StrINVLD-Str ; (invalid)
	jsr Send_MSG
	.ifpc02
		Fail_Branch: ; second jump to ram clear is too far, chaining to fix.
		bra RamClear
	.else
		beq Ramclear ; Send_MSG always returns as equal
	.endif
	Skip2:
.endscope
.scope					; main read section
Loop:					; 61-73 cycles 24.4-29.2 us (34.2-40.1 kb/s)
jsr Read ;38 cycles
inc Z_CountLSB ; Inc write address
bne CountMSBIncSkip
inc Z_CountMSB
CountMSBIncSkip:
lda Z_Length_1LSB
bne LengthMSBDecSkip
dec Z_Length_1MSB
LengthMSBDecSkip:
dec Z_Length_1LSB			
bne Loop ;jmp (will always be not eqaul)
lda Z_Length_1MSB
bne Loop

.endscope
Done:
Checksum: ; main checksum calculation includes itself, subtracts each byte from checksum
.scope
lda Z_CalcChecksumLSB
ldx #$02 ;avoiding cpx #$ff by increasing by 1
Loop:
sec
sbc Z_ChecksumLSB-1, X ;avoiding cpx #$ff by decreasing memory adress by 1
bcs Skip
dec Z_CalcChecksumMSB
Skip:
dex
bne Loop
cmp Z_ChecksumLSB
bne Invalid
lda Z_CalcChecksumMSB
cmp Z_ChecksumMSB
bne Invalid
OK:					; Final Jump to loaded Program
ldy StrOK-Str ; (ok)
jsr Send_MSG
jmp (Z_StartLSB)
Invalid:
ldy StrCHKSM-Str ;(Checksum)
jsr Send_MSG
	.ifpc02
		bra Header::Fail_Branch
	.else
		beq Header::Fail_Branch  ; Send_MSG always returns as equal
	.endif  ;too far for branch
.endscope












Read:	; reads a byte in to a location in memory defined by Z_Count, and adds it to checksum calculation
		; 38 cycles (15.2us at 2.5mhz, 65kb/s) ((41 if nmos)) (((ignoting propogation time)))
.scope
	.ifpc02
		
	.else
	ldy #$00
	.endif
Loop:
bit R_COMM_LINE_STAT ; better than lda, lsr (-1) ;check if there is data in fifo
bcc Loop ; wait if not
lda R_COMM_TXRX 
	
	.ifpc02
		sta (Z_CountLSB)
	.else
		sta (Z_CountLSB), Y
	.endif
clc
adc Z_CalcChecksumLSB ;add to chcksum calc
sta Z_CalcChecksumLSB
bcc Skip
inc Z_CalcChecksumMSB
;clc (not needed??)
Skip:
rts
.endscope

Send_MSG: ; sends a message to comm. y is ofset in string table
.scope
Loop: ;(0)
lda Str, Y
beq Terminate

sta R_COMM_TXRX
iny 

	.ifpc02
		bra Loop
	.else
		bne Loop ; should be not equal as long as y=ff and iny does NOT occur (in order to get past beq termitate, zero must be not equal). should never happen because Y is never set and should never be set as ff 
	.endif
Terminate: 
cpy #$02
beq Return
ldy #$00
beq Loop
Return:
rts
.endscope



;************************************************
;*				  String Table					*
;************************************************


.segment "DATA" ; Strings for COMM
Str:
StrCR:		.byte $0d, $0a, $00 
.ifpc02
	StrVMC:	.asciiz "VMC 1.0"
.endif
StrRDY:		.asciiz "READY"
StrOK:		.literal "OK!", $07, $00
StrCHKSM:	.asciiz "CHECKSUM"
StrINVLD:	.asciiz "INVALID"








.segment "VEC"
.word $ffff
.word Entrypoint
.word $ffff








;OK0
;ERR0
;CHKSM0
;INVLD0