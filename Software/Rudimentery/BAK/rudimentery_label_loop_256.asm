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
ldx #$00
stx $8c
stx $67f0 ; clear mapping register
stx $6020 ; clear timer register
dex
stx $8d
ldx #$70
stx $8e
ldx #$60
stx $8f

RamClear:
.scope
lda #$00
sta $01
sta $00
ldy #$02
Loop:
sta ($00), Y ;startLSB
iny
cpy #$ff
bne Loop
inc $01
lda #$3f
cmp $01
bcs Skip
jmp Main
Skip:
lda #$00
jmp Loop
.endscope
Main:
.scope
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
ldy #<StrPrompt
jsr Copy
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
	beq Skip
	Invalid:
	ldy #<StrInvalid
	jsr Copy
	jmp Entrypoint
	Skip:
.endscope
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
jmp Loop
Done:
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
ldy #<StrInvalid
jsr Copy
ldy #<StrPrompt
jsr Copy
jmp Entrypoint
.endscope
ldy #<StrOK
jsr Copy
jmp ($0080)
.endscope

















Read:
.scope
clc
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

Copy: ; copies data to an address, store data location and copy location at $8c and $8e and load length into $90
.scope
ldx #$00
Loop:
lda ($8c) , Y
sta ($8e), y
inx
iny
cpx #$03
bne Loop
rts
.endscope

.segment "DATA" ;count real number of char + 1 (for length byte) || length byte then data
StrPrompt:
.byte $40, $0d, $0a 
StrOK:
.byte $21, $0d, $0a
StrInvalid:
.byte $45, $0d, $0a
StrCHKSM:
.byte $43, $0d, $0a






.segment "VEC"
.word $ffff
.word Entrypoint
.word $ffff
