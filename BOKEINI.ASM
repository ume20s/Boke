title   ぼけ初期化
;

INCLUDE		dev.h

code		segment byte public	'code'
		assume CS:code, DS:code, ES:code, SS:code
		
		public	init

init		proc	near
		irp	reg,<ax,bx,cx,dx,bp,si,di,ds,es>
			push reg
		endm
		
		;****************************************
		;*** STOP キー の割り込みベクトル設定 ***
		;****************************************
		push	ds
		push	es
		xor	ax,ax
		mov	es,ax
		xor	bx,bx
		mov	ah,35h
		mov	al,23h
		int	21h
		mov	ax,es
		mov	word ptr stop_seg,ax
		mov	word ptr stop_off,bx
		mov	ax,cs
		mov	ds,ax
		mov	dx,offset stopkey
		mov	ah,25h
		mov	al,23h
		int	21h
		pop	es
		pop	ds
		jmp	main
		
		;************************
		;*** STOP キー の処理 ***
		;************************
stopkey:	cli
		mov	al,0ffh
		out	02,al
		mov	al,01h
		mov	stflag,al
		mov	dx,offset cr
		mov	ah,09h
		int	21h
		mov	bl,bufstr
		and	bl,03h
st0:		cmp	bl,00h
		jne	st1
		mov	dx,offset stopmes0
		mov	ah,09h
		int	21h
		jmp	stopquit
st1:		cmp	bl,01h
		jne	st2
		mov	dx,offset stopmes1
		mov	ah,09h
		int	21h
		jmp	stopquit
st2:		cmp	bl,02h
		jne	st3
		mov	dx,offset stopmes2
		mov	ah,09h
		int	21h
		jmp	stopquit
st3:		mov	dx,offset stopmes3
		mov	ah,09h
		int	21h
stopquit:	mov	dx,offset cr
		mov	ah,09h
		int	21h
		inc	bl
		mov	bufstr,bl
		mov	ax,cs
		mov	ds,ax
		mov	al,00h
		out	02h,al
		mov	al,20h
		out	0,al
		sti
		iret
		
		;**************************
		;*** 組み込みメッセージ ***
		;**************************
main:		mov	dx,offset msg
		mov	ah,09h
		int	21h
		
		;****************************
		;*** コマンド・バージョン ***
		;****************************
		mov	dx,offset comver
		mov	ah,09h
		int	21h
		mov	ah,30h
		int	21h
		mov	bl,ah
		add	al,30h
		mov	dl,al
		mov	ah,02h
		int	21h
		mov	dl,2eh
		mov	ah,02h
		int	21h	;'.'
		mov	al,bl
		aam
		or	ax,3030h
		mov	bl,al
		mov	dl,ah
		mov	ah,02h
		int	21h
		mov	dl,bl
		mov	ah,02h
		int	21h
		mov	dx,offset comverend
		mov	ah,09h
		int	21h
		
		;************************
		;*** プロンプトと入力 ***
		;************************
input:		mov	dx,offset cr
		mov	ah,09h
		int	21h
		mov	dx,offset prompt
		mov	ah,09h
		int	21h
		
		mov	dx,offset bufmax
		mov	ah,0ah
		int	21h
		
		;******************************
		;*** STOP キー だったかな？ ***
		;******************************
		mov	al,stflag
		cmp	al,00h
		je	kaiseki
		xor	al,al
		mov	stflag,al
		jmp	input
		
		;****************************
		;*** リターンキーのみかな ***
		;****************************
kaiseki:	mov	dx,offset cr
		mov	ah,09h
		int	21h
		xor	bx,bx
		mov	bl,bufcnc
		cmp	bl,00h
		jne	henkan
		mov	dx,offset retnomi
		mov	ah,09h
		int	21h
		jmp	input
		
		;***************************
		;*** 大文字→小文字 変換 ***
		;***************************
henkan:		xor	cx,cx
		mov	cl,bufcnc
		xor	si,si
hepick:		mov	al,[bufstr+si]
		cmp	al,41h
		jb	nextchar
		cmp	al,5ah
		ja	nextchar
		add	al,20h
		mov	[bufstr+si],al
