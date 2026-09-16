/* IMOQPGM - iMoq: create a *PGM mock in QTEMP                      */
             CMD        PROMPT('iMoq - Mock a program')
             PARM       KWD(OBJ) TYPE(QOBJ) MIN(1) +
                          PROMPT('Program to mock')
             PARM       KWD(PARMS) TYPE(PDEF) MAX(64) +
                          PROMPT('Parameter layout')
             PARM       KWD(BEHAVIOR) TYPE(*CHAR) LEN(7) RSTD(*YES) +
                          DFT(*LOOSE) VALUES(*LOOSE *STRICT) +
                          PROMPT('Calls without a match')
 QOBJ:       QUAL       TYPE(*NAME) LEN(10) MIN(1)
             QUAL       TYPE(*NAME) LEN(10) DFT(QTEMP) +
                          PROMPT('Library for the mock')
 PDEF:       ELEM       TYPE(*CHAR) LEN(10) RSTD(*YES) +
                          VALUES(*CHAR *VARCHAR *PACKED *ZONED *INT +
                          *UNS *FLOAT *IND *DATE *TIME *TIMESTAMP +
                          *PTR) MIN(1) PROMPT('Type')
             ELEM       TYPE(*INT4) DFT(0) PROMPT('Length or digits')
             ELEM       TYPE(*INT4) DFT(0) PROMPT('Decimal positions')
