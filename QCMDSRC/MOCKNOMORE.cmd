/* MOCKNOMORE - IBMIMOCK: fail if a call was not verified            */
             CMD        PROMPT('IBMIMOCK - No more calls')
             PARM       KWD(OBJ) TYPE(*NAME) LEN(10) DFT(*ALL) +
                          SPCVAL((*ALL)) PROMPT('Mock')