nextchar:	inc	si
		loop	hepick
		
		;****************************
		;*** 重複コマンドチェック ***
		;****************************
		xor	cx,cx
		mov	cl,bufcnc
		mov	al,comcnc
		cmp	al,cl
		jne	comstore
		xor	si,si
mojicheck:	mov	al,[comstr+si]
		mov	bl,[bufstr+si]
		cmp	al,bl
		jne	comstore
		inc	si
		loop	mojicheck
		mov	dx,offset onaji
		mov	ah,09h
		int	21h
		jmp	input
comstore:	xor	cx,cx
		mov	cl,bufcnc
		inc	cl
		xor	si,si
comst:		mov	al,[bufcnc+si]
		mov	[comcnc+si],al
		inc	si
		loop	comst
		
		;********************************
		;*** ？または１文字メッセージ ***
		;********************************
hitomoji:	mov	al,bufcnc
		cmp	al,01h
		jne	ch_dir
		mov	al,bufstr
		cmp	al,'?'
		jne	out_hitomoji
		dec	al
		mov	bufstr,al
		mov	dx,offset hatemes1
		mov	ah,09h
		int	21h
		mov	ah,07h
		int	21h
		mov	dx,offset hatemes2
		mov	ah,09h
		int	21h
dekiru:		mov	dx,offset hatemes3
		mov	ah,09h
		int	21h
		mov	ah,08h
		int	21h
		mov	al,stflag
		cmp	al,00h
		jne	dekiru_to_inp
		mov	dx,offset cr
		mov	ah,09h
		int	21h
		mov	dx,offset hatemes4
		mov	ah,09h
		int	21h
		mov	ah,08h
		int	21h
		mov	al,stflag
		cmp	al,00h
		jne	dekiru_to_inp
		mov	dx,offset cr
		mov	ah,09h
		int	21h
		jmp	dekiru
dekiru_to_inp:	xor	al,al
		mov	stflag,al
		jmp	input
		
out_hitomoji:	mov	dx,offset hitomes
		mov	ah,09h
		int	21h
		jmp	input
		
		;**************
		;*** ｄｉｒ ***
		;**************
ch_dir:		mov	al,bufstr
		cmp	al,'d'
		jne	ch_ls
		mov	al,bufstr+1
		cmp	al,'i'
		jne	ch_dir_mes16
		mov	al,bufstr+2
		cmp	al,'r'
		jne	ch_dir_mes16
		mov	al,bufstr+3
		cmp	al,' '
		je	ch_dir_out
		cmp	al,0dh
		je	ch_dir_out
ch_dir_mes16:	jmp	mes16
ch_dir_out:	mov	dx,offset dirmes
		mov	ah,09h
		int	21h
		jmp	input
		
		;************
		;*** ｌｓ ***
		;************
ch_ls:		mov	al,bufstr
		cmp	al,'l'
		jne	ch_sl
		mov	al,bufstr+1
		cmp	al,'s'
		jne	ch_log
		mov	al,bufstr+2
		cmp	al,' '
		je	ch_ls_out
		cmp	al,0dh
		je	ch_ls_out
ch_ls_mes16:	jmp	mes16
ch_ls_out:	mov	dx,offset lsmes
		mov	ah,09h
		int	21h
		jmp	input
		
		;**************
		;*** ｌｏｇ ***
		;**************
ch_log:		mov	al,bufstr+1
		cmp	al,'o'
		jne	ch_log_mes16
		mov	al,bufstr+2
		cmp	al,'g'
		je	ch_log_out
ch_log_mes16:	jmp	mes16
ch_log_out:	mov	dx,offset logmes
		mov	ah,09h
		int	21h
		jmp	input
		
		;************
		;*** ｓｌ ***
		;************
ch_sl:		mov	al,bufstr
		cmp	al,'s'
		jne	ch_exit
		mov	al,bufstr+1
		cmp	al,'l'
		jne	ch_sl_mes16
		mov	al,bufstr+2
		cmp	al,' '
		je	ch_sl_out
		cmp	al,0dh
		je	ch_sl_out
ch_sl_mes16:	jmp	mes16
ch_sl_out:	mov	dx,offset slmes
		mov	ah,09h
		int	21h
		mov	ah,07h
		int	21h
		mov	dx,offset cr
		mov	ah,09h
		int	21h
syuppo:		mov	al,stflag
		cmp	al,00h
		je	syuppo_out
		xor	al,al
		mov	stflag,al
		jmp	input
