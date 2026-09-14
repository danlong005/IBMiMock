/* IMOQCHK - iMoq: diagnose library list and binding problems       */
             CMD        PROMPT('iMoq - Check mocks')
             PARM       KWD(PGM) TYPE(QPGM) DFT(*NONE) +
                          SNGVAL((*NONE)) +
                          PROMPT('Program or service program')
 QPGM:       QUAL       TYPE(*NAME) LEN(10)
             QUAL       TYPE(*NAME) LEN(10) DFT(*LIBL) +
                          SPCVAL((*LIBL)) PROMPT('Library')
