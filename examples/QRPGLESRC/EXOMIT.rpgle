**free
// ------------------------------------------------------------------
// EXOMIT - Optional parameters: *OMIT and *NOPASS
//
// Features: matchers *NOTPASSED, *OMIT and *ANY
// EX_DISCOUNT's second parameter is options(*nopass:*omit).
// ------------------------------------------------------------------
ctl-opt main(main);

/copy QTEMP/MOCKINC,MOCK_H
/copy QTEMP/MOCKINC,EXAMPLE_H

dcl-proc main;
  mock('MOCKRESET');

  mock('MOCKWHEN OBJ(EXPRICE) PROC(EX_DISCOUNT) +
        ARGS((1 *ANY) (2 *NOTPASSED)) RETURN(''1.00'')');
  mock('MOCKWHEN OBJ(EXPRICE) PROC(EX_DISCOUNT) +
        ARGS((2 *OMIT)) RETURN(''2.00'')');
  mock('MOCKWHEN OBJ(EXPRICE) PROC(EX_DISCOUNT) +
        ARGS((2 *EQ VIP)) RETURN(''3.00'')');

  expect(getDiscount(100) = 1.00 : 'code not passed');
  expect(getDiscount(100 : *omit) = 2.00 : 'code passed as *OMIT');
  expect(getDiscount(100 : 'VIP') = 3.00 : 'code VIP');

  expect(mock_arg('EXPRICE' : 'EX_DISCOUNT' : 1 : 2) = '*NOTPASSED'
         : 'mock_arg reports a missing parameter');
  expect(mock_arg('EXPRICE' : 'EX_DISCOUNT' : 2 : 2) = '*OMIT'
         : 'mock_arg reports an omitted parameter');
end-proc;
