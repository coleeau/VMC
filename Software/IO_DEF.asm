;vmc io map


; might want to set up some different calling method that is more compact (ie x= register adress, y sub adress, a value written/read)

; register 00 6545 crt controller
R_CRTC_REG_SEL 	:= $6000
R_CRTC_REG		:= $6001

; register 01 Ascii Keyboard
R_KEYB			:= $6010


; register 02 Timer Enable Register
R_TIE 			:= $6020

; register 03
R_TIME_0		:= $6030
R_TIME_1		:= $6031
R_TIME_2		:= $6032
R_TIME_CTRL		:= $6033

; register 03
;RESERVED

; register 04
;RESERVED

; Register 05 PIA
R_PIA_GPIO		:= $6050
R_PIA_GPIO_CTRL	:= $6051
R_PIA_JOY		:= $6052
R_PIA_I2C		:= $6052
R_PIA_JOY_CTRL	:= $6053
R_PIA_I2C_CTRL	:= $6053

; Register 06
;RESERVED

; Register 07 16c550
R_COMM_TXRX			:= $6070
R_COMM_DIV_LSB		:= $6070
R_COMM_IRQ_ENA		:= $6071
R_COMM_DIV_MSB		:= $6071
R_COMM_FIFO_CTRL	:= $6072
R_COMM_IRQ_STAT		:= $6072
R_COMM_LINE_CTRL	:= $6073
R_COMM_MODM_CTRL	:= $6074
R_COMM_LINE_STAT	:= $6075
R_COMM_MODM_STAT	:= $6076
R_COMM_SPAR			:= $6077

; Register 7F Bank Select
R_BANK_SEL		:= $67F0
