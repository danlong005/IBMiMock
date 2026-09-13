/* MOCKRMV - RPGMOCK: delete mocks from QTEMP                        */
             CMD        PROMPT('RPGMOCK - Remove mocks')
             PARM       KWD(OBJ) TYPE(*NAME) LEN(10) DFT(*ALL) +
                          SPCVAL((*ALL)) PROMPT('Mock')
