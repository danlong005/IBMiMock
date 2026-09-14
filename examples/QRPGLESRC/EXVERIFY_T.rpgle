**free
// ------------------------------------------------------------------
// EXVERIFY_T - Check how many times a dependency was called
//
// Features: IMOQVERIFY TIMES(*ONCE | *NEVER | *EXACTLY n |
//                            *ATLEAST n | *ATMOST n), with ARGS
// imoq_ok() returns *off when the verification fails.
// Run it with the driver EXVERIFY.
// ------------------------------------------------------------------
ctl-opt main(main);

/copy QRPGLESRC,IMOQ_H

// The dependency this example calls. It is a mock created by the
// driver EXVERIFY; no real object exists.

// EXPRICE (*SRVPGM), procedure EX_LOG: write a log message
dcl-pr logMessage extproc('EX_LOG');
  text char(50) const;
end-pr;

/copy QRPGLESRC,EXAMPLE_H

dcl-proc main;
  imoq('IMOQRESET');

  logMessage('started');
  logMessage('working');
  logMessage('working');

  expect(imoq_ok('IMOQVERIFY OBJ(EXPRICE) PROC(EX_LOG) +
                  TIMES(*EXACTLY 3)') : imoq_lastError());
  expect(imoq_ok('IMOQVERIFY OBJ(EXPRICE) PROC(EX_LOG) +
                  ARGS((1 *EQ ''working'')) TIMES(*EXACTLY 2)')
         : imoq_lastError());
  expect(imoq_ok('IMOQVERIFY OBJ(EXPRICE) PROC(EX_LOG) +
                  ARGS((1 *EQ ''started'')) TIMES(*ONCE)')
         : imoq_lastError());
  expect(imoq_ok('IMOQVERIFY OBJ(EXPRICE) PROC(EX_LOG) +
                  ARGS((1 *EQ ''stopped'')) TIMES(*NEVER)')
         : imoq_lastError());
  expect(imoq_ok('IMOQVERIFY OBJ(EXPRICE) PROC(EX_LOG) +
                  TIMES(*ATLEAST 1)') : imoq_lastError());
  expect(imoq_ok('IMOQVERIFY OBJ(EXPRICE) PROC(EX_LOG) +
                  TIMES(*ATMOST 5)') : imoq_lastError());
  expect(imoq_ok('IMOQVERIFY OBJ(EXPRICE) PROC(EX_PRICE) +
                  TIMES(*NEVER)') : imoq_lastError());
end-proc;
