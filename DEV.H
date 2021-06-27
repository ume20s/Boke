;dev.h

;
FALSE	=	0		;‚¢‚¢‚Å‚·‚æ
TRUE	=	not FALSE	;‚æ‚­‚È‚¢

STATOK	=	0000000100000000b
BITDONE	=	00000001b
BITBUSY	=	00000010b
BITERR	=	10000000b
ERRCN	=	3

CTRLC	=	03h
MAXCMD	=	16		;ºÏÝÄÞ¥º°ÄÞ‚Ìmax

reqheader	struc		;Ø¸´½ÄÊß¹¯Ä
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