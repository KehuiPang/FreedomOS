@echo on

::编译引导boot.bin
call "./tools/nasm" boot/boot.asm -o boot/boot.bin
::编译引导loader.bin
call "./tools/nasm" loader/loader.asm -o loader/loader.bin


::引导boot.bin文件写入镜像文件的第一扇区
call "./tools/SectionTool.exe" boot/boot.bin FreedomOS.img

::运行系统
call "./tools/bochs.exe" -q -f etc/bochsrc.bxrc