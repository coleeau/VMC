; Mem layout
;$80-87 StartLSB | StartMSB | Length+1LSB | Length+1MSB | ChecksumLSB | ChecksumMSB | Signature "J" | Signature "D"
;$88-8f CountLSB | CountMSB | CalcChecksumLSB | CalcChecksumMSB | DataLocationLSB | DataLocationMSB |StoreLSB |storeMSB
;$90    length
.pc02


.segment "CODE"

Entrypoint:
sei
cld
setup:
lda #$00
sta $67f0 ; clear mapping register
sta $6020 ; clear timer register
lda #$70
sta $8e
lda #$60
sta $8f
ZeroPageRamClear:
.scope
lda #$00
ldx #$00
Loop:
sta $00, X
inx
cpx #$ff
bne Loop
.endscope
RamClear:
.scope
lda #$00
sta $80
inc
sta $81
ldy #$00
Loop:
sta ($80), Y ;startLSB
iny
cpy #$ff
bne Loop
inc $81
lda #$3f
cmp $81
bcs Skip
jmp Main
Skip:
lda #$00
jmp Loop
.endscope
Main:
.scope
jsr Setup
lda #<StrPrompt
sta $8c
lda #>StrPrompt
sta $8d
jsr Copy
jsr Header
Loop:
jsr Read
inc $88 ; Inc write address
lda #$00
cmp $88
bne CountMSBIncSkip
inc $89
CountMSBIncSkip:
dec $82
lda #$FF
cmp $82
bne LengthMSBIncSkip
dec $83
LengthMSBIncSkip:
cmp $83
beq Done
bra Loop
Done:
jsr Checksum
lda #<StrOK
sta $8c
lda #>StrOK
lda $8d
jsr Copy
jmp ($0080)
.endscope














Setup:
lda #%11000001
sta $6072 ; FCR
lda #%10000000
sta $6073 ; LCR
lda #12
sta $6070 ; DLL
lda #$00
sta $6071 ; DLM
lda #%00001011
sta $6073 ; LCR
lda #$00
sta $6071 ; IER
rts



Read:
.scope
ldy #$00
lda $6075 ; LSR
lsr A
bcc Read
clc
lda $6070 ; RBR
sta ($88), Y
adc $8a ;add to chcksum calc
sta $8a
bcc Skip
inc $8b
clc
Skip:
rts
.endscope





Header:
.scope
	lda #$80
	sta $88 ; Count
	lda #$00
	sta $81
	Loop:
	jsr Read
	inc $88 ; Count
	lda #$88
	cmp $88 ; Count
	bcs Loop
	lda $80 ; copy LOCATION to COUNT
	sta $88
	lda $81
	sta $89
	SignatureCompare:
	lda #$4A
	cmp $86
	beq Skip
	lda #$44
	cmp $87
	beq Skip
	lda #<StrInvalid
	sta $8c
	lda #>StrInvalid
	sta $8d
	jsr Copy
	jmp Main
	Skip:
	rts
.endscope



Checksum:
.scope
lda $8a
cmp $84
bne Invalid
lda $8b
cmp $85
bne Invalid
rts
Invalid:
lda #<StrInvalid
sta $8c
lda #>StrInvalid
sta $8d
jsr Copy
lda #<StrPrompt
sta $8c
lda #>StrPrompt
sta $8d
jsr Copy
jmp Main
.endscope

Copy: ; copies data to an address, store data location and copy location at $8c and $8e and load length into $90
.scope
ldy #$00
lda ($8c), Y
sta $90
iny
Loop:
lda ($8c) , Y
sta ($8e)
iny
cpy $90
bne Loop
rts
.endscope

.segment "DATA" ;count real number of char + 1 (for length byte) || length byte then data
StrPrompt:
.byte $04, $21, $0d, $0a 
StrOK:
.byte $06, $4f, $4b, $21, $0d, $0a
StrInvalid:
.byte $0A, $49, $4e, $56, $41, $4c, $49, $44, $0d, $0a
StrCHKSM:
.byte $08, $43, $48, $4b, $53, $4d, $0d, $0a






.segment "VEC"
.word $ffff
.word Entrypoint
.word $ffff
