ECHO ON
CD ../../cc65/bin
START /wait ca65.exe ../../micro/Rudimentery/rudimentery_label_loop_256_chksm_stack_commentless.asm -o ../../micro/Rudimentery/rudimentery_label_loop_256_chksm_stack_commentless.o 
START /wait ld65.exe ../../micro/Rudimentery/rudimentery_label_loop_256_chksm_stack_commentless.o -C ../../micro/vmc_fe.cfg -o ../../micro/Rudimentery/out256_stack_commentless.bin
PAUSE