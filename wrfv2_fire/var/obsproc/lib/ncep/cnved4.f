	SUBROUTINE CNVED4(MSGIN,LMSGOT,MSGOT)

C$$$  SUBPROGRAM DOCUMENTATION BLOCK
C
C SUBPROGRAM:    CNVED4
C   PRGMMR: ATOR             ORG: NP12       DATE: 2005-11-29
C
C ABSTRACT: THIS SUBROUTINE READS AN INPUT BUFR MESSAGE ENCODED USING
C   BUFR EDITION 3 AND OUTPUTS AN EQUIVALENT BUFR MESSAGE ENCODED USING
C   BUFR EDITION 4.  THE OUTPUT MESSAGE WILL BE SLIGHTLY LONGER THAN THE
C   INPUT MESSAGE, SO THE USER MUST ALLOW FOR ENOUGH SPACE WITHIN THE
C   MSGOT ARRAY.  NOTE THAT MSGIN AND MSGOT MUST BE SEPARATE ARRAYS.
C
C PROGRAM HISTORY LOG:
C 2005-11-29  J. ATOR    -- ORIGINAL AUTHOR
C
C USAGE:    CALL STNDRD (MSGIN, LMSGOT, MSGOT)
C   INPUT ARGUMENT LIST:
C     MSGIN    - INTEGER: *-WORD ARRAY CONTAINING BUFR MESSAGE ENCODED
C                USING BUFR EDITION 3
C     LMSGOT   - INTEGER: DIMENSIONED SIZE (IN INTEGER WORDS) OF MSGOT;
C                USED BY THE SUBROUTINE TO ENSURE THAT IT DOES NOT
C                OVERFLOW THE MSGOT ARRAY
C
C   OUTPUT ARGUMENT LIST:
C     MSGOT    - INTEGER: *-WORD ARRAY CONTAINING INPUT BUFR MESSAGE
C                NOW ENCODED USING BUFR EDITION 4
C
C REMARKS:
C    MSGIN AND MSGOT MUST BE SEPARATE ARRAYS.
C
C    THIS ROUTINE CALLS:        BORT     GETLENS  IUPBS01  MVB
C                               PKB
C    THIS ROUTINE IS CALLED BY: MSGWRT
C                               Also called by application programs.
C
C ATTRIBUTES:
C   LANGUAGE: FORTRAN 77
C   MACHINE:  PORTABLE TO ALL PLATFORMS
C
C$$$

	DIMENSION MSGIN(*), MSGOT(*)

	COMMON /HRDWRD/ NBYTW,NBITW,NREV,IORD(8)

C-----------------------------------------------------------------------
C-----------------------------------------------------------------------

C	Verify that the input message is not already encoded in
C	BUFR edition 4.

	IF(IUPBS01(MSGIN,'BEN').EQ.4) GOTO 900

C	Get some section lengths and addresses from the input message.

	CALL GETLENS(MSGIN,3,LEN0,LEN1,LEN2,LEN3,L4,L5)

	IAD2 = LEN0 + LEN1
	IAD4 = IAD2 + LEN2 + LEN3 

	LENM = IUPBS01(MSGIN,'LENM')

C	Check for overflow of the output array.  Note that the new
C	edition 4 message will be a total of 3 bytes longer than the
C	input message (i.e. 4 more bytes in Section 1, but 1 fewer
C	byte in Section 3).

	LENMOT = LENM + 3
	IF(LENMOT.GT.((LMSGOT*NBYTW)-8)) GOTO 901 

	LEN1OT = LEN1 + 4
	LEN3OT = LEN3 - 1

C	Write Section 0 of the new message into the output array.

	CALL MVB ( MSGIN, 1, MSGOT, 1, 4 )
	IBIT = 32
	CALL PKB ( LENMOT, 24, MSGOT, IBIT )
	CALL PKB ( 4, 8, MSGOT, IBIT )

C	Write Section 1 of the new message into the output array.

	CALL PKB ( LEN1OT, 24, MSGOT, IBIT )
	CALL PKB ( IUPBS01(MSGIN,'BMT'), 8, MSGOT, IBIT )
	CALL PKB ( IUPBS01(MSGIN,'OGCE'), 16, MSGOT, IBIT )
	CALL PKB ( IUPBS01(MSGIN,'GSES'), 16, MSGOT, IBIT )
	CALL PKB ( IUPBS01(MSGIN,'USN'), 8, MSGOT, IBIT )
	CALL PKB ( IUPBS01(MSGIN,'ISC2')*128, 8, MSGOT, IBIT )
	CALL PKB ( IUPBS01(MSGIN,'MTYP'), 8, MSGOT, IBIT )

C	Set a default of 255 for the international subcategory.

	CALL PKB ( 255, 8, MSGOT, IBIT )
	CALL PKB ( IUPBS01(MSGIN,'MSBT'), 8, MSGOT, IBIT )
	CALL PKB ( IUPBS01(MSGIN,'MTV'), 8, MSGOT, IBIT )
	CALL PKB ( IUPBS01(MSGIN,'MTVL'), 8, MSGOT, IBIT )
	CALL PKB ( IUPBS01(MSGIN,'YEAR'), 16, MSGOT, IBIT )
	CALL PKB ( IUPBS01(MSGIN,'MNTH'), 8, MSGOT, IBIT )
	CALL PKB ( IUPBS01(MSGIN,'DAYS'), 8, MSGOT, IBIT )
	CALL PKB ( IUPBS01(MSGIN,'HOUR'), 8, MSGOT, IBIT )
	CALL PKB ( IUPBS01(MSGIN,'MINU'), 8, MSGOT, IBIT )

C	Set a default of 0 for the second.

	CALL PKB ( 0, 8, MSGOT, IBIT )

C	Copy Section 2 (if it exists) through the next-to-last byte
C	of Section 3 from the input array to the output array.

	CALL MVB ( MSGIN, IAD2+1, MSGOT, (IBIT/8)+1, LEN2+LEN3-1 )

C	Store the length of the new Section 3.

	IBIT = ( LEN0 + LEN1OT + LEN2 ) * 8
	CALL PKB ( LEN3OT, 24, MSGOT, IBIT )
	
C	Copy Section 4 and Section 5 from the input array to the
C	output array.

	IBIT = IBIT + ( LEN3OT * 8 ) - 24
	CALL MVB ( MSGIN, IAD4+1, MSGOT, (IBIT/8)+1, LENM-IAD4 )

	RETURN
900	CALL BORT('BUFRLIB: CNVED4 - INPUT MSG IS ALREADY EDITION 4')
901	CALL BORT('BUFRLIB: CNVED4 - OVERFLOW OF OUTPUT (EDITION 4) '//
     .    'MESSAGE ARRAY; TRY A LARGER DIMENSION FOR THIS ARRAY')
	END
