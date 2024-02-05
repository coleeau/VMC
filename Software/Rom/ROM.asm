;****************************************************
;*													*
;*					Build this file!				*
;*													*
;****************************************************
.pc02
.FEATURE String_Escapes
.INCLUDE		"../IO_DEF.asm"











.CODE

.INCLUDE 		"Mon.asm"
.INCLUDE 		"Bios.asm"







.ORG			$FF00
.INCLUDE		"Bios.inc"


.SEGMENT "VEC"
.word B_Panic
.word Entrypoint
.word IRQ_Entrypoint