syuppo_out:	mov	dx,offset slmes1
		mov	ah,09h
		int	21h
		jmp	syuppo
		
		;****************
		;*** ｅｘｉｔ ***
		;****************
ch_exit:	mov	al,bufstr
		cmp	al,'e'
		jne	ch_cls
		mov	al,bufstr+1
		cmp	al,'x'
		jne	ch_end
		mov	al,bufstr+2
		cmp	al,'i'
		jne	ch_exit_mes16
		mov	al,bufstr+3
		cmp	al,'t'
		jne	ch_exit_mes16
		mov	al,bufstr+4
		cmp	al,' '
		je	ch_exit_out
		cmp	al,0dh
		je	ch_exit_out
ch_exit_mes16:	jmp	mes16
ch_exit_out:	mov	dx,offset exitmes
		mov	ah,09h
		int	21h
		jmp	input
		
		;**************
		;*** ｅｎｄ ***
		;**************
ch_end:		mov	al,bufstr+1
		cmp	al,'n'
		jne	ch_end_mes16
		mov	al,bufstr+2
		cmp	al,'d'
		jne	ch_end_mes16
		mov	al,bufstr+3
		cmp	al,' '
		je	ch_end_out
		cmp	al,0dh
		je	ch_end_out
ch_end_mes16:	jmp	mes16
ch_end_out:	mov	dx,offset endmes
		mov	ah,09h
		int	21h
		jmp	input
		
		;**************
		;*** ｃｌｓ ***
		;**************
ch_cls:		mov	al,bufstr
		cmp	al,'c'
		jne	ch_boke
		mov	al,bufstr+1
		cmp	al,'l'
		jne	ch_cls_mes16
		mov	al,bufstr+2
		cmp	al,'s'
		jne	ch_cls_mes16
		mov	al,bufstr+3
		cmp	al,0dh
		je	ch_cls_out
ch_cls_mes16:	jmp	mes16
ch_cls_out:	mov	dx,offset clsmes
		mov	ah,09h
		int	21h
		jmp	input
		
		;****************
		;*** ｂｏｋｅ ***
		;****************
ch_boke:	mov	al,bufstr
		cmp	al,'b'
		jne	ch_reset
		mov	al,bufstr+1
		cmp	al,'o'
		jne	ch_boke_mes16
		mov	al,bufstr+2
		cmp	al,'k'
		jne	ch_boke_mes16
		mov	al,bufstr+3
		cmp	al,'e'
		jne	ch_boke_mes16
		mov	al,bufstr+4
		cmp	al,' '
		je	ch_boke_out
		cmp	al,0dh
		je	ch_boke_out
ch_boke_mes16:	jmp	mes16
ch_boke_out:	mov	dx,offset bokemes1
		mov	ah,09h
		int	21h
		mov	ah,07h
		int	21h
		mov	dx,offset cr
		mov	ah,09h
		int	21h
		mov	dx,offset bokemes2
		mov	ah,09h
		int	21h
		mov	ah,07h
		int	21h
		mov	dx,offset cr
		mov	ah,09h
		int	21h
		mov	dx,offset bokemes3
		mov	ah,09h
		int	21h
		mov	ah,07h
		int	21h
		mov	dx,offset cr
		mov	ah,09h
		int	21h
		mov	dx,offset bokemes4
		mov	ah,09h
		int	21h
		mov	ah,07h
		int	21h
		mov	dx,offset cr
		mov	ah,09h
		int	21h
		mov	dx,offset bokemes5
		mov	ah,09h
		int	21h
		jmp	input
		
		;********************
		;*** 　ｒｅｓｅｔ ***
		;********************
ch_reset:	mov	al,bufstr
		cmp	al,'r'
		jne	ch_and
		mov	al,bufstr+1
		cmp	al,'e'
		jne	ch_reset_mes16
		mov	al,bufstr+2
		cmp	al,'s'
		jne	ch_reset_mes16
		mov	al,bufstr+3
		cmp	al,'e'
		jne	ch_reset_mes16
		mov	al,bufstr+4
		cmp	al,'t'
		jne	ch_reset_mes16
		mov	al,bufstr+5
		cmp	al,0dh
		je	ch_reset_out
