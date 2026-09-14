**free
// ------------------------------------------------------------------
// EXPGM_T - Mock a program and fill in its output parameters
//
// Features: IMOQPGM, IMOQWHEN SETPARM
// The driver EXPGM creates the mock with:
//   IMOQPGM OBJ(EXCUST) PARMS((*CHAR 5) (*CHAR 30) (*IND))
// ------------------------------------------------------------------
ctl-opt main(main);

/copy QRPGLESRC,IMOQ_H

// The dependency this example calls. It is a mock created by the
// driver EXPGM; no real object exists.

// EXCUST (*PGM): look up a customer name
dcl-pr getCustomer extpgm('EXCUST');
  custId char(5) const;
  name char(30);
  found ind;
end-pr;

/copy QRPGLESRC,EXAMPLE_H

dcl-proc main;
  dcl-s name char(30);
  dcl-s found ind;

  imoq('IMOQRESET');

  // When EXCUST is called, write parameter 2 (name) and 3 (found)
  imoq('IMOQWHEN OBJ(EXCUST) +
        SETPARM((2 ''Ada Lovelace'') (3 ''1''))');

  getCustomer('C0001' : name : found);

  expect(name = 'Ada Lovelace' : 'name is set by SETPARM');
  expect(found : 'found is set by SETPARM');
end-proc;
