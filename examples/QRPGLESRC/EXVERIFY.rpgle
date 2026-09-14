**free
// ------------------------------------------------------------------
// EXVERIFY - Check how many times a dependency was called
//
// Features: MOCKVERIFY TIMES(*ONCE | *NEVER | *EXACTLY n |
//                            *ATLEAST n | *ATMOST n), with ARGS
// mock_ok() returns *off when the verification fails.
// ------------------------------------------------------------------
ctl-opt main(main);

/copy QTEMP/MOCKINC,MOCK_H
/copy QTEMP/MOCKINC,EXAMPLE_H

dcl-proc main;
  mock('MOCKRESET');

  logMessage('started');
  logMessage('working');
  logMessage('working');

  expect(mock_ok('MOCKVERIFY OBJ(EXPRICE) PROC(EX_LOG) +
                  TIMES(*EXACTLY 3)') : mock_lastError());
  expect(mock_ok('MOCKVERIFY OBJ(EXPRICE) PROC(EX_LOG) +
                  ARGS((1 *EQ ''working'')) TIMES(*EXACTLY 2)')
         : mock_lastError());
  expect(mock_ok('MOCKVERIFY OBJ(EXPRICE) PROC(EX_LOG) +
                  ARGS((1 *EQ ''started'')) TIMES(*ONCE)')
         : mock_lastError());
  expect(mock_ok('MOCKVERIFY OBJ(EXPRICE) PROC(EX_LOG) +
                  ARGS((1 *EQ ''stopped'')) TIMES(*NEVER)')
         : mock_lastError());
  expect(mock_ok('MOCKVERIFY OBJ(EXPRICE) PROC(EX_LOG) +
                  TIMES(*ATLEAST 1)') : mock_lastError());
  expect(mock_ok('MOCKVERIFY OBJ(EXPRICE) PROC(EX_LOG) +
                  TIMES(*ATMOST 5)') : mock_lastError());
  expect(mock_ok('MOCKVERIFY OBJ(EXPRICE) PROC(EX_PRICE) +
                  TIMES(*NEVER)') : mock_lastError());
end-proc;
