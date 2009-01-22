      SUBROUTINE UFBDMP(LUNIN,LUPRT)

C$$$  SUBPROGRAM DOCUMENTATION BLOCK
C
C SUBPROGRAM:    UFBDMP
C   PRGMMR: WOOLLEN          ORG: NP20       DATE: 1994-01-06
C
C ABSTRACT: THIS SUBROUTINE DUMPS A VERBOSE PRINT LISTING OF THE
C   CONTENTS OF THE UNPACKED DATA SUBSET CURRENTLY RESIDING IN THE
C   INTERNAL SUBSET ARRAYS ASSOCIATED WITH A BUFR FILE IN LOGICAL UNIT
C   ABS(LUNIN) OPENED FOR INPUT VIA A PREVIOUS CALL TO BUFR ARCHIVE
C   LIBRARY SUBROUTINE OPENBF.  THE DATA SUBSET MUST HAVE SUBSEQUENTLY
C   BEEN READ INTO THE INTERNAL BUFR ARCHIVE LIBRARY ARRAYS VIA CALLS
C   TO BUFR ARCHIVE LIBRARY SUBROUTINE READMG OR READERME FOLLOWED BY A
C   CALL TO BUFR ARCHIVE LIBRARY SUBROUTINE READSB (OR VIA A
C   SINGLE CALL TO BUFR ARCHIVE LIBRARY SUBROUTINE READNS).  FOR A
C   PARTICULAR SUBSET, THIS LISTING CONTAINS EACH MNEMONIC ACCOMPANIED
C   BY ITS CORRESPONDING DATA VALUE AND OTHER POTENTIALLY USEFUL
C   INFORMATION SUCH AS WHICH OTHER MNEMONIC(S) THAT MNEMONIC WAS A
C   CONSTITUENT OF WITHIN THE OVERALL DATA SUBSET.  HOWEVER, IT ALSO
C   CONTAINS OTHER, MORE ESOTERIC INFORMATION SUCH AS BUFR STORAGE
C   CHARACTERISTICS AND A COPY OF THE JUMP/LINK TABLE USED INTERNALLY
C   WITHIN THE BUFR ARCHIVE LIBRARY SOFTWARE.  THIS SUBROUTINE IS
C   SIMILAR TO BUFR ARCHIVE LIBRARY SUBROUTINE UFDUMP EXCEPT THAT
C   UFDUMP DOES NOT PRINT POINTERS, COUNTERS AND THE OTHER, MORE
C   ESOTERIC INFORMATION DESCRIBING THE INTERNAL SUBSET STRUCTURES.
C   EACH SUBROUTINE, UFBDMP AND UFDUMP, IS USEFUL FOR DIFFERENT
C   DIAGNOSTIC PURPOSES, BUT IN GENERAL UFDUMP IS MORE USEFUL FOR
C   JUST LOOKING AT THE DATA ELEMENTS.
C
C PROGRAM HISTORY LOG:
C 1994-01-06  J. WOOLLEN -- ORIGINAL AUTHOR
C 1998-07-08  J. WOOLLEN -- REPLACED CALL TO CRAY LIBRARY ROUTINE
C                           "ABORT" WITH CALL TO NEW INTERNAL BUFRLIB
C                           ROUTINE "BORT"
C 1999-11-18  J. WOOLLEN -- THE NUMBER OF BUFR FILES WHICH CAN BE
C                           OPENED AT ONE TIME INCREASED FROM 10 TO 32
C                           (NECESSARY IN ORDER TO PROCESS MULTIPLE
C                           BUFR FILES UNDER THE MPI)
C 2002-05-14  J. WOOLLEN -- REMOVED OLD CRAY COMPILER DIRECTIVES
C 2003-11-04  S. BENDER  -- ADDED REMARKS/BUFRLIB ROUTINE
C                           INTERDEPENDENCIES
C 2003-11-04  D. KEYSER  -- MAXJL (MAXIMUM NUMBER OF JUMP/LINK ENTRIES)
C                           INCREASED FROM 15000 TO 16000 (WAS IN
C                           VERIFICATION VERSION); UNIFIED/PORTABLE FOR
C                           WRF; ADDED DOCUMENTATION (INCLUDING
C                           HISTORY); OUTPUTS MORE COMPLETE DIAGNOSTIC
C                           INFO WHEN ROUTINE TERMINATES ABNORMALLY OR
C                           FOR INFORMATIONAL PURPOSES; TEST FOR A
C                           MISSING VALUE NOW ALLOWS SOME FUZZINESS
C                           ABOUT 10E10 (RATHER THAN TRUE EQUALITY AS
C                           BEFORE) BECAUSE SOME MISSING VALUES (E.G.,
C                           CHARACTER STRINGS < 8 CHARACTERS) WERE NOT
C                           GETTING STAMPED OUT AS "MISSING"; ADDED
C                           OPTION TO PRINT VALUES USING FORMAT EDIT
C                           DESCRIPTOR "F15.6" IF LUNIN IS < ZERO,
C                           IF LUNIN IS > ZERO EDIT DESCRIPTOR EXPANDED
C                           FROM "G10.3" TO "G15.6" {REGARDLESS OF
C                           LUNIN, ADDITIONAL VALUES
C                           "IB,IS,IR,ND,JP,LK,JB" NOW PRINTED (THEY
C                           WERE COMMENTED OUT)}
C 2004-08-18  J. ATOR    -- MODIFIED FUZZINESS TEST;ADDED READLC OPTION;
C                           RESTRUCTURED SOME LOGIC FOR CLARITY
C
C USAGE:    CALL UFBDMP (LUNIN, LUPRT)
C   INPUT ARGUMENT LIST:
C     LUNIN    - INTEGER: ABSOLUTE VALUE IS FORTRAN LOGICAL UNIT NUMBER
C                FOR BUFR FILE
C                  - IF LUNIN IS GREATER THAN ZERO, DATA VALUES ARE
C                    PRINTED OUT USING FORMAT DATA EDIT DESCRIPTOR
C                    "G15.6" (all values are printed since output
C                    format adapts to the magnitude of the data, but
C                    they are not lined up in columns according to
C                    decimal point)
C                  - IF LUNIN IS LESS THAN ZERO, DATA VALUES ARE
C                    PRINTED OUT USING FORMAT DATA EDIT DESCRIPTOR
C                    "F15.6" {values are lined up in columns according
C                    to decimal point, but data of large magnitude,
C                    (i.e., exceeding the format width of 15) get the
C                    overflow ("***************") print}
C     LUPRT    - INTEGER: FORTRAN LOGICAL UNIT NUMBER FOR PRINT OUTPUT
C                FILE
C                       0 = LUPRT is set to 06 (standard output) and
C                           the subroutine will scroll the output,
C                           twenty elements at a time (see REMARKS)
C
C   INPUT FILES:
C     UNIT 05  - STANDARD INPUT (SEE REMARKS)
C
C   OUTPUT FILES:
C     IF LUPRT > 0: UNIT "LUPRT" - PRINT (IF LUPRT=6, STANDARD OUTPUT)
C     IF LUPRT = 0: UNIT 06      - STANDARD OUTPUT PRINT (SEE REMARKS)
C                    
C
C REMARKS:
C    THIS ROUTINE WILL SCROLL THROUGH THE DATA SUBSET, TWENTY ELEMENTS
C    AT A TIME WHEN LUPRT IS INPUT AS "0".  IN THIS CASE, THE EXECUTING
C    SHELL SCRIPT SHOULD USE THE TERMINAL AS BOTH STANDARD INPUT AND
C    STANDARD OUTPUT.  INITIALLY, THE FIRST TWENTY ELEMENTS OF THE
C    CURRENT UNPACKED SUBSET WILL BE DISPLAYED ON THE TERMIMAL,
C    FOLLOWED BY THE PROMPT "(<enter> for MORE, q <enter> to QUIT)".
C    IF THE TERMINAL ENTERS ANYTHING OTHER THAN "q" FOLLOWED BY
C    "<enter>" (e.g., "<enter>"), THE NEXT TWENTY ELEMENTS WILL BE
C    DISPLAYED, AGAIN FOLLOWED BY THE SAME PROMPT.  THIS CONTINUES
C    UNTIL EITHER THE ENTIRE SUBSET HAS BEEN DISPLAYED, OR THE TERMINAL
C    ENTERS "q" FOLLOWED BY "<enter>" AFTER THE PROMPT, IN WHICH CASE
C    THIS SUBROUTINE STOPS THE SCROLL AND RETURNS TO THE CALLING
C    PROGRAM (PRESUMABLY TO READ IN THE NEXT SUBSET IN THE BUFR FILE).
C
C    THIS ROUTINE CALLS:        BORT     RJUST    STATUS
C    THIS ROUTINE IS CALLED BY: None
C                               Normally called only by application
C                               programs.
C
C ATTRIBUTES:
C   LANGUAGE: FORTRAN 77
C   MACHINE:  PORTABLE TO ALL PLATFORMS
C
C$$$

      INCLUDE 'bufrlib.prm'

      COMMON /MSGCWD/ NMSG(NFILES),NSUB(NFILES),MSUB(NFILES),
     .                INODE(NFILES),IDATE(NFILES)
      COMMON /TABLES/ MAXTAB,NTAB,TAG(MAXJL),TYP(MAXJL),KNT(MAXJL),
     .                JUMP(MAXJL),LINK(MAXJL),JMPB(MAXJL),
     .                IBT(MAXJL),IRF(MAXJL),ISC(MAXJL),
     .                ITP(MAXJL),VALI(MAXJL),KNTI(MAXJL),
     .                ISEQ(MAXJL,2),JSEQ(MAXJL)
      COMMON /USRINT/ NVAL(NFILES),INV(MAXJL,NFILES),VAL(MAXJL,NFILES)

      CHARACTER*20 LCHR
      CHARACTER*10 TAG,TG
      CHARACTER*8  VC
      CHARACTER*3  TYP,TP
      CHARACTER*1  YOU
      EQUIVALENCE  (VL,VC)
      REAL*8       VAL,VL,BMISS,BDIFD

      DATA BMISS /10E10/
      DATA BDIFD /5000./
      DATA YOU /'Y'/

