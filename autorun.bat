@echo on

::��������boot.bin
call "./tools/nasm" boot/boot.asm -o boot/boot.bin
::��������loader.bin
call "./tools/nasm" loader/loader.asm -o loader/loader.bin


::����boot.bin�ļ�д�뾵���ļ��ĵ�һ����
call "./tools/SectionTool.exe" boot/boot.bin FreedomOS.img

::����ϵͳ
call "./tools/bochs.exe" -q -f etc/bochsrc.bxrc