ch_reset_mes16:	jmp	mes16
ch_reset_out:	mov	dx,offset resetmes
		mov	ah,09h
		int	21h
		jmp	input
		
		;**************
		;*** ａｎｄ ***
		;**************
ch_and:		mov	al,bufstr
		cmp	al,'a'
		jne	ch_kq
		mov	al,bufstr+1
		cmp	al,'n'
		jne	ch_and_mes16
		mov	al,bufstr+2
		cmp	al,'d'
		jne	ch_and_mes16
		mov	al,bufstr+3
		cmp	al,0dh
		je	ch_and_out
ch_and_mes16:	jmp	mes16
ch_and_out:	mov	dx,offset andmes
		mov	ah,09h
		int	21h
		jmp	input
		
		;************
		;*** ／ｅ ***
		;************
ch_kq:		mov	al,bufstr
		cmp	al,'/'
		jne	mes16
		mov	al,bufstr+1
		cmp	al,'e'
		jne	ch_kq_mes16
		mov	al,bufstr+2
		cmp	al,0dh
		je	ch_kq_out
ch_kq_mes16:	jmp	mes16
ch_kq_out:	mov	dx,offset kqmes
		mov	ah,09h
		int	21h
		jmp	quit
		

		;************************
		;*** 知らないコマンド ***
		;************************
mes16:		xor	bx,bx
		mov	bl,comcnc
		mov	si,bx
		mov	[comstr+si],'$'
		
		dec	si
		dec	si
		xor	ax,ax
		mov	al,[comstr+si]
		and	al,0fh
		mov	bl,comstr
		add	al,bl
		add	al,bufcnc
		mov	bl,al
		and	bl,01fh
		
		cmp	bl,010h
		jb	siran0
		jmp	siranf
		
siran0:		cmp	bl,00h
		jne	siran1
		mov	dx,offset comstr
		mov	ah,09h
		int	21h
		mov	dx,offset sirames0
		mov	ah,09h
		int	21h
		jmp	siraquit
siran1:		cmp	bl,01h
		jne	siran2
		mov	dx,offset sirames1
		mov	ah,09h
		int	21h
		jmp	siraquit
siran2:		cmp	bl,02h
		jne	siran3
		mov	dx,offset sirames2
		mov	ah,09h
		int	21h
		jmp	siraquit
siran3:		cmp	bl,03h
		jne	siran4
		mov	dx,offset sirames3
		mov	ah,09h
		int	21h
		jmp	siraquit
siran4:		cmp	bl,04h
		jne	siran5
		mov	dx,offset comstr
		mov	ah,09h
		int	21h
		mov	dx,offset sirames4
		mov	ah,09h
		int	21h
		jmp	siraquit
siran5:		cmp	bl,05h
		jne	siran6
		mov	dx,offset sirames5_1
		mov	ah,09h
		int	21h
		mov	dx,offset comstr
		mov	ah,09h
		int	21h
		mov	dx,offset sirames5_2
		mov	ah,09h
		int	21h
		jmp	siraquit
siran6:		cmp	bl,06h
		jne	siran7
		mov	dx,offset sirames6
		mov	ah,09h
		int	21h
		jmp	siraquit
siran7:		cmp	bl,07h
		jne	siran8
		mov	dx,offset sirames7
		mov	ah,09h
		int	21h
		jmp	siraquit
siran8:		cmp	bl,08h
		jne	siran9
		mov	dx,offset sirames8
		mov	ah,09h
		int	21h
		jmp	siraquit
siran9:		cmp	bl,09h
		jne	sirana
		mov	dx,offset sirames9
		mov	ah,09h
		int	21h
		jmp	siraquit
sirana:		cmp	bl,0ah
		jne	siranb
		mov	dx,offset siramesa1
		mov	ah,09h
		int	21h
		mov	dx,offset comstr
		mov	ah,09h
		int	21h
		mov	dx,offset siramesa2
		mov	ah,09h
		int	21h
		mov	dx,offset comstr
		mov	ah,09h
		int	21h
		mov	dx,offset siramesa3
		mov	ah,09h
		int	21h
		mov	dx,offset comstr
		mov	ah,09h
		int	21h
		mov	dx,offset siramesa4
		mov	ah,09h
		int	21h
		jmp	siraquit
