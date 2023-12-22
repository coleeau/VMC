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
;bcs Skip   not needed since bcs will just fall through bcc (-2)
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
;dex            only used by 1 function, using indexed absolute instead (-6)
;stx $8d
;ldx #<StrNewline-1
;stx $8c
;lda #$52 ; using y as an index, (-2)
;ldx #$44
ldy
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
	;lda #$49
	;ldx #$56 ; using y as an index, (-2)
	ldy
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
;lda #$4F
;ldx #$4B ; using y as an index, (-2)
ldy
jsr Copy
jmp ($0080)
Invalid:
;lda #$43
;ldx #$53 ; using y as an index, (-2)
ldy
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
lda StrNewline-1, Y
sta $6070
iny
cpy #$02
bne Loop
rts
.endscope

.segment "DATA" ;count real number of char + 1 (for length byte) || length byte then data
Str:
StrNewline:
.byte $0d, $0a, $00 ;(+1)






.segment "VEC"
.word $ffff
.word Entrypoint
.word $ffff



Copy_2:
.scope
;sta $6070 (-8)
;ldy #$00
;stx $6070
 
ldx #$02
Loop: ;(0)
lda Str-1, Y
beq Terminate
sta $6070
iny
bne Loop ; should be not equal as long as y=ff and iny does NOT occur (in order to get past beq termitate, zero must be not equal). should never happen because Y is never set and should never be set as ff 
Terminate: ;this part is for looping exactly twice with the second time always being a new line (+7)
ldy ; y value for new line 
dex
bne Loop
rts
.endscope


;16+ (-3)  19 total




OK0
ERR0
CHKSM0
INVLD0