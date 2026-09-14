**free
// ------------------------------------------------------------------
// EXOMIT_T - Optional parameters: *OMIT and *NOPASS
//
// Features: matchers *NOTPASSED, *OMIT and *ANY
// EX_DISCOUNT's second parameter is options(*nopass:*omit).
// Run it with the driver EXOMIT.
// ------------------------------------------------------------------
ctl-opt main(main);

/copy QRPGLESRC,IMOQ_H

// The dependency this example calls. It is a mock created by the
// driver EXOMIT; no real object exists.

// EXPRICE (*SRVPGM), procedure EX_DISCOUNT: discount for an amount
dcl-pr getDiscount packed(7:2) extproc('EX_DISCOUNT');
  amount packed(7:2) const;
  code char(10) const options(*nopass:*omit);
end-pr;

/copy QRPGLESRC,EXAMPLE_H

dcl-proc main;
  imoq('IMOQRESET');

  imoq('IMOQWHEN OBJ(EXPRICE) PROC(EX_DISCOUNT) +
        ARGS((1 *ANY) (2 *NOTPASSED)) RETURN(''1.00'')');
  imoq('IMOQWHEN OBJ(EXPRICE) PROC(EX_DISCOUNT) +
        ARGS((2 *OMIT)) RETURN(''2.00'')');
  imoq('IMOQWHEN OBJ(EXPRICE) PROC(EX_DISCOUNT) +
        ARGS((2 *EQ VIP)) RETURN(''3.00'')');

  expect(getDiscount(100) = 1.00 : 'code not passed');
  expect(getDiscount(100 : *omit) = 2.00 : 'code passed as *OMIT');
  expect(getDiscount(100 : 'VIP') = 3.00 : 'code VIP');

  expect(imoq_arg('EXPRICE' : 'EX_DISCOUNT' : 1 : 2) = '*NOTPASSED'
         : 'imoq_arg reports a missing parameter');
  expect(imoq_arg('EXPRICE' : 'EX_DISCOUNT' : 2 : 2) = '*OMIT'
         : 'imoq_arg reports an omitted parameter');
end-proc;
