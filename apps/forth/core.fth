: H HERE @ ;
: -^ SWAP - ;
: +! SWAP OVER @ + SWAP ! ;
: ALLOT HERE +! ;
: , H ! 2 ALLOT ;
: C, H C! 1 ALLOT ;
: BEGIN H ; IMMEDIATE
: AGAIN ['] (bbr) , H -^ C, ; IMMEDIATE
: NOT 1 SWAP SKIP? EXIT 0 * ;
: ( BEGIN LITS ) WORD SCMP NOT SKIP? AGAIN ; IMMEDIATE
( Hello, hello, krkrkrkr... do you hear me?
  Ah, voice at last! Some lines above need comments
  BTW: Forth lines limited to 64 cols because of default
  input buffer size in Collapse OS
  NOT: a bit convulted because we don't have IF yet
  IF true, skip following (fbr). Also, push br cell ref H,
  to PS )
: IF ['] SKIP? , ['] (fbr) , H 1 ALLOT ; IMMEDIATE
( Subtract TOS from H to get offset to write to IF or ELSE's
  br cell )
: THEN DUP H -^ SWAP C! ; IMMEDIATE
( write (fbr) addr, allot, then same as THEN )
: ELSE ['] (fbr) , 1 ALLOT DUP H -^ SWAP C! H 1 - ; IMMEDIATE
: ? @ . ;
: VARIABLE CREATE 2 ALLOT ;
: CONSTANT CREATE H ! DOES> @ ;
: = CMP NOT ;
: < CMP 0 1 - = ;
: > CMP 1 = ;
