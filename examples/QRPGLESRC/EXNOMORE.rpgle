**free
// ------------------------------------------------------------------
// EXNOMORE - Make sure nothing else was called
//
// Features: MOCKNOMORE
// MOCKNOMORE fails if any recorded call was not covered by a
// successful MOCKVERIFY.
// ------------------------------------------------------------------
ctl-opt main(main);

/copy QTEMP/MOCKINC,MOCK_H
/copy QTEMP/MOCKINC,EXAMPLE_H

dcl-proc main;
  mock('MOCKRESET');

  logMessage('hello');
  getPrice('A0001');

  expect(mock_ok('MOCKVERIFY OBJ(EXPRICE) PROC(EX_LOG)')
         : mock_lastError());
  expect(not mock_ok('MOCKNOMORE')
         : 'the EX_PRICE call is not verified yet');

  expect(mock_ok('MOCKVERIFY OBJ(EXPRICE) PROC(EX_PRICE)')
         : mock_lastError());
  expect(mock_ok('MOCKNOMORE') : 'every call is now verified');
end-proc;
