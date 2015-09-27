@echo on

::更新boot.bin
del boot.bin

::延迟1秒执行
choice /t 1 /d y /n >nul

::编译引导boot.bin
nasm boot.asm -o boot.bin

::引导boot.bin文件写入镜像文件的第一扇区
SectionTool.exe

::运行系统
bochs.exe -q -f bochsrc.bxrc