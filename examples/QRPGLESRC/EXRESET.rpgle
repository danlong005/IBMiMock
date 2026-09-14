**free
// ------------------------------------------------------------------
// EXRESET - Clear recorded calls or stubs between tests
//
// Features: MOCKRESET SCOPE(*ALL | *CALLS | *STUBS), OBJ(name)
// Put MOCKRESET in your test setup so every test starts clean.
// ------------------------------------------------------------------
ctl-opt main(main);

/copy QTEMP/MOCKINC,MOCK_H
/copy QTEMP/MOCKINC,EXAMPLE_H

dcl-proc main;
  mock('MOCKRESET');                          // everything, all mocks

  mock('MOCKWHEN OBJ(EXPRICE) PROC(EX_PRICE) RETURN(''7.00'')');
  getPrice('A0001');

  // Forget the calls, keep the stub
  mock('MOCKRESET OBJ(EXPRICE) SCOPE(*CALLS)');
  expect(mock_count('EXPRICE' : 'EX_PRICE') = 0 : 'calls cleared');
  expect(getPrice('A0001') = 7.00 : 'stub still answers');

  // Forget the stub, keep the calls
  mock('MOCKRESET OBJ(EXPRICE) SCOPE(*STUBS)');
  expect(getPrice('A0001') = 0 : 'no stub left, loose mock returns zero');
  expect(mock_count('EXPRICE' : 'EX_PRICE') = 2 : 'calls were kept');
end-proc;
