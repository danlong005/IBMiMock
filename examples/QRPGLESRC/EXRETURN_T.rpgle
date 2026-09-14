**free
// ------------------------------------------------------------------
// EXRETURN_T - Mock a service program procedure and return a value
//
// Features: IMOQSRVPGM, IMOQPROC, IMOQBUILD, IMOQWHEN RETURN
// The driver EXRETURN creates the mock with:
//   IMOQSRVPGM OBJ(EXPRICE)
//   IMOQPROC   OBJ(EXPRICE) PROC(EX_PRICE) RTNTYPE(*PACKED 7 2)
//                PARMS((*CHAR 5 *CONST))
//   IMOQBUILD  OBJ(EXPRICE)
// ------------------------------------------------------------------
ctl-opt main(main);

/copy QRPGLESRC,IMOQ_H

// The dependency this example calls. It is a mock created by the
// driver EXRETURN; no real object exists.

// EXPRICE (*SRVPGM), procedure EX_PRICE: price of an item
dcl-pr getPrice packed(7:2) extproc('EX_PRICE');
  item char(5) const;
end-pr;

/copy QRPGLESRC,EXAMPLE_H

dcl-proc main;
  imoq('IMOQRESET');

  // Every call to EX_PRICE returns 19.99
  imoq('IMOQWHEN OBJ(EXPRICE) PROC(EX_PRICE) RETURN(''19.99'')');

  expect(getPrice('A0001') = 19.99 : 'EX_PRICE returns 19.99');
  expect(getPrice('B0002') = 19.99 : 'no ARGS, so every call matches');
end-proc;
