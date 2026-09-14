**free
// ------------------------------------------------------------------
// EXTIMES - A stub that answers only a limited number of calls
//
// Features: MOCKWHEN TIMES(n)
// After n calls the stub is skipped and older stubs answer again.
// ------------------------------------------------------------------
ctl-opt main(main);

/copy QTEMP/MOCKINC,MOCK_H
/copy QTEMP/MOCKINC,EXAMPLE_H

dcl-proc main;
  mock('MOCKRESET');

  mock('MOCKWHEN OBJ(EXPRICE) PROC(EX_PRICE) RETURN(''10.00'')');
  // The first two calls are free
  mock('MOCKWHEN OBJ(EXPRICE) PROC(EX_PRICE) RETURN(''0.00'') TIMES(2)');

  expect(getPrice('A0001') = 0.00 : 'call 1 is free');
  expect(getPrice('A0001') = 0.00 : 'call 2 is free');
  expect(getPrice('A0001') = 10.00 : 'call 3 uses the older stub');
end-proc;
