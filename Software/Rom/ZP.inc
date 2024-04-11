;************************************
;*				Memory				*
;************************************
ZP_Math_1						:=			$E0
ZP_Math_2						:=			$E1
ZP_Math_3						:=			$E2
ZP_Math_4						:=			$E3
ZP_Pointer1_LSB					:=			$E4
ZP_Pointer1_MSB					:=			$E5
ZP_Pointer2_LSB					:=			$E6
ZP_Pointer2_MSB					:=			$E7
ZP_Mon_Bak_A					:=			$E8
ZP_Mon_Bak_X					:=			$E9
ZP_Mon_Bak_Y					:=			$EA
ZP_Mon_Bak_P					:=			$EB
ZP_Mon_Bak_SP					:=			$EC


ZP_Interupt_Stat				:=			$F0		; b7= timer b6= Serial     b0=Newkey
ZP_Key_Buffer_Pointer			:=			$F1
ZP_Key_Buffer_Read_Pointer		:=			$F2
ZP_Bios_Error					:=			$F3		;b7=keyboard buffer overflow  b6=Data routine Error (Check ZP_Scratch_3)	b0=timer source 0=cpuclk 1=clk2
ZP_INT_BSR_MIRROR				:=			$F4
ZP_INT_TIE_MIRROR				:=			$F5
ZP_INT_PANIC_1					:=			$F6		; Not reserved per say, but will be destroyed if B_B_Panic is called. 
ZP_Bios_Flags					:=			$F7		;b7= kb/serial buffer location 0=$0200 1=ZP_Pointer1
ZP_INT_SCRATCH_1				:=			$F8
ZP_INT_SCRATCH_2				:=			$F9
ZP_INT_SCRATCH_3				:=			$FA
ZP_INT_SCRATCH_4				:=			$FB
ZP_INT_SCRATCH_5				:=			$FC
ZP_INT_SCRATCH_6				:=			$FD









