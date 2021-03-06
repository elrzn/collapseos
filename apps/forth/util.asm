; Return address of scratchpad in HL
pad:
	ld	hl, (HERE)
	ld	a, PADDING
	jp	addHL

; Read word from (INPUTPOS) and return, in HL, a null-terminated word.
; Advance (INPUTPOS) to the character following the whitespace ending the
; word.
; When we're at EOL, we call fetchline directly, so this call always returns
; a word.
readword:
	ld	hl, (INPUTPOS)
	; skip leading whitespace
	dec	hl	; offset leading "inc hl"
.loop1:
	inc	hl
	ld	a, (hl)
	or	a
	; When at EOL, fetch a new line directly
	jr	z, .empty
	cp	' '+1
	jr	c, .loop1
	push	hl		; --> lvl 1. that's our result
.loop2:
	inc	hl
	ld	a, (hl)
	; special case: is A null? If yes, we will *not* inc A so that we don't
	; go over the bounds of our input string.
	or	a
	jr	z, .noinc
	cp	' '+1
	jr	nc, .loop2
	; we've just read a whitespace, HL is pointing to it. Let's transform
	; it into a null-termination, inc HL, then set (INPUTPOS).
	xor	a
	ld	(hl), a
	inc	hl
.noinc:
	ld	(INPUTPOS), hl
	pop	hl		; <-- lvl 1. our result
	ret	; Z set from XOR A
.empty:
	call	fetchline
	jr	readword

; Sets Z if (HL) == E and (HL+1) == D
HLPointsDE:
	ld	a, (hl)
	cp	e
	ret	nz		; no
	inc	hl
	ld	a, (hl)
	dec	hl
	cp	d		; Z has our answer
	ret


HLPointsNUMBER:
	push	de
	ld	de, NUMBER
	call	HLPointsDE
	pop	de
	ret

HLPointsLIT:
	push	de
	ld	de, LIT
	call	HLPointsDE
	pop	de
	ret

HLPointsBR:
	push	de
	ld	de, FBR
	call	HLPointsDE
	jr	z, .end
	ld	de, BBR
	call	HLPointsDE
.end:
	pop	de
	ret

; Skip the compword where HL is currently pointing. If it's a regular word,
; it's easy: we inc by 2. If it's a NUMBER, we inc by 4. If it's a LIT, we skip
; to after null-termination.
compSkip:
	call	HLPointsNUMBER
	jr	z, .isNum
	call	HLPointsBR
	jr	z, .isBranch
	call	HLPointsLIT
	jr	nz, .isWord
	; We have a literal
	inc	hl \ inc hl
	call	strskip
	inc	hl		; byte after word termination
	ret
.isNum:
	; skip by 4
	inc	hl
	; continue to isBranch
.isBranch:
	; skip by 3
	inc	hl
	; continue to isWord
.isWord:
	; skip by 2
	inc	hl \ inc hl
	ret

; Find the entry corresponding to word where (HL) points to and sets DE to
; point to that entry.
; Z if found, NZ if not.
find:
	push	hl
	push	bc
	ld	de, (CURRENT)
	ld	bc, CODELINK_OFFSET
.inner:
	; DE is a wordref, let's go to beginning of struct
	push	de		; --> lvl 1
	or	a		; clear carry
	ex	de, hl
	sbc	hl, bc
	ex	de, hl		; We're good, DE points to word name
	ld	a, NAMELEN
	call	strncmp
	pop	de		; <-- lvl 1, return to wordref
	jr	z, .end		; found
	call	.prev
	jr	nz, .inner
	; Z set? end of dict unset Z
	inc	a
.end:
	pop	bc
	pop	hl
	ret

; For DE being a wordref, move DE to the previous wordref.
; Z is set if DE point to 0 (no entry). NZ if not.
.prev:
	dec	de \ dec de \ dec de	; prev field
	call	intoDE
	; DE points to prev. Is it zero?
	xor	a
	or	d
	or	e
	; Z will be set if DE is zero
	ret

; Write compiled data from HL into IY, advancing IY at the same time.
wrCompHL:
	ld	(iy), l
	inc	iy
	ld	(iy), h
	inc	iy
	ret

; Spit name + prev in (HERE) and adjust (HERE) and (CURRENT)
; HL points to new (HERE)
entryhead:
	call	readword
	ld	de, (HERE)
	call	strcpy
	ex	de, hl		; (HERE) now in HL
	ld	de, (CURRENT)
	ld	a, NAMELEN
	call	addHL
	call	DEinHL
	; Set word flags: not IMMED, not UNWORD, so it's 0
	xor	a
	ld	(hl), a
	inc	hl
	ld	(CURRENT), hl
	ld	(HERE), hl
	ret

; Sets Z if wordref at HL is of the IMMEDIATE type
HLisIMMED:
	dec	hl
	bit	FLAG_IMMED, (hl)
	inc	hl
	; We need an invert flag. We want to Z to be set when flag is non-zero.
	jp	toggleZ

; Sets Z if wordref at (HL) is of the IMMEDIATE type
HLPointsIMMED:
	push	hl
	call	intoHL
	call	HLisIMMED
	pop	hl
	ret

; Sets Z if wordref at HL is of the UNWORD type
HLisUNWORD:
	dec	hl
	bit	FLAG_UNWORD, (hl)
	inc	hl
	; We need an invert flag. We want to Z to be set when flag is non-zero.
	jp	toggleZ

; Sets Z if wordref at (HL) is of the IMMEDIATE type
HLPointsUNWORD:
	push	hl
	call	intoHL
	call	HLisUNWORD
	pop	hl
	ret

; Checks flags Z and C and sets BC to 0 if Z, 1 if C and -1 otherwise
flagsToBC:
	ld	bc, 0
	ret	z	; equal
	inc	bc
	ret	c	; >
	; <
	dec	bc
	dec	bc
	ret

; Write DE in (HL), advancing HL by 2.
DEinHL:
	ld	(hl), e
	inc	hl
	ld	(hl), d
	inc	hl
	ret

fetchline:
	call	printcrlf
	call	stdioReadLine
	ld	(INPUTPOS), hl
	ret
