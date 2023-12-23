; Mem layout
;$80-87 StartLSB | StartMSB | Length+1LSB | Length+1MSB | ChecksumLSB | ChecksumMSB | Signature "J" | Signature "D"
;$88-8f CountLSB | CountMSB | CalcChecksumLSB | CalcChecksumMSB |

.pc02



Entrypoint:
sei
setup:
lda #$00
sta $67f0 ; clear mapping register
sta $6020 ; clear timer register
ZeroPageRamClear:
lda #$00
ldx #$00
ZeroPageRamClear.Loop:
sta $00, X
inx
cpx #$ff
bne ZeroPageRamClear.Loop
RamClear:
lda #$00
sta $80
inc
sta $81
ldy #$00
RamClear.Loop:
sta ($80), Y
iny
cpy #$ff
bne RamClear.Loop
inc $81
lda #$3f
cmp $81
bcs RamClear.Skip
jmp Main
RamClear.Skip
lda #$00
jmp RamClear.Loop
Main:
jsr Setup
lda #$21 ; send prompt
sta $6070
lda #$0D
sta $6070
lda #$0A
sta $6070
jsr Header
Main.Loop:
jsr Read
inc $88 ; Inc write address
lda #$00
cmp $88
bne Main.CountMSBIncSkip
inc $89
Main.MSBIncSkip
dec $82
lda #$FF
cmp $82
bne Main.LengthMSBIncSkip
dec $83
cmp $83
beq Main.Done
bra Main.Loop
Main.Done
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
ldy #$00
lda $6075 ; LSR
lsr A
bcc Read
clc
lda $6070 ; RBR
sta ($88), Y
adc $8a ;add to chcksum calc
sta $8a
bcc Read.Skip
inc $8b
clc
Read.Skip:
rts






Header:
lda #$80
sta $88 ; Count
lda #$00
sta $81
Header.Loop:
jsr Read
inc $88 ; Count
lda #$88
cmp $88 ; Count
bcs Header.Loop:
lda $80 ; copy LOCATION to COUNT
sta $88
lda $81
sta $89
Header.SignatureCompare:
lda #$4A
cmp $86
beq Header.Skip
lda #$44
cmp $87
beq Header.Skip
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
Header.Skip:
rts



Checksum:
lda $8a
cmp $84
bne Checksum.Invalid:
lda $8b
cmp $85
bne Checksum.Invalid
rts
Checksum.Invalid:
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


.org $FFFC
.word Entrypoint
