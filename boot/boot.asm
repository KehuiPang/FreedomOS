org 7c00h

;================================================
;开始执行代码
jmp short LABEL_START				;2字节
nop 								;1字节
;================================================
;BPB结构和BS参数
;下面是FAT12磁盘的头
BS_OEMName 		db	'FreedoOS'		;厂商名,8字节
BPB_BytsPerSec	dw	0x200			;每扇区字节数（即十进制512）	
BPB_SecPerClus	db  0x01			;每簇扇区数
BPB_RsvdSecCnt	dw	0x01			;Boot记录占用多少扇区
BPB_NumFATs		db	0x02			;共有多少FAT表
BPB_RootEntCnt	dw	0xE0			;根目录文件数最大值（224）
BPB_TotSec16	dw	0xB40			;扇区总数（2880）
BPB_Media		db	0xF0			;介质描述符(f0:软盘;f8:硬盘)
BPB_FATSz16		dw	0x09			;每FAT扇区数
BPB_SecPerTrk	dw	0x12			;每磁道扇区数
BPB_NumHeads	dw	0x02			;磁头数
BPB_HiddSec		dd	0				;隐藏扇区数
BPB_TotSec32	dd	0xB40			;如果BPB_TotSec16是0，由这个值记录扇区数（2880）
BS_DrvNum		db	0				;中断13的驱动器号
BS_Reserved1	db	0				;未使用
BS_BootSig		db	0x29			;扩展引导标记
BS_VolID		dd	0				;卷序列号
BS_VolLab		db	'FreedoOS   '	;卷标,必须11字节
BS_FileSysType	db	'FAT12   '		;文件系统类型,必须8字节


;================================================
;常量
STACK_LEN	equ	50h
BASE_STACK 	equ 7c00h 
;缓存区
CHACH_DATA 	equ 7e00h
;进制
SCALE		equ 16

;================================================
;变量
msg_welcome: 
	db "Hello FreedomOS~",0
;文件名
filename_loader:
	db "loader",0
;================================================
;真正开始执行处
LABEL_START:
	mov 	ax,cs
	mov		ds,ax
	mov 	es,ax
	mov 	ss,ax
	mov 	sp,BASE_STACK
	;初始化
	call 	clear_screen
	call 	set_screen_mode
	call 	reset_floppy
	;打印欢迎信息
	mov 	ax,msg_welcome
	call 	print_str_line	
	;读扇区
	mov 	ax,0			;起始扇区号
	mov 	cl,2
	mov 	bx,CHACH_DATA
	call 	read_section
	;打印内存数据
	mov 	cx,512
	mov 	si,CHACH_DATA
	call 	print_mem_data
	jmp 	$
;--------------------------------------
;功能描述：
;	寻找loader文件,并加载到内存,然后运行改文件
;参数
;	无
;返回值
;	无
run_loader:
	push bp
	mov bp,sp


	pop bp
	ret

;--------------------------------------
;功能描述：
;	打印内存的一块区域数据
;参数
;	ds:si=数据的起始地址
;	cx=打印数据的长度
;返回值
;	无
print_mem_data:
	pusha

	xor 	bx,bx
.print_data:
	xor 	dx,dx
	xor 	ax,ax

	mov 	al,byte [ds:si]
	call 	print_num
	inc 	si

	mov 	al,' '			;打印分隔符空格
	call 	print_char
	loop 	.print_data 	;循环打印

	popa
	ret
;--------------------------------------
;功能描述：
;	复位软盘
;参数
;	无
;返回值
;	无
;调用中断
;	int 13h
reset_floppy:
	push  	ax
	xor 	ax,ax
	int 	13h
	pop 	ax
	ret

;--------------------------------------
;功能描述：
;	读取指定磁盘扇区的数据(读扇区)
;参数
;	ax=起始扇区号
;	cl=连续查询的扇区数
;	es:bx=存放数据的地址
;返回值
;	无
;调用中断
;	int 13h
;参考
;	入口参数：
;		AH=02H
;		AL=扇区数
;		CH=柱面
;		CL=扇区
;		DH=磁头
;		DL=驱动器，00H~7FH：软盘；80H~0FFH：硬盘
;		ES:BX＝缓冲区的地址
;	出口参数：CF=0——操作成功，AH=00H，AL=传输的扇区数，否则，AH=状态代码
; 	设扇区号为 x
;                           ┌ 柱面号 = y >> 1
;       x           ┌ 商 y ┤
; -------------- => ┤      └ 磁头号 = y & 1
;  	每磁道扇区数    │
;                   └ 余 z => 起始扇区号 = z + 1
read_section:
	push bp
	mov bp,sp
	sub sp,2
	mov byte [bp-2],cl
	push bx
	mov bl,[BPB_SecPerTrk]
	div bl
	mov cl,ah
	inc cl
	mov dh,al
	shr al,2
	mov ch,al
	and dh,1h
	mov dl,[BS_DrvNum]
	pop bx
.GoOnReading:
	mov ah,2
	mov al,[bp-2]
	int 13h
	jc .GoOnReading
	add sp,2
	pop bp
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

	;去掉每行开头的空格,使各行对齐
	;if(dl==0&&当前的字符==' '){;}else{cursor_forward();}
	call    read_cursor_info
	cmp 	dl,0
	jne 	.cursor_forward
	cmp 	al,' '
	je 		.end
	call	cursor_forward
	jmp  	.end
.cursor_forward:
	call cursor_forward
.end:
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
	mov bx,SCALE;10进制,bx数值为几就为几进制
.neq:			;至少会执行一次下面的代码
	div bx
	push dx		;暂存余数
	xor dx,dx	;清空余数,用来存放被除数的高位
	inc cx 		;累计数字的个数
	cmp ax,0	;是否被除完
	jne .neq
	;if(SCALE==16&&cx==1)print_char('0')
	cmp bx,16
	jne .for
	cmp cx,1
	jne .for
	mov al,'0'
	call print_char
.for:
	pop ax				;取出暂存的数字
	;if(al>9){al=al-10+65;}else{al+=48}
	cmp al,9
	jbe .else
	add al,37h
	jmp .end
.else:
	add al,30h
.end:
	call print_char 	;显示数字或字母
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
;	用文本坐标下 向后移动一格光标光标位置
;参数
;	无
;返回值
;	无
cursor_forward:
	call read_cursor_info
.if:
	cmp dl,79			;if(dl>79){dh++;dl=0;}else{al++}
	jb  .else
	xor  dl,dl
	inc  dh
	jmp  .end
.else:
	inc dl	
.end:
	call set_cursor_position

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
