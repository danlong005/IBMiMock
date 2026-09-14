/* IMOQPROC - iMoq: declare a procedure of a *SRVPGM mock           */
             CMD        PROMPT('iMoq - Declare procedure')
             PARM       KWD(OBJ) TYPE(*NAME) LEN(10) MIN(1) +
                          PROMPT('Service program mock')
             PARM       KWD(PROC) TYPE(*CHAR) LEN(256) MIN(1) +
                          VARY(*YES *INT2) CASE(*MIXED) +
                          PROMPT('Exported procedure')
             PARM       KWD(RTNTYPE) TYPE(RDEF) PROMPT('Return value')
             PARM       KWD(PARMS) TYPE(PDEF) MAX(64) +
                          PROMPT('Parameter layout')
 RDEF:       ELEM       TYPE(*CHAR) LEN(10) RSTD(*YES) DFT(*NONE) +
                          VALUES(*NONE *CHAR *VARCHAR *PACKED *ZONED +
                          *INT *UNS *FLOAT *IND *DATE *TIME +
                          *TIMESTAMP *PTR) PROMPT('Type')
             ELEM       TYPE(*INT4) DFT(0) PROMPT('Length or digits')
             ELEM       TYPE(*INT4) DFT(0) PROMPT('Decimal positions')
 PDEF:       ELEM       TYPE(*CHAR) LEN(10) RSTD(*YES) +
                          VALUES(*CHAR *VARCHAR *PACKED *ZONED *INT +
                          *UNS *FLOAT *IND *DATE *TIME *TIMESTAMP +
                          *PTR) MIN(1) PROMPT('Type')
             ELEM       TYPE(*INT4) DFT(0) PROMPT('Length or digits')
             ELEM       TYPE(*INT4) DFT(0) SPCVAL((*CONST -1) +
                          (*VALUE -2) (*REF -3)) +
                          PROMPT('Decimal positions or passing')
             ELEM       TYPE(*CHAR) LEN(6) RSTD(*YES) DFT(*REF) +
                          VALUES(*REF *CONST *VALUE) PROMPT('Passing')
