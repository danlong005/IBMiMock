**free
// ------------------------------------------------------------------
// EXERRMSG_T - What a failed verification tells you
//
// Features: imoq_ok() + imoq_lastError(), imoq() escape message
// Use imoq_ok() in assertions and imoq() for setup: imoq() sends
// escape message IMQ0300 when the command fails.
// Run it with the driver EXERRMSG.
// ------------------------------------------------------------------
ctl-opt main(main);

/copy QRPGLESRC,IMOQ_H

// The dependency this example calls. It is a mock created by the
// driver EXERRMSG; no real object exists.

// EXPRICE (*SRVPGM), procedure EX_PRICE: price of an item
dcl-pr getPrice packed(7:2) extproc('EX_PRICE');
  item char(5) const;
end-pr;

/copy QRPGLESRC,EXAMPLE_H

dcl-proc main;
  dcl-s message varchar(512);
  dcl-s escaped ind;

  imoq('IMOQRESET');
  getPrice('A0001');

  // Expect a call for B0002, but the code called A0001
  expect(not imoq_ok('IMOQVERIFY OBJ(EXPRICE) PROC(EX_PRICE) +
                      ARGS((1 *EQ B0002))') : 'verification fails');

  message = imoq_lastError();
  // Verification failed: expected EXPRICE.EX_PRICE to be called
  // exactly 1 time(s) with (1 *EQ 'B0002') but it matched 0 time(s).
  // Recorded calls: #1('A0001')
  expect(%scan('Verification failed' : message) = 1 : message);
  expect(%scan('''A0001''' : message) > 0
         : 'the message lists the calls that really happened');

  monitor;
    imoq('IMOQVERIFY OBJ(EXPRICE) PROC(EX_PRICE) ARGS((1 *EQ B0002))');
  on-error;
    escaped = *on;
  endmon;
  expect(escaped : 'imoq() sends an escape message instead');
end-proc;
