@echo on

::����boot.bin
del boot.bin

::�ӳ�1��ִ��
choice /t 1 /d y /n >nul

::��������boot.bin
nasm boot.asm -o boot.bin

::����boot.bin�ļ�д�뾵���ļ��ĵ�һ����
SectionTool.exe

::����ϵͳ
bochs.exe -q -f bochsrc.bxrc