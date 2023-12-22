; Mem layout
;$80-87 StartLSB | StartMSB | Length+1LSB | Length+1MSB | ChecksumLSB | ChecksumMSB | Signature "J" | Signature "D"
;$88-8f CountLSB | CountMSB | CalcChecksumLSB | CalcChecksumMSB | DataLocationLSB | DataLocationMSB |StoreLSB |storeMSB
;$90    skip chsm flag
.pc02


.segment "CODE"

Entrypoint:
sei
cld; stack not cleared bc it is unused
setup:
lda #$00
	;txa ;a is now 00 (removed bc can just use a (-1))
sta $67f0 ; clear mapping register
sta $6020 ; clear timer register

RamClear:
.scope
;          lda #$00 avoided -1 byte
sta $01
sta $00
ldy #$02
ldx #$40 ;adjusted to use x; 1 more so bne could be used (and beq would fall thu) (-2) 
Loop:
sta ($00), Y ;startLSB
iny
cpy #$ff
bne Loop
inc $01
cpx $01			
bne Loop  ;(jmp loop) main will fall thru (-4)
.endscope
Main:
.scope
Setup:
txa ; to be able to use asl (+1) x (and now a) is $40 
ldx #%11000001
stx $6072 ; FCR (set up fifo)
asl ; a goes from $40 to $80 lda #%10000000 avoided 
sta $6073 ; LCR (enable divisor accses)
ldx #12
stx $6070 ; DLL (set baud to 9600)
asl; lda #$00 avoided (-1)
dex ;ldx #%00001011 avoided as 1011 is 1 less than 12 (-1)
sta $6071 ; DLM

stx $6073 ; LCR
                ;lda #$00 avoided by using x
	;sta $6071 ; IER (not neccisary as ier set to 00 on reset (-3)
ldy StrRDY-Str ; (ready)
jsr Copy
Header:
.scope
	lda #$80
	sta $88 ; Count
	asl
	sta $89
	Loop:
	jsr Read
	inc $88 ; Count
	lda $88
	cmp #$88 ; Count
	bne Loop
	lda $80 ; copy LOCATION to COUNT
	sta $88
	lda $81
	sta $89
	SignatureCompare:
	lda #$4A
	cmp $86
	bne Invalid
	lda #$44
	cmp $87
	beq Skip2
	Invalid:
	ldy StrINVLD-Str ; (invalid)
	jsr Copy
	jmp Entrypoint ;too far to use branch
	Skip2:
.endscope
.scope
Loop:
jsr Read
inc $88 ; Inc write address
bne CountMSBIncSkip
inc $89
CountMSBIncSkip:
lda $82
bne LengthMSBDecSkip
dec $83
LengthMSBDecSkip:
dec $82
lda #$00 
cmp $83
bne Loop ;jmp (will always be not eqaul)
cmp $82
bne Loop

.endscope
Done:
	Checksum:
.scope
lda $8a
LDX #$02 ;avoiding cpx #$ff by increasing by 1
Loop:
sec
sbc $83, X ;avoiding cpx #$ff by decreasing memory adress by 1
bcs Skip
dec $8b
Skip:
dex
;cpx #$ff (-2)
bne Loop
cmp $84
bne Invalid
lda $8b
cmp $85
bne Invalid
OK:			;beq OK avoided by changing order
ldy StrOK-Str ; (ok)
jsr Copy
jmp ($0080)
Invalid:
ldy StrCHKSM-Str ;(Checksum)
jsr Copy
jmp Entrypoint  ;too far for branch
.endscope
.endscope











Read:
.scope
ldy #$00
Loop:
lda $6075 ; LSR
lsr A
bcc Loop
lda $6070 ; RBR
sta ($88), Y
clc
adc $8a ;add to chcksum calc
sta $8a
bcc Skip
inc $8b
;clc (not needed??)
Skip:
rts
.endscope

Copy:
.scope
Loop: ;(0)
lda Str, Y
beq Terminate
sta $6070
iny 
bne Loop ; should be not equal as long as y=ff and iny does NOT occur (in order to get past beq termitate, zero must be not equal). should never happen because Y is never set and should never be set as ff 
Terminate: 

rts
.endscope

.segment "DATA" ;count real number of char + 1 (for length byte) || length byte then data
Str:
StrOK:		.literal "OK", $0d, $0a, $00 
StrRDY:		.literal "READY", $0d, $0a, $00 
StrCHKSM:	.literal "CHECKSUM", $0d, $0a, $00 
StrINVLD:	.literal "INVALID", $0d, $0a, $00 
StrNewline:







.segment "VEC"
.word $ffff
.word Entrypoint
.word $ffff








;OK0
;ERR0
;CHKSM0
;INVLD0