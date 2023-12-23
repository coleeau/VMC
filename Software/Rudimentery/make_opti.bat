ECHO ON
CD C:\Users\jaked\Desktop\cc65\bin
START /wait 2>&1 ca65.exe ../../micro/Software/Rudimentery/rudimentery_optimized.asm -o ../../micro/Software/Rudimentery/rudimentery_optimized.o 
START /wait 2>&1 ld65.exe ../../micro/Software/Rudimentery/rudimentery_optimized.o -C ../../micro/vmc_fe.cfg -o ../../micro/Software/Rudimentery/out256_optimized.bin 
PAUSE /?