siranb:		cmp	bl,0bh
		jne	siranc
		mov	dx,offset siramesb
		mov	ah,09h
		int	21h
		jmp	siraquit
siranc:		cmp	bl,0ch
		jne	sirand
		mov	dx,offset siramesc
		mov	ah,09h
		int	21h
		jmp	siraquit
sirand:		cmp	bl,0dh
		jne	sirane
		mov	dx,offset siramesd1
		mov	ah,09h
		int	21h
		mov	dx,offset comstr
		mov	ah,09h
		int	21h
		mov	dx,offset siramesd2
		mov	ah,09h
		int	21h
		jmp	siraquit
sirane:		cmp	bl,0eh
		jne	siranf
		mov	dx,offset siramese1
		mov	ah,09h
		int	21h
		mov	dx,offset comstr
		mov	ah,09h
		int	21h
		mov	dx,offset siramese2
		mov	ah,09h
		int	21h
		jmp	siraquit
siranf:		cmp	bl,0fh
		jne	siran10
		mov	dx,offset siramesf
		mov	ah,09h
		int	21h
		jmp	siraquit
siran10:	cmp	bl,010h
		jne	siran11
		mov	dx,offset sirames10
		mov	ah,09h
		int	21h
		jmp	siraquit
siran11:	cmp	bl,011h
		jne	siran12
		mov	dx,offset sirames11
		mov	ah,09h
		int	21h
		jmp	siraquit
siran12:	cmp	bl,012h
		jne	siran13
		mov	dx,offset sirames12
		mov	ah,09h
		int	21h
		jmp	siraquit
siran13:	cmp	bl,013h
		jne	siran14
		mov	dx,offset sirames13
		mov	ah,09h
		int	21h
		jmp	siraquit
siran14:	cmp	bl,014h
		jne	siran15
		mov	dx,offset sirames14
		mov	ah,09h
		int	21h
		jmp	siraquit
siran15:	cmp	bl,015h
		jne	siran16
		mov	dx,offset sirames15
		mov	ah,09h
		int	21h
		jmp	siraquit
siran16:	cmp	bl,016h
		jne	siran17
		mov	dx,offset sirames16
		mov	ah,09h
		int	21h
		jmp	siraquit
siran17:	cmp	bl,017h
		jne	siran18
		mov	dx,offset sirames17
		mov	ah,09h
		int	21h
		jmp	siraquit
siran18:	cmp	bl,018h
		jne	siran19
		mov	dx,offset sirames18
		mov	ah,09h
		int	21h
		jmp	siraquit
siran19:	cmp	bl,019h
		jne	siran1a
		mov	dx,offset sirames19
		mov	ah,09h
		int	21h
		jmp	siraquit
siran1a:	cmp	bl,01ah
		jne	siran1b
		mov	dx,offset sirames1a
		mov	ah,09h
		int	21h
		jmp	siraquit
siran1b:	cmp	bl,01bh
		jne	siran1c
		mov	dx,offset sirames1b
		mov	ah,09h
		int	21h
		jmp	siraquit
siran1c:	cmp	bl,01ch
		jne	siran1d
		mov	dx,offset sirames1c
		mov	ah,09h
		int	21h
		jmp	siraquit
siran1d:	cmp	bl,01dh
		jne	siran1e
		mov	dx,offset sirames1d
		mov	ah,09h
		int	21h
		jmp	siraquit
siran1e:	cmp	bl,01eh
		jne	siran1f
		mov	dx,offset sirames1e
		mov	ah,09h
		int	21h
		jmp	siraquit
siran1f:	mov	dx,offset sirames1f
		mov	ah,09h
		int	21h
		
siraquit:	mov	dx,offset cr
		mov	ah,09h
		int	21h
		jmp	input
		
		;****************
		;*** 出口処理 ***
		;****************
quit:		push	ds
		push	es
		mov	ax,stop_seg
		mov	ds,ax
		mov	dx,stop_off
		mov	ah,25h
		mov	al,23h
		int	21h
		pop	es
		pop	ds
		
		irp	reg,<es,ds,di,si,bp,dx,cx,bx,ax>
			pop	reg
		endm
		
		mov	ax,offset init
		mov	word ptr es:[bx._addr],ax
		mov	ax,cs
		mov	word ptr es:[bx._addr+2],ax
		mov	ax,STATOK
		
		ret

