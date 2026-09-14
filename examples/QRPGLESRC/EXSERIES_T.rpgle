**free
// ------------------------------------------------------------------
// EXSERIES_T - Different answers on successive calls
//
// Features: IMOQWHEN RETURN('first' 'second' ...)
// The last value repeats once the list is used up.
// Run it with the driver EXSERIES.
// ------------------------------------------------------------------
ctl-opt main(main);

/copy QRPGLESRC,IMOQ_H

// The dependency this example calls. It is a mock created by the
// driver EXSERIES; no real object exists.

// EXPRICE (*SRVPGM), procedure EX_PRICE: price of an item
dcl-pr getPrice packed(7:2) extproc('EX_PRICE');
  item char(5) const;
end-pr;

/copy QRPGLESRC,EXAMPLE_H

dcl-proc main;
  imoq('IMOQRESET');

  imoq('IMOQWHEN OBJ(EXPRICE) PROC(EX_PRICE) +
        RETURN(''1.00'' ''2.00'' ''3.00'')');

  expect(getPrice('A0001') = 1.00 : 'call 1 returns 1.00');
  expect(getPrice('A0001') = 2.00 : 'call 2 returns 2.00');
  expect(getPrice('A0001') = 3.00 : 'call 3 returns 3.00');
  expect(getPrice('A0001') = 3.00 : 'call 4 repeats the last value');
end-proc;
