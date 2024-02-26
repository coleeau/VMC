;****************************************************
;*													*
;*					Build this file!				*
;*													*
;****************************************************
.pc02
.FEATURE String_Escapes
.INCLUDE		"../IO_DEF.asm"
.INCLUDE		"ZP.inc"









.SEGMENT 	"ROM_LOWER"
.ASCIIZ		"Rom for VCM 1.0\r\nJ. Donovan 2024"
.SEGMENT 	"ROM_UPPER"

.INCLUDE 		"Mon.asm"
.INCLUDE 		"Bios.asm"







;.ORG			$FF00
.INCLUDE		"Bios.inc"


.SEGMENT "VEC"
.word B_Panic
.word Entrypoint
.word IRQ_Entrypoint


