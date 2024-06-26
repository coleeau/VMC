; Mem layout
;$80-87 StartLSB | StartMSB | Length+1LSB | Length+1MSB | ChecksumLSB | ChecksumMSB | Signature "J" | Signature "D"
;$88-8f CountLSB | CountMSB | CalcChecksumLSB | CalcChecksumMSB |

.pc02


.segment "CODE"

Entrypoint:
sei
setup:
lda #$00
sta $67f0 ; clear mapping register
sta $6020 ; clear timer register
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
sta ($80), Y
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
lda #$21 ; send prompt
sta $6070
lda #$0D
sta $6070
lda #$0A
sta $6070
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
lda #$4f ; send ok prompt
sta $6070
lda #$4b
sta $6070
lda #$21 
sta $6070
lda #$0D
sta $6070
lda #$0A
sta $6070
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
	lda #$49 ; Transmit Invalid
	sta $6070
	lda #$4E
	sta $6070
	lda #$56
	sta $6070
	lda #$41
	sta $6070
	lda #$4C
	sta $6070
	lda #$49
	sta $6070
	lda #$44
	sta $6070
	lda #$0D
	sta $6070
	lda #$0A
	sta $6070
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
lda #$43
sta $6070
lda #$48
sta $6070
lda #$45
sta $6070
lda #$43
sta $6070
lda #$4b
sta $6070	
lda #$53
sta $6070
lda #$55
sta $6070
lda #$4d
sta $6070
lda #$21 ; send prompt
sta $6070
lda #$0D
sta $6070
lda #$0A
sta $6070
jmp Main
.endscope


.segment "VEC"
.word $ffff
.word Entrypoint
.word $ffff
