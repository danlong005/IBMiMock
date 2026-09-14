**free
// ------------------------------------------------------------------
// EXNOMORE_T - Make sure nothing else was called
//
// Features: IMOQNOMORE
// IMOQNOMORE fails if any recorded call was not covered by a
// successful IMOQVERIFY.
// Run it with the driver EXNOMORE.
// ------------------------------------------------------------------
ctl-opt main(main);

/copy QRPGLESRC,IMOQ_H

// The dependencies this example calls. They are mocks created by
// the driver EXNOMORE; no real objects exist.

// EXPRICE (*SRVPGM), procedure EX_PRICE: price of an item
dcl-pr getPrice packed(7:2) extproc('EX_PRICE');
  item char(5) const;
end-pr;

// EXPRICE (*SRVPGM), procedure EX_LOG: write a log message
dcl-pr logMessage extproc('EX_LOG');
  text char(50) const;
end-pr;

/copy QRPGLESRC,EXAMPLE_H

dcl-proc main;
  imoq('IMOQRESET');

  logMessage('hello');
  getPrice('A0001');

  expect(imoq_ok('IMOQVERIFY OBJ(EXPRICE) PROC(EX_LOG)')
         : imoq_lastError());
  expect(not imoq_ok('IMOQNOMORE')
         : 'the EX_PRICE call is not verified yet');

  expect(imoq_ok('IMOQVERIFY OBJ(EXPRICE) PROC(EX_PRICE)')
         : imoq_lastError());
  expect(imoq_ok('IMOQNOMORE') : 'every call is now verified');
end-proc;
