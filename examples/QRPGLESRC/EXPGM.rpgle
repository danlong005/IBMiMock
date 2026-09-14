**free
// ------------------------------------------------------------------
// EXPGM - Mock a program and fill in its output parameters
//
// Features: MOCKPGM, MOCKWHEN SETPARM
// The EXAMPLES driver created the mock with:
//   MOCKPGM OBJ(EXCUST) PARMS((*CHAR 5) (*CHAR 30) (*IND))
// ------------------------------------------------------------------
ctl-opt main(main);

/copy QTEMP/MOCKINC,MOCK_H
/copy QTEMP/MOCKINC,EXAMPLE_H

dcl-proc main;
  dcl-s name char(30);
  dcl-s found ind;

  mock('MOCKRESET');

  // When EXCUST is called, write parameter 2 (name) and 3 (found)
  mock('MOCKWHEN OBJ(EXCUST) +
        SETPARM((2 ''Ada Lovelace'') (3 ''1''))');

  getCustomer('C0001' : name : found);

  expect(name = 'Ada Lovelace' : 'name is set by SETPARM');
  expect(found : 'found is set by SETPARM');
end-proc;
