/* IMOQRMV - iMoq: delete mocks from QTEMP                          */
             CMD        PROMPT('iMoq - Remove mocks')
             PARM       KWD(OBJ) TYPE(*NAME) LEN(10) DFT(*ALL) +
                          SPCVAL((*ALL)) PROMPT('Mock')
