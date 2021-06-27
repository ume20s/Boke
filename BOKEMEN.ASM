title	ぼけてしまったデバイスドライバ
;	ぼけてしまったデバイスドライバ <BOKEMEN.ASM>
;		1989-05-08

;	device header

INCLUDE		dev.h

code		segment byte public	'code'
		assume CS:code, DS:code, ES:code, SS:code
		
		extrn	init:near

;デバイスヘッダ
header		dd	-1		;デバイスリンク
		dw	8000h		;キャラクタデバイスなんだよ
		dw	strategy	;ストラテジエントリ
		dw	interrupt	;割り込みエントリ
		db	'BOKEKE  '	;デバイス名

packetaddr	dd	?
savess		dw	?
savesp		dw	?

		dw	128 dup (?)	;デバイスドライバ内スタック領域
stackarea	label	near
;ジャンプテーブル
jumptable	dw	init		;初期化
		dw	nonnon		;あとはなーんもしない
		dw	nonnon		; 2
		dw	nonnon		; 3
		dw	nonnon		; 4
		dw	nonnon		; 5
		dw	nonnon		; 6
		dw	nonnon		; 7
		dw	nonnon		; 8
		dw	nonnon		; 9
		dw	nonnon		;10
		dw	nonnon		;11
		dw	nonnon		;12
		dw	nonnon		;13
		dw	nonnon		;14
		dw	nonnon		;15
		dw	nonnon		;16

;ストラテジエントリ
strategy	proc	far
		mov	word ptr cs:packetaddr,bx
		mov	word ptr cs:packetaddr+2,es
		ret
strategy	endp

;割り込みエントリ
interrupt	proc	far
		irp	reg,<ax,bx,cx,dx,bp,si,di,ds,es>
			push reg
		endm
		mov	ax,cs
		mov	ds,ax
		cli
		mov	savess,ss
		mov	savesp,sp
		mov	ss,ax
		mov	sp,offset stackarea
		sti
		
		les	bx,packetaddr
		xor	ax,ax
		mov	al,es:[bx._cmd]
		cmp	al,MAXCMD
		jna	interrupt0
		mov	al,ERRCN
		mov	ah,BITDONE+BITERR
		jmp	short interruptexit
interrupt0:
		mov	si,offset jumptable
		add	si,ax
		add	si,ax
		call	[si]

interruptexit:
		les	bx,packetaddr
		mov	es:[bx._status],ax
		
		cli
		mov	ax,savess
		mov	ss,ax
		mov	sp,savesp
		sti
		irp	reg,<es,ds,di,si,bp,dx,cx,bx,ax>
			pop	reg
		endm
		ret
interrupt	endp

nonnon		proc	near
		mov	ax,STATOK
		ret
nonnon		endp

code		ends
		end
