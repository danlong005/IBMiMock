**free
// ------------------------------------------------------------------
// EXFAILMSG - What a failed verification tells you
//
// Features: mock_ok() + mock_lastError(), mock() escape message
// Use mock_ok() in assertions and mock() for setup: mock() sends
// escape message MCK0300 when the command fails.
// ------------------------------------------------------------------
ctl-opt main(main);

/copy QTEMP/MOCKINC,MOCK_H
/copy QTEMP/MOCKINC,EXAMPLE_H

dcl-proc main;
  dcl-s message varchar(512);
  dcl-s escaped ind;

  mock('MOCKRESET');
  getPrice('A0001');

  // Expect a call for B0002, but the code called A0001
  expect(not mock_ok('MOCKVERIFY OBJ(EXPRICE) PROC(EX_PRICE) +
                      ARGS((1 *EQ B0002))') : 'verification fails');

  message = mock_lastError();
  // Verification failed: expected EXPRICE.EX_PRICE to be called
  // exactly 1 time(s) with (1 *EQ 'B0002') but it matched 0 time(s).
  // Recorded calls: #1('A0001')
  expect(%scan('Verification failed' : message) = 1 : message);
  expect(%scan('''A0001''' : message) > 0
         : 'the message lists the calls that really happened');

  monitor;
    mock('MOCKVERIFY OBJ(EXPRICE) PROC(EX_PRICE) ARGS((1 *EQ B0002))');
  on-error;
    escaped = *on;
  endmon;
  expect(escaped : 'mock() sends an escape message instead');
end-proc;