init		endp

stflag		db	00h
stop_seg	dw	?
stop_off	dw	?

stopmes2	db	'Int trap hlt ',07h
		db	0dh,0ah,'どうじゃ，おどろいたかの？','$'
stopmes1	db	'いぢめる？ いぢめる？','$'
stopmes0	db	'command.comがロードできません……なーんちゃって','$'
stopmes3	db	'おぉっとぉ，『ちょっと待ったコール』だぁ！！','$'

cr		db	0dh,0ah,'$'
msg		db	0dh,0ah
		db	'ボケてしまった'
		db	'デバイスドライバ Ver 0.91 を組み込みましたが…….'
		db	0dh,0ah
		db	'Copyright 1989,90 (C) Muroran Inst. of Tec.'
		db	' Thermal Engineering Lab.'
		db	0dh,0ah
		db	'$'

comver		db	0dh,0ah,'Command ﾊﾞｰｼﾞｮﾝ ','$'
comverend	db	0dh,0ah,'$'

prompt		db	0dh,0ah,'A>','$'

retnomi		db	'黙っとらんで，何か話してみぃ．','$'
onaji		db	'何度も何度も同じ事言って……わしを年寄りと思って'
		db	'バカにしとるんぢゃろ！！！','$'
hatemes1	db	'はてな？ ',0dh,0ah,'$'
hatemes2	db	'クックックックックエッショーン！ ',0dh,0ah
		db	0dh,0ah,'$'
hatemes3	db	'でっきるっかな でっきるっかな はてさてふふーん','$'
hatemes4	db	'さてふふーーん！！',0dh,0ah,'$'
hitomes		db	'キー入力をなまけちゃいかんよ','$'
dirmes		db	'ls の間違いじゃないのか．','$'
logmes		db	'うーん うーん うーん うーん うーん うーん',0dh,0ah
		db	'そんな対数の計算，知らないよぉ．',0dh,0ah
		db	'どうせ私は対数の計算すらできない，ぼけな'
		db	'コンピュータですよ．ふんっ……','$'
lsmes		db	'sl なら知っとるんじゃがのぉ‥‥‥','$'
slmes		db	'ほう『ＳＬ』とは懐かしいのぉ．',0dh,0ah
		db	'子供ん頃ぁ，あれに乗りたくてのぉ………………',0dh,0ah
		db	'汽車に乗りたぁい，汽車に乗りたぁい！……って'
		db	'だだをこねたもんじゃ．  ','$'
slmes1		db	'しゅっしゅっぽっぽ　','$'
exitmes		db	'　ふっふっふ‥‥‥よくぞ見破った！',0dh,0ah
		db	'　このプログラムはデバイスドライバにして'
		db	'　デバイスドライバにあらず．また，普通の'
		db	'プログラムにして普通のプログラムにあらず．'
		db	0dh,0ah,'　しかして，その実体は‥‥‥！！',0dh,0ah
		db	'　プログラムのニューウェーブ！！',0dh,0ah,0dh,0ah
		db	'《コマンドインタプリタもどき》 だっ！！！',0dh,0ah
		db	0dh,0ah,'　さて，コマンドインタプリタを終了するには，'
		db	'一般的には先程貴兄が看破されたような方法を'
		db	'取るわけですが，本プログラム《もどき》に於いては，'
		db	'さきのコマンドはこのメッセージを出力するだけで，'
		db	'終了処理を行うことは無い（はず）です．'
		db	'本来のコマンドインタプリタ（多分command.comだと'
		db	'思いますが）に制御を移すには，他にコマンドを'
		db	'用意してあります．',0dh,0ah
		db	'　がんばって，脱出してみて下さい．',0dh,0ah
		db	'　なお，このプログラムはデバイス名『ＢＯＫＥＫＥ』で'
		db	'登録されているので，このディスクでＭＳ－ＤＯＳを'
		db	'たちあげると『ＢＯＫＥＫＥ』というファイルには'
		db	'まともにアクセスしません（まあ滅多に『ＢＯＫＥＫＥ』'
		db	'なんてファイル名は使わないでしょうが）．',0dh,0ah
		db	'　ま，一応の注意です．',0dh,0ah
		db	'　では GOOD LUCK !!','$'
