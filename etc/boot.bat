@echo on

::����boot.bin
del boot.bin

::�ӳ�1��ִ��
choice /t 1 /d y /n >nul

::��������boot.bin
nasm boot.asm -o boot.bin

pause