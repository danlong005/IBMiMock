**free
// ------------------------------------------------------------------
// EXSEQUENCE - Different answers on successive calls
//
// Features: MOCKWHEN RETURN('first' 'second' ...)
// The last value repeats once the list is used up.
// ------------------------------------------------------------------
ctl-opt main(main);

/copy QTEMP/MOCKINC,MOCK_H
/copy QTEMP/MOCKINC,EXAMPLE_H

dcl-proc main;
  mock('MOCKRESET');

  mock('MOCKWHEN OBJ(EXPRICE) PROC(EX_PRICE) +
        RETURN(''1.00'' ''2.00'' ''3.00'')');

  expect(getPrice('A0001') = 1.00 : 'call 1 returns 1.00');
  expect(getPrice('A0001') = 2.00 : 'call 2 returns 2.00');
  expect(getPrice('A0001') = 3.00 : 'call 3 returns 3.00');
  expect(getPrice('A0001') = 3.00 : 'call 4 repeats the last value');
end-proc;
