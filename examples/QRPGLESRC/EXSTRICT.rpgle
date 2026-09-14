**free
// ------------------------------------------------------------------
// EXSTRICT - Fail on any call you did not expect
//
// Features: BEHAVIOR(*STRICT), MOCKWHEN without an answer
// The EXAMPLES driver created the mock with:
//   MOCKPGM OBJ(EXAUDIT) PARMS((*CHAR 20)) BEHAVIOR(*STRICT)
// A strict mock sends MCK0100 for a call that no MOCKWHEN matches.
// ------------------------------------------------------------------
ctl-opt main(main);

/copy QTEMP/MOCKINC,MOCK_H
/copy QTEMP/MOCKINC,EXAMPLE_H

dcl-proc main;
  dcl-s rejected ind;

  mock('MOCKRESET');

  // LOGIN events are allowed. The stub has no answer; it only matches.
  mock('MOCKWHEN OBJ(EXAUDIT) ARGS((1 *EQ LOGIN))');

  writeAudit('LOGIN');

  monitor;
    writeAudit('DELETE');
  on-error;
    rejected = *on;
  endmon;

  expect(rejected : 'DELETE was not expected, so the call fails');
  expect(%scan('Unexpected call to EXAUDIT' : mock_lastError()) > 0
         : 'mock_lastError() explains the unexpected call');
end-proc;
