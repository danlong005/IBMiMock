**free
// ------------------------------------------------------------------
// EXRETURN - Mock a service program procedure and return a value
//
// Features: MOCKSRVPGM, MOCKPROC, MOCKBUILD, MOCKWHEN RETURN
// The EXAMPLES driver created the mock with:
//   MOCKSRVPGM OBJ(EXPRICE) SRCFILE(lib/QSRVSRC) SRCMBR(EXPRICE)
//   MOCKPROC   OBJ(EXPRICE) PROC(EX_PRICE) RTNTYPE(*PACKED 7 2)
//                PARMS((*CHAR 5 *CONST))
//   MOCKBUILD  OBJ(EXPRICE)
// ------------------------------------------------------------------
ctl-opt main(main);

/copy QTEMP/MOCKINC,MOCK_H
/copy QTEMP/MOCKINC,EXAMPLE_H

dcl-proc main;
  mock('MOCKRESET');

  // Every call to EX_PRICE returns 19.99
  mock('MOCKWHEN OBJ(EXPRICE) PROC(EX_PRICE) RETURN(''19.99'')');

  expect(getPrice('A0001') = 19.99 : 'EX_PRICE returns 19.99');
  expect(getPrice('B0002') = 19.99 : 'no ARGS, so every call matches');
end-proc;
