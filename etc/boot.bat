@echo on

::更新boot.bin
del boot.bin

::延迟1秒执行
choice /t 1 /d y /n >nul

::编译引导boot.bin
nasm boot.asm -o boot.bin

pause