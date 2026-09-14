**free
// ------------------------------------------------------------------
// EXNEWEST_T - A default answer plus a special case
//
// Features: several MOCKWHENs; the newest matching one wins
// Run it with the driver EXNEWEST.
// ------------------------------------------------------------------
ctl-opt main(main);

/copy QRPGLESRC,IMOQ_H

// The dependency this example calls. It is a mock created by the
// driver EXNEWEST; no real object exists.

// EXPRICE (*SRVPGM), procedure EX_PRICE: price of an item
dcl-pr getPrice packed(7:2) extproc('EX_PRICE');
  item char(5) const;
end-pr;

/copy QRPGLESRC,EXAMPLE_H

dcl-proc main;
  imoq('IMOQRESET');

  // General stub first (this is often done once in setup) ...
  imoq('IMOQWHEN OBJ(EXPRICE) PROC(EX_PRICE) RETURN(''5.00'')');
  // ... then the special case. Newer stubs are checked first.
  imoq('IMOQWHEN OBJ(EXPRICE) PROC(EX_PRICE) +
        ARGS((1 *EQ GOLD1)) RETURN(''99.00'')');

  expect(getPrice('GOLD1') = 99.00 : 'special case wins for GOLD1');
  expect(getPrice('PLAIN') = 5.00 : 'everything else gets the default');
end-proc;
