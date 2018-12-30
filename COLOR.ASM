; COLOR v1.0 by GDX
; Command to change the colors for MSX-DOS
; 
; Assembled with zasm cross assembler
; http://sourceforge.net/projects/zasm/

;S 16	; Remove the semicolon at the beginning of this line to assemble it with GEN80

CALSLT	equ	0001Ch		; Call Slot
CHGCLR	equ	00062h		; Change colors
FORCLR	equ	0F3E9h		; Draw/Text color
BAKCLR	equ	0F3EAh		; Background color
BDRCLR	equ	0F3EBh		; Border color
SCRMOD	equ	0FCAFh		; Current screen mode
EXPTBL	equ	0FCC1h		; Main-ROM Slot

DMA	equ	00080h		; Parameters address
BDOS	equ	00005h		; MSX-DOS function

	org	0100h

	ld	c,048h		; 'H' character
	call	Param_Srch	; Search the option /h

	jp	z,HELP		; Displays the help if /h is found

	ld	hl,DMA

; Get text color

Space_TC:
	inc	hl
	ld	a,(hl)
	cp	0dh		; Parameters end	
	jp	z,Param_END
	or	a		; Parameters end	
	jp	z,Param_END
	cp	2Ch		; ","	
	jp	z,Space_BGC
	cp	20h
	jr	nz,No_Space_TC
	jr	Space_TC
No_Space_TC:
	cp	2Fh		; "0"-1
	jp	c,Syntax_ERR	; Jump if character < "0"
	cp	40h		; "9"+1
	jp	nc,Syntax_ERR	; Jump if character > "9"
	call	Get_Value
	cp	254
	jp	z,Overflow_ERR
	cp	255
	jp	z,Syntax_ERR
	push	af
	ld	a,c
	ld	(FORCLR),a	; Text color
	pop	af
	or	a
	jp	z,Param_END

; Get background color

Space_BGC:
	inc	hl
	ld	a,(hl)
	cp	0dh		; Parameters end	
	jp	z,Param_END
	or	a		; Parameters end	
	jp	z,Param_END
	cp	2Ch		; ","	
	jp	z,Space_BDC
	cp	20h
	jr	nz,No_Space_BGC
	jr	Space_BGC
No_Space_BGC:
	cp	2Fh		; "0"-1
	jp	c,Syntax_ERR	; Jump if character < "0"
	cp	40h		; "9"+1
	jp	nc,Syntax_ERR	; Jump if character > "9"
	call	Get_Value
	cp	254
	jp	z,Overflow_ERR
	cp	255
	jp	z,Syntax_ERR
	push	af
	ld	a,c
	ld	(BAKCLR),a	; Background color
	pop	af
	or	a
	jp	z,Param_END

; Get foreground color

Space_BDC:
	inc	hl
	ld	a,(hl)
	cp	0dh		; Parameters end	
	jp	z,Param_END
	or	a		; Parameters end	
	jp	z,Param_END
	cp	2Ch		; ","	
	jp	z,Space_BGC
	cp	20h
	jr	nz,No_Space_BDC
	jr	Space_BDC

No_Space_BDC:
	cp	2Fh		; "0"-1
	jp	c,Syntax_ERR	; Jump if character < "0"
	cp	40h		; "9"+1
	jp	nc,Syntax_ERR	; Jump if character > "9"
	call	Get_Value
	cp	254
	jp	z,Overflow_ERR
	cp	255
	jp	z,Syntax_ERR
	push	af
	ld	a,c
	ld	(BDRCLR),a	; Background color
	pop	af
	or	a
	jp	z,Param_END

Param_END:
	ld	a,(SCRMOD)
	ld	ix,CHGCLR	
	call	CALL2BIOS	; Changes colors
	ret			; Back to MSX-DOS

; Entry: The content of the address pointed to by HL must be one or two
;        digit.
; Output: A = code for condition, C = value converted, HL = next character
; Modify: AF, BC, HL

Get_Value:
	sub	30h		; Digit to value
	ld	c,a		; C = color or first digit value

	inc	hl
	ld	a,(hl)
	or	a		; Parameters end
	ret	z		; Back if character = 0
	cp	0Dh	
	ld	a,0
	ret	z		; back if character = 0Dh
	ld	a,(hl)
	cp	2Ch		; ","	
	ret	z		; back if character = 2Ch

	cp	2Fh		; "0"-1
	ld	a,255
	ret	c		; Back if character < "0"
	ld	a,(hl)
	cp	40h		; "9"+1
	ld	a,255
	ret	nc		; Back if character > "9"
	ld	a,(hl)
	cp	36h		; "6"
	ld	a,254
	ret	nc		; Back if character > "5"

	ld	a,(hl)
	sub	30h		; Digit to value
	ld	b,a		; B = second digit value
	ld	a,c
	cp	1	
	jr	z,Ten_TC
	or	a
	jr	z,Zero_TC
	ld	a,254
	ret			; Jump if character < "0"
Ten_TC:
	ld	a,b
	add	10
	ld	c,a		; C = Text color
	jr	Third_digit_TC
Zero_TC:
	ld	c,b		; C = Text color

Third_digit_TC:
	inc	hl
	ld	a,(hl)
	cp	2Fh		; "0"-1
	ret	c		; Back if character < "0"
	ld	a,(hl)
	cp	40h		; "9"+1
	ld	a,254
	ret	c		; Back if character < "9"+1
	ld	a,(hl)
	ret

Syntax_ERR:
	ld	de,Syntax_ERR_TXT
	ld	c,9
	call	BDOS		; Print
	ret			; Back to MSX-DOS

Overflow_ERR:
	ld	de,Overflow_ERR_TXT
	ld	c,9
	call	BDOS		; Print
	ret			; Back to MSX-DOS
; -- Parameter search routine
; Entry: C = Character used as option (A~Z or a~z)
; Output: F = NZ if Parameter not found
; Modify: AF, BC, HL

Param_Srch:
	ld	a,c
	or	020h		; Upper case
	ld	c,a
	ld	hl,DMA
	ld	b,(hl)
	inc	b
ParamBCL:
	inc	hl
	ld	a,(hl)
	cp	02Fh		; Seek '/' character
	jr	nz,SLSH_NTFND	; Jump if '/' is not found
	inc	hl
	ld	a,(hl)
	or	020h		; Upper case
	cp	c		; Compare found character with the input character
	ret	z		; Back if character is found
SLSH_NTFND:
	djnz	ParamBCL
	ret
	
CALL2BIOS:

; Entry: ix=Routine address

	ld	iy,(EXPTBL-1)
	jp	CALSLT

HELP:
	ld	de,HELP_TXT
	ld	c,9
	call	BDOS		; Print
	ret			; Back to DOS	

HELP_TXT:
	db	"COLOR v1.0 by GDX",10,13
	db	"Use:",10,13
	db	"color <0-15>,<0-15>,<0-15>",10,13,24h

Syntax_ERR_TXT:
	db	"Syntax error!!!",10,13,24h

Overflow_ERR_TXT:
	db	"Overflow!!!",10,13,24h