endmes		db	'and の間違いじゃないのか．','$'
andmes		db	'あんどうとろわ','$'
clsmes		db	'やーだよーーーだぁ．',0dh,0ah
		db	'画面なんか消してやんないモーーン','$'
bokemes1	db	'　私は今まで「遅い」とか，「なんもできん」とか陰口'
		db	'たたかれた事はありました．が，面と向かって「ぼけ」'
		db	'と言われたのは初めてです．','$'
bokemes2	db	'　私は，とても傷つきました．','$'
bokemes3	db	'　先立つ不幸をお許し下さい．','$'
bokemes4	db	'　リセットします．','$'
bokemes5	db	0dh,0ah,'　なーんて，冗談ですよ，冗談．',0dh,0ah
		db	'　驚いた？','$'
kqmes		db	'　これにて，本プログラムの実行を終了いたします．'
		db	0dh,0ah
		db	'なお，引続き command.com が実行されますので，',0dh,0ah
		db	'そちらの方もごゆっくりご覧下さいませ．',0dh,0ah,'$'


sirames0	db	' って，美味いんじゃろうな？','$'

sirames1	db	'いつもすまないねぇ……．',0dh,0ah
		db	'こんな時，あいつがいてくれたら……','$'

sirames11	db	'隣のじいさんが新しいゲートボールのスティックを'
		db	'嫁に買ってもらったそうじゃ‥‥‥',0dh,0ah
		db	'うらやましいのぉ‥‥‥',0dh,0ah
		db	'わしも買ってほしいのぉ‥‥‥','$'

sirames13	db	'乃木大将は偉いお方じゃ！','$'

sirames4	db	' とは豪気な話ぢゃのぉ．','$'

sirames5_1	db	'なにぃ，','$'
sirames5_2	db	' とは何事ぢゃ！'
		db	' その曲った根性 たたき直してやるわ！！','$'

sirames8	db	'はいはい，ご飯は美味しゅういただきました．',0dh,0ah
		db	'もうお腹一杯で食べられません．','$'

sirames7	db	'はいはい，それはよござんしたねぇ．','$'

sirames6	db	'あら，もう片付けるんですか？',0dh,0ah
		db	'まだ私，朝ご飯，いただいてませんよ．',0dh,0ah
		db	'私が食べてないっていったら食べてないんですから．'
		db	0dh,0ah
		db	'年寄りは，テレビとご飯だけが'
		db	'楽しみなのにねぇ‥‥‥',0dh,0ah
		db	'うちの嫁ったら，満足にご飯も食べさせてくれない‥‥‥'
		db	0dh,0ah
		db	'わたしゃ，なんて不幸なんだろ‥‥‥','$'

sirames9	db	'ピ，ピピ，ピンクの象だぁ！！','$'

siramesa1	db	'やれ ','$'
siramesa2	db	' ほれ ','$'
siramesa3	db	' どうした ','$'
siramesa4	db	' ほほいのほい！','$'

siramesb	db	'おしっこぐらいひとりで行けます．','$'

sirames15	db	'あいつのあたまは　あいうえお',0dh,0ah
		db	'かんじんかなめの　かきくけこ',0dh,0ah
		db	'さんざんさわいで　さしすせそ',0dh,0ah
		db	'たいしたたいどで　たちつてと',0dh,0ah
		db	'なーにがなんだか　なにぬねの',0dh,0ah
		db	'はなはだはんぱで　はひふへほ',0dh,0ah
		db	'まんなかまるあき　まみむめも',0dh,0ah
		db	'やーけのやんぱち　やいゆえよ',0dh,0ah
		db	'らくだいらくちん　らりるれろ',0dh,0ah
		db	'わ-け-もわからず　わいうえを',0dh,0ah
		db	'んっ！','$'

siramesc	db	'ここ，ちゅうちゅうねずみ出てこわいんですー',0dh,0ah
		db	'あけてーー','$'

siramesd1	db	'ううむ，やはり ','$'
siramesd2	db	' に相違あるまい．','$'

siramese1	db	'へいっ，がってんでぃ！',0dh,0ah
		db	'いますぐとりかかりやしょう．',0dh,0ah
		db	'ときに，','$'
siramese2	db	' は何処に売ってるんですかぃ？','$'

