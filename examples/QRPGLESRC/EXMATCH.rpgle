**free
// ------------------------------------------------------------------
// EXMATCH - Answer differently depending on the arguments
//
// Features: MOCKWHEN ARGS((parm matcher value))
// Matchers: *EQ *NE *GT *GE *LT *LE *LIKE *BLANK *ANY
//           *OMIT *NOTPASSED (see EXOMIT)
// ------------------------------------------------------------------
ctl-opt main(main);

/copy QTEMP/MOCKINC,MOCK_H
/copy QTEMP/MOCKINC,EXAMPLE_H

dcl-proc main;
  mock('MOCKRESET');

  // Parameter 1 equal to A0001
  mock('MOCKWHEN OBJ(EXPRICE) PROC(EX_PRICE) +
        ARGS((1 *EQ A0001)) RETURN(''1.00'')');
  // Parameter 1 starts with B (% = any text, _ = one character)
  mock('MOCKWHEN OBJ(EXPRICE) PROC(EX_PRICE) +
        ARGS((1 *LIKE ''B%'')) RETURN(''2.00'')');
  // Parameter 1 is blank
  mock('MOCKWHEN OBJ(EXPRICE) PROC(EX_PRICE) +
        ARGS((1 *BLANK)) RETURN(''0.50'')');
  // Numbers compare as numbers: amounts over 100 get 10.00 off
  mock('MOCKWHEN OBJ(EXPRICE) PROC(EX_DISCOUNT) +
        ARGS((1 *GT 100)) RETURN(''10.00'')');

  expect(getPrice('A0001') = 1.00 : '*EQ A0001');
  expect(getPrice('B7777') = 2.00 : '*LIKE B%');
  expect(getPrice(' ') = 0.50 : '*BLANK');
  expect(getDiscount(150.00) = 10.00 : '*GT 100');

  // No stub matches: a loose mock returns zero
  expect(getPrice('Z9999') = 0 : 'no match returns zero');
  expect(getDiscount(50.00) = 0 : '50 is not greater than 100');
end-proc;
