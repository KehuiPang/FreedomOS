org 7c00h

;================================================
;开始执行代码
jmp LABEL_START

;================================================
;常量
STACK_LEN	equ	50h
BASE_STACK 	equ 7c00h 
;================================================
;堆栈段


;================================================
;变量
msg_welcome: 
	db "Hello FreedomOS~",0
msg_boot:
	db "Booting ........",0
msg_loader:
	db "loading loader .........",0
msg_kernel:
	db "loading kernel .............",0
msg_run:
	db "running kernel .............",0
;================================================
;真正开始执行处
LABEL_START:
	mov 	ax,cs
	mov		ds,ax
	mov 	es,ax
	mov 	ss,ax
	mov 	sp,BASE_STACK

	call 	clear_screen
	call 	set_screen_mode

	mov 	ax,msg_welcome
	call 	print_str_line	
	call 	demo
	jmp 	$
;--------------------------------------
;功能描述：
;	键盘输入并回显
;参数
;	无
;返回值
;	AL=输入字符
;调用中断
;	INT 21H
;参考
;	AH＝01H
demo:
	int 12h
	xor dx,dx
	call print_num

	ret

;--------------------------------------
;功能描述：
;	在当前光标处按原有属性显示字符
;参数
;	AL＝字符
;返回值
;	无
;调用中断
;	int 10h
;参考
;	AH＝0AH
;	BH＝显示页码
;	BL＝颜色(图形模式，仅适用于PCjr)
;	CX＝重复输出字符的次数

print_char:
	pusha

	mov ah,0ah 			
	mov bh,0
	mov bl,0Ch
	mov cx,1			
	int 10h

	call read_cursor_info
	inc dl	
	call set_cursor_position

	popa
	ret
;--------------------------------------
;功能描述：
;	在当前光标处按原有属性显示数字
;	仅能输出09ffffh(655359)及以下的数值
;参数
;	DX=高位数字
;	AX＝低位数字
;返回值
;	无
;调用中断
;	int 10h
;参考
;	AH＝0AH
;	BH＝显示页码
;	BL＝颜色(图形模式，仅适用于PCjr)
;	CX＝重复输出字符的次数

print_num:
	push ax
	push bx
	push cx

	xor cx,cx
	xor bx,bx
	mov bx,10	;10进制
.neq:			;至少会执行一次下面的代码
	div bx
	push dx		;暂存余数
	xor dx,dx	;清空余数,用来存放被除数的高位
	inc cx 		;累计数字的个数
	cmp ax,0	;是否被除完
	jne .neq
	
.for:
	pop ax		;取出暂存的数字
	add al,30h
	call print_char 	;显示数字
	loop .for

	pop cx
	pop bx
	pop ax
	ret
;--------------------------------------
;功能描述：
;	在Teletype模式下显示字符串
;参数
;	AX = 显示字符串的地址 
;	BX = 是否换行(0:不换行;非零:换行)
;返回值 
;	无
;调用中断
;	int 10h
;参考
;	AH＝13H	
;	BH＝页码
;	BL＝属性(若AL=00H或01H)
;	CX＝显示字符串长度
;	(DH、DL)＝坐标(行、列)
;	ES:BP＝显示字符串的地址 
;	AL＝显示输出方式
;		0——字符串中只含显示字符，其显示属性在BL中。显示后，光标位置不变
;		1——字符串中只含显示字符，其显示属性在BL中。显示后，光标位置改变
;		2——字符串中含显示字符和显示属性。显示后，光标位置不变
;		3——字符串中含显示字符和显示属性。显示后，光标位置改变
print_str:
	pusha
	push bx

	call read_cursor_info ;读出光标所在的位置,自动把返回值设值给DH和DL

	mov bp,ax		;字符串首地址
	mov si,ax		;字符串首地址
	call get_string_len
	mov cx,ax		;字符串长度
	mov ah,13h		;显示字符串
	mov al,01h		;输出模式 字符串中只含显示字符，其显示属性在BL中。显示后，光标位置改变
	mov bh,0 		;显示页码
	mov bl,09h		;显示黑底蓝字
	int 10h	

	pop bx
	cmp bx,0
	je  .old_line
	call read_cursor_info
	inc dh
	xor dl,dl
	call set_cursor_position
.old_line:
	popa
	ret 
;--------------------------------------
;功能描述：
;	在Teletype模式下显示字符串并换行
;参数
;	AX = 显示字符串的地址 
;返回值 
;	无
print_str_line:
	mov  bx,1
	call print_str
	ret

;--------------------------------------
;功能描述：
;	在文本坐标下，读取光标各种信息
;参数
;	无
;返回值
;	CH＝光标的起始行
;	CL＝光标的终止行
;	DH＝行(Y坐标)
;	DL＝列(X坐标)
;调用中断
;	AH＝03H
;	BH＝显示页码
;	int 10h
read_cursor_info:
	push ax
	push bx

	mov bh,0 			;页号
	mov ah,03h			;用文本坐标下设置光标位置
	int 10h

	pop bx
	pop ax
	ret

;--------------------------------------
;功能描述：
;	用文本坐标下 设置光标位置
;参数
;	DH＝行(Y坐标)
;	DL＝列(X坐标)
;返回值
;	无
;调用中断
;	AH=02H 	设置光标位置
;	int 10h
set_cursor_position:
	push ax

	mov ah,02h			;用文本坐标下设置光标位置
	int 10h

	pop ax
	ret


;--------------------------------------
;功能描述：
;	计算字符串的长度
;参数
;	ds:si=字符串的地址
;返回值 
;	ax=字符串的长度
get_string_len:
	push si
	push cx
	mov cx,0 		;字符串长度
.if:
	cmp byte [si],0
	jz	.end
	inc cx
	inc si
	jmp .if
.end:	
	mov ax,cx
	pop cx
	pop si
	ret	

;--------------------------------------
;功能描述：
;	清空屏幕
;调用中断
;	int 10h
clear_screen:
	pusha

	mov al,0
	mov bh,07h
	mov cx,0
	mov dh,24
	mov dl,79
	int 10h

	popa
	ret
;--------------------------------------
;功能描述：
;	设置显示模式
;调用中断
;	int 10h
set_screen_mode:
	push ax

	mov ah,0 		;设定显示模式
	mov al,03h		;文字 80*25 
	int 10h			;BIOS 对屏幕及显示器所提供的服务程序

	pop ax
	ret
;================================================
;按规则填充满引导扇区
times 510-($-$$) db 0
dw 0xaa55