siramesf	db	'わたしの人形はよい人形．目はぱっちりと色白で，','$'

sirames10	db	'ほほう，そりゃあよかったのぉ (y/n) ','$'

sirames2	db	'#include <stdio.h>',0dh,0ah,0dh,0ah
		db	'main(argc,argv)',0dh,0ah
		db	'int	argc;',0dh,0ah
		db	'char	**argv;',0dh,0ah
		db	'{',0dh,0ah
		db	'	･',0dh,0ah
		db	'	･',0dh,0ah
		db	'	･',0dh,0ah
		db	'	･',0dh,0ah
		db	'	･',0dh,0ah
		db	'	･',0dh,0ah
		db	'　もう歳じゃからのぉ……',0dh,0ah
		db	'　Ｃは忘れてしもーたわぃ……（意味不明）','$'

sirames12	db	' ドライブ C: のディスクのボリュームラベルは'
		db	' JUNK.',0dh,0ah
		db	' ディレクトリは C:\BOKE',0dh,0ah,0dh,0ah
		db	'.            <DIR>     89-05-08  12:46',0dh,0ah
		db	'..           <DIR>     89-05-08  12:46',0dh,0ah
		db	'BOKEINI  OBJ     6609  90-02-07  18:46',0dh,0ah
		db	'BOKEMEN  ASM     1791  89-07-10  20:22',0dh,0ah
		db	'BOKEMEN  EXE     6290  90-02-07  18:46',0dh,0ah
		db	'BOKEMEN  OBJ      430  89-07-10  20:23',0dh,0ah
		db	'BOKEMEN  SYS     5778  90-02-07  18:46',0dh,0ah
		db	'DEV      H        392  89-07-10  21:22',0dh,0ah
		db	'README   DOC     2211  89-07-10  21:24',0dh,0ah
		db	'BOKE     BAT       83  90-02-07  18:42',0dh,0ah
		db	'BOKEINI  LST    66016  90-02-07  18:46',0dh,0ah
		db	'BOKEINI  ASM    19164  90-02-07  18:44',0dh,0ah
		db	'       12 個のファイルがあります.',0dh,0ah
		db	'   818176 バイトが使用可能です.',0dh,0ah,'$'

sirames3	db	'困ってしまってワンワンワワン','$'

sirames14	db	'飲んだビールが５万本！','$'

resetmes	db	'待て！リセットは最後の武器だっ！',0dh,0ah
		db	'我々は忍者部隊だぞ！！','$'

sirames16	db	'おめでとーーーございます！！！',0dh,0ah
		db	'ズバリ賞です！',0dh,0ah
		db	'賞品は，豪華！ナショナル製品一式でーーーーーす！'
		db	0dh,0ah,0dh,0ah,0dh,0ah,0dh,0ah,0dh,0ah
		db	'なーんちゃって，の（笑）','$'

sirames17	db	'ねえアンヌ，僕は人間じゃないんだ．','$'

sirames18	db	'お風呂に入ったら',0dh,0ah
		db	'ちゃーんと，１００まで数えるんじゃぞ','$'

sirames1c	db	'祈りなさい','$'

sirames1a	db	'にちよーのぉーーーーお昼だよーーーーー','$'

sirames1b	db	'気を付けろ，月が細い','$'

sirames19	db	'ざんす，ざぁーーんす',0dh,0ah
		db	'さいざーーーんすっ',0dh,0ah
		db	'わたしあなたにアイブラユー！','$'

sirames1e	db	'くいんとりっくす！',0dh,0ah
		db	'アナタ，エーゴ，ダァーメ ネー','$'

sirames1d	db	'当り前田のクラッカー','$'

sirames1f	db	'　豊臣秀吉がまだ木下藤吉朗と呼ばれていた頃，'
		db	'京の都では金目教という妖しい宗教が流行っていた．'
		db	'それを信じないものは，恐ろしいたたりに見舞われる'
		db	'という．藤吉朗は金目教の謎を解くため，'
		db	'飛騨の山奥より忍者を呼んだ．',0dh,0ah
		db	'　その名は……！','$'

bufmax		db	7fh
bufcnc		db	00h
bufstr		db	7eh dup (?)
		db	'$'

comcnc		db	27h
comstr		db	7eh dup (?)
		db	'$'

code		ends
		end