C----------------------------------------------------------------------
      IF(LUPRT.EQ.0) THEN
         LUOUT = 6
      ELSE
         LUOUT = LUPRT
      ENDIF

C  CHECK THE FILE STATUS AND I-NODE
C  --------------------------------

      LUNIT = ABS(LUNIN)
      CALL STATUS(LUNIT,LUN,IL,IM)
      IF(IL.EQ.0) GOTO 900
      IF(IL.GT.0) GOTO 901
      IF(IM.EQ.0) GOTO 902
      IF(INODE(LUN).NE.INV(1,LUN)) GOTO 903

C  DUMP THE CONTENTS OF COMMON /USRINT/ FOR UNIT ABS(LUNIN)
C  --------------------------------------------------------

      DO NV=1,NVAL(LUN)
      IF(LUPRT.EQ.0 .AND. MOD(NV,20).EQ.0) THEN

C  When LUPRT=0, the output will be scrolled, 20 elements at a time
C  ----------------------------------------------------------------

         PRINT*,'(<enter> for MORE, q <enter> to QUIT)'
         READ(5,'(A1)') YOU

C  If the terminal enters "q" followed by "<enter>" after the prompt
C  "(<enter> for MORE, q <enter> to QUIT)", scrolling will end and the
C  subroutine will return to the calling program
C  -------------------------------------------------------------------

         IF(YOU.EQ.'q') THEN
         PRINT*
         PRINT*,'==> You have chosen to stop the dumping of this subset'
         PRINT*
            GOTO 100
         ENDIF
      ENDIF
      ND = INV (NV,LUN)
      VL = VAL (NV,LUN)
      TG = TAG (ND)
      TP = TYP (ND)
      IT = ITP (ND)
      IB = IBT (ND)
      IS = ISC (ND)
      IR = IRF (ND)
      JP = JUMP(ND)
      LK = LINK(ND)
      JB = JMPB(ND)
      RJ = RJUST(TG)
      IF(TP.NE.'CHR') THEN
         IF(ABS(VL-BMISS).LT.BDIFD) THEN
            LCHR = 'MISSING'
            RJ = RJUST(LCHR)
            WRITE(LUOUT,2) NV,TP,IT,TG,LCHR,IB,IS,IR,ND,JP,LK,JB
         ELSE
            IF(LUNIT.EQ.LUNIN) THEN
               WRITE(LUOUT,1) NV,TP,IT,TG,VL,IB,IS,IR,ND,JP,LK,JB
            ELSE
               WRITE(LUOUT,10) NV,TP,IT,TG,VL,IB,IS,IR,ND,JP,LK,JB
            ENDIF
         ENDIF
      ELSE
         IF(IB.GT.64) THEN
            CALL READLC(LUNIT,LCHR,TG)
         ELSE
            LCHR = VC
         ENDIF
         IF(ABS(VL-BMISS).LT.BDIFD) LCHR = 'MISSING'
         RJ = RJUST(LCHR)
         WRITE(LUOUT,2) NV,TP,IT,TG,LCHR,IB,IS,IR,ND,JP,LK,JB
      ENDIF
      ENDDO

      WRITE(LUOUT,3)

