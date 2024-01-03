;************************************************************************************
;*																					*
;*								VMC Bios for Rev 1									*
;*																					*
;*		By Jake Donovan			started on 1/3/2024									*
;*																					*
;************************************************************************************

; features
;
; --------hardware---------
;




























;************************************
;*				Memory				*
;************************************









;************************************
;*				Main  				*
;************************************





; ======Video=====
; 
; Set mode 
;				(initiallize screen to specific settings
; chram copy
;		 point to a location and copy into chram at a specific location in chram. 
;		header is optional, compression is optional (likely rle)
; smooth scroll
; 		vertical and horizontal. will need to be called once per frame
;		https://www.cpcwiki.eu/index.php/Programming:Hardware_scrolling_the_screen_using_the_CRTC
; vid bank swap CPU
;		switches what bank is visible to cpu. currently only vram, can be updated to include chram
; vid bank swap crtc
;		same as above, just for crtc
;

; ======Keyboard=======
; readkey
;		read currently pressed key, not irq
;
; ======timer=====
; Timer setup
;	 	enable, and start timer of certain length
; pulse
;		specifiy frequency and period for one or both channels
; pulse mute
;		mute one or both channels
;
;
; ======Serial=======
; rx char
;		 recive one char, destination set in command or from table
; rx n char
;		 recive n charecters, destination set in command or from table
; rx term char
;		recive charecters until a specified termination value is recived (ie nul, cr, etc)
; set speed
;		self explanitory
; tx char
;		send one charecter
; tx n char
;		send n char from location specified in command or in table
;tx char term
;		send char until termination found. location specified in command or in table
; flow control settings
; fifo setings

; =====i2c=====
; send 
;		send packet from stack or specified in command or in table
; read
;		read packet and store at a specified buffer (option to wait for response)
;
;
; ======clock======
; set cpu speed
; set video speed (might not be its own thing due to trying to avoid doing that)
; set clk2 speed

; ======bankswitch====== (might combine all 3 into 1 command) (ie 2 msb control mode, and 6 lsb controls what is actually switched)
; ram bankswitch
; rom bankswitch
; chram bankswitch







; --------- local routines ---------
; ======8bit======
; 8bit multi
; 8bit divide
;
;  ======16bit======
;   16bit inc/dec
;   16bit add/sub
;   16bit multiply
;   16bit divide
;
; =======data tools=======
; rle encode
; rle decode
; lzs encode
; lzs decode
;  copy
; ROM UPDATE
;
; =======