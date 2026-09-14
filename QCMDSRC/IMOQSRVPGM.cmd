/* IMOQSRVPGM - iMoq: start a *SRVPGM mock (build with IMOQBUILD) */
             CMD        PROMPT('iMoq - Mock a srvpgm')
             PARM       KWD(OBJ) TYPE(*NAME) LEN(10) MIN(1) +
                          PROMPT('Service program to mock')
             PARM       KWD(BEHAVIOR) TYPE(*CHAR) LEN(7) RSTD(*YES) +
                          DFT(*LOOSE) VALUES(*LOOSE *STRICT) +
                          PROMPT('Calls without a match')
             PARM       KWD(SRCFILE) TYPE(QSRC) DFT(*NONE) +
                          SNGVAL((*NONE) (*RTV)) +
                          PROMPT('Exports: *NONE, *RTV or file')
             PARM       KWD(SRCMBR) TYPE(*NAME) LEN(10) DFT(*OBJ) +
                          SPCVAL((*OBJ)) PROMPT('Binder source member')
             PARM       KWD(SIGNATURE) TYPE(*CHAR) LEN(16) DFT(*GEN) +
                          SPCVAL((*GEN)) CASE(*MIXED) +
                          PROMPT('Signature for SRCFILE(*NONE)')
             PARM       KWD(LIB) TYPE(*NAME) LEN(10) DFT(QTEMP) +
                          PROMPT('Library for the mock')
 QSRC:       QUAL       TYPE(*NAME) LEN(10)
             QUAL       TYPE(*NAME) LEN(10) DFT(*LIBL) +
                          SPCVAL((*LIBL) (*CURLIB)) PROMPT('Library')
