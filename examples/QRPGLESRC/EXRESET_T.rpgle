**free
// ------------------------------------------------------------------
// EXRESET_T - Clear recorded calls or stubs between tests
//
// Features: IMOQRESET SCOPE(*ALL | *CALLS | *STUBS), OBJ(name)
// Put IMOQRESET in your test setup so every test starts clean.
// Run it with the driver EXRESET.
// ------------------------------------------------------------------
ctl-opt main(main);

/copy QRPGLESRC,IMOQ_H

// The dependency this example calls. It is a mock created by the
// driver EXRESET; no real object exists.

// EXPRICE (*SRVPGM), procedure EX_PRICE: price of an item
dcl-pr getPrice packed(7:2) extproc('EX_PRICE');
  item char(5) const;
end-pr;

/copy QRPGLESRC,EXAMPLE_H

dcl-proc main;
  imoq('IMOQRESET');                          // everything, all mocks

  imoq('IMOQWHEN OBJ(EXPRICE) PROC(EX_PRICE) RETURN(''7.00'')');
  getPrice('A0001');

  // Forget the calls, keep the stub
  imoq('IMOQRESET OBJ(EXPRICE) SCOPE(*CALLS)');
  expect(imoq_count('EXPRICE' : 'EX_PRICE') = 0 : 'calls cleared');
  expect(getPrice('A0001') = 7.00 : 'stub still answers');

  // Forget the stub, keep the calls
  imoq('IMOQRESET OBJ(EXPRICE) SCOPE(*STUBS)');
  expect(getPrice('A0001') = 0 : 'no stub left, loose mock returns zero');
  expect(imoq_count('EXPRICE' : 'EX_PRICE') = 2 : 'calls were kept');
end-proc;
