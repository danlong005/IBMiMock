/* IMOQRESET - iMoq: clear recorded calls and/or stubs              */
             CMD        PROMPT('iMoq - Reset mocks')
             PARM       KWD(OBJ) TYPE(*NAME) LEN(10) DFT(*ALL) +
                          SPCVAL((*ALL)) PROMPT('Mock')
             PARM       KWD(SCOPE) TYPE(*CHAR) LEN(7) RSTD(*YES) +
                          DFT(*ALL) VALUES(*ALL *CALLS *STUBS) +
                          PROMPT('What to clear')
