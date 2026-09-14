**free
// ------------------------------------------------------------------
// EXTIMES_T - A stub that answers only a limited number of calls
//
// Features: IMOQWHEN TIMES(n)
// After n calls the stub is skipped and older stubs answer again.
// Run it with the driver EXTIMES.
// ------------------------------------------------------------------
ctl-opt main(main);

/copy QRPGLESRC,IMOQ_H

// The dependency this example calls. It is a mock created by the
// driver EXTIMES; no real object exists.

// EXPRICE (*SRVPGM), procedure EX_PRICE: price of an item
dcl-pr getPrice packed(7:2) extproc('EX_PRICE');
  item char(5) const;
end-pr;

/copy QRPGLESRC,EXAMPLE_H

dcl-proc main;
  imoq('IMOQRESET');

  imoq('IMOQWHEN OBJ(EXPRICE) PROC(EX_PRICE) RETURN(''10.00'')');
  // The first two calls are free
  imoq('IMOQWHEN OBJ(EXPRICE) PROC(EX_PRICE) RETURN(''0.00'') TIMES(2)');

  expect(getPrice('A0001') = 0.00 : 'call 1 is free');
  expect(getPrice('A0001') = 0.00 : 'call 2 is free');
  expect(getPrice('A0001') = 10.00 : 'call 3 uses the older stub');
end-proc;
