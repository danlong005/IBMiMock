**free
// ------------------------------------------------------------------
// EXOVERRIDE - A default answer plus a special case
//
// Features: several MOCKWHENs; the newest matching one wins
// ------------------------------------------------------------------
ctl-opt main(main);

/copy QTEMP/MOCKINC,MOCK_H
/copy QTEMP/MOCKINC,EXAMPLE_H

dcl-proc main;
  mock('MOCKRESET');

  // General stub first (this is often done once in setup) ...
  mock('MOCKWHEN OBJ(EXPRICE) PROC(EX_PRICE) RETURN(''5.00'')');
  // ... then the special case. Newer stubs are checked first.
  mock('MOCKWHEN OBJ(EXPRICE) PROC(EX_PRICE) +
        ARGS((1 *EQ GOLD1)) RETURN(''99.00'')');

  expect(getPrice('GOLD1') = 99.00 : 'special case wins for GOLD1');
  expect(getPrice('PLAIN') = 5.00 : 'everything else gets the default');
end-proc;
