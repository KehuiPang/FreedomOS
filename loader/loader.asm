;loader
;任务
;	把内核加载到内存
org 0100h

mov ax,0B800h
mov gs,ax
mov ah,0fh 			;黑底白字
mov al,'F'
mov [gs:(80*2+0)*2],ax	;在第二行0列显示字符
jmp $