;dev.h

;
FALSE	=	0		;いいですよ
TRUE	=	not FALSE	;よくない

STATOK	=	0000000100000000b
BITDONE	=	00000001b
BITBUSY	=	00000010b
BITERR	=	10000000b
ERRCN	=	3

CTRLC	=	03h
MAXCMD	=	16		;ｺﾏﾝﾄﾞ･ｺｰﾄﾞのmax

reqheader	struc		;ﾘｸｴｽﾄﾊﾟｹｯﾄ
	_length		db	?
	_unit		db	?
	_cmd		db	?
	_status		dw	?
	_reseve		db	8 dup (?)
	_media		db	?
	_addr		dd	?
	_count		dw	?
reqheader	ends

