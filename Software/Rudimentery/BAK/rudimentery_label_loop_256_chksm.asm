; Mem layout
;$80-87 StartLSB | StartMSB | Length+1LSB | Length+1MSB | ChecksumLSB | ChecksumMSB | Signature "J" | Signature "D"
;$88-8f CountLSB | CountMSB | CalcChecksumLSB | CalcChecksumMSB | DataLocationLSB | DataLocationMSB |StoreLSB |storeMSB
;$90    skip chsm flag
.pc02


.segment "CODE"

Entrypoint:
sei
cld
setup:
ldx #$00
txa ;a is now 00
stx $67f0 ; clear mapping register
stx $6020 ; clear timer register
;ldx #$70
;stx $8e
;ldx #$60
;stx $8f

RamClear:
.scope
;          lda #$00 avoided -1 byte
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
bcc Main ;(jmp main)
Skip:
lda #$00
bpl Loop  ;(jmp loop)
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
ldx #$00
stx $6071 ; DLM
lda #%00001011
sta $6073 ; LCR
                ;lda #$00 avoided by using x
stx $6071 ; IER
dex
stx $8d
ldx #<StrNewline-1
stx $8c
lda #$52
ldx #$44
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
	lda #$49
	ldx #$56
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
LDX #$01
Loop:
sec
sbc $84, X
bcs Skip
dec $8b
Skip:
dex
cpx #$ff
bne Loop
cmp $84
bne Invalid
lda $8b
cmp $85
bne Invalid
OK:			;beq OK avoided by changing order
lda #$4F
ldx #$4B
jsr Copy
jmp ($0080)
Invalid:
lda #$43
ldx #$53
jsr Copy
jmp Entrypoint  ;too far for branch
.endscope
.endscope








	








Read:
.scope
clc
ldy #$00
lda $6075 ; LSR
lsr A
bcc Read
lda $6070 ; RBR
sta ($88), Y
clc
adc $8a ;add to chcksum calc
sta $8a
bcc Skip
inc $8b
clc
Skip:
rts
.endscope

Copy: ; copies data to an address, store data location and copy location at $8c and $8e
.scope
sta $6070
ldy #$00
stx $6070
Loop:
lda ($8c) , Y
sta $6070
iny
cpy #$02
bne Loop
rts
.endscope

.segment "DATA" ;count real number of char + 1 (for length byte) || length byte then data
StrNewline:
.byte $0d, $0a






.segment "VEC"
.word $ffff
.word Entrypoint
.word $ffff



