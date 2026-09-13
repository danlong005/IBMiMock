/* MOCKSRVPGM - RPGMOCK: start a *SRVPGM mock (build with MOCKBUILD) */
             CMD        PROMPT('RPGMOCK - Mock a srvpgm')
             PARM       KWD(OBJ) TYPE(*NAME) LEN(10) MIN(1) +
                          PROMPT('Service program to mock')
             PARM       KWD(BEHAVIOR) TYPE(*CHAR) LEN(7) RSTD(*YES) +
                          DFT(*LOOSE) VALUES(*LOOSE *STRICT) +
                          PROMPT('Calls without a match')
             PARM       KWD(SRCFILE) TYPE(QSRC) DFT(*RTV) +
                          SNGVAL((*RTV)) PROMPT('Binder source file')
             PARM       KWD(SRCMBR) TYPE(*NAME) LEN(10) DFT(*OBJ) +
                          SPCVAL((*OBJ)) PROMPT('Binder source member')
 QSRC:       QUAL       TYPE(*NAME) LEN(10)
             QUAL       TYPE(*NAME) LEN(10) DFT(*LIBL) +
                          SPCVAL((*LIBL) (*CURLIB)) PROMPT('Library')
