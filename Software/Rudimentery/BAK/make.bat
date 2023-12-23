ECHO ON
CD ../cc65/bin
START ca65.exe ../../micro/rudimentery_label_loop_256.asm -o ../../micro/rudimentery_label_loop_256.o
START ld65.exe ../../micro/rudimentery_label_loop_256.o -C ../../micro/vmc_fe.cfg -o ../../micro/out256.bin
PAUSE