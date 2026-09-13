/* MOCKNOMORE - RPGMOCK: fail if a call was not verified             */
             CMD        PROMPT('RPGMOCK - No more interactions')
             PARM       KWD(OBJ) TYPE(*NAME) LEN(10) DFT(*ALL) +
                          SPCVAL((*ALL)) PROMPT('Mock')