1     FORMAT(I5,1X,A3,'-',I1,1X,A10,5X,G15.6,7(1X,I5))
10    FORMAT(I5,1X,A3,'-',I1,1X,A10,5X,F15.6,7(1X,I5))
2     FORMAT(I5,1X,A3,'-',I1,1X,A10,   A20,  7(1X,I5))
3     FORMAT(/' >>> END OF SUBSET <<< '/)

C  EXITS
C  -----

100   RETURN
900   CALL BORT('BUFRLIB: UFBDMP - INPUT BUFR FILE IS CLOSED, IT '//
     . 'MUST BE OPEN FOR INPUT')
901   CALL BORT('BUFRLIB: UFBDMP - INPUT BUFR FILE IS OPEN FOR '//
     . 'OUTPUT, IT MUST BE OPEN FOR INPUT')
902   CALL BORT('BUFRLIB: UFBDMP - A MESSAGE MUST BE OPEN IN INPUT '//
     . 'BUFR FILE, NONE ARE')
903   CALL BORT('BUFRLIB: UFBDMP - LOCATION OF INTERNAL TABLE FOR '//
     . 'INPUT BUFR FILE DOES NOT AGREE WITH EXPECTED LOCATION IN '//
     . 'INTERNAL SUBSET ARRAY')
      END
