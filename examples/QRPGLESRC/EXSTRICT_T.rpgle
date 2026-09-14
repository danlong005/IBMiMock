**free
// ------------------------------------------------------------------
// EXSTRICT_T - Fail on any call you did not expect
//
// Features: BEHAVIOR(*STRICT), IMOQWHEN without an answer
// The driver EXSTRICT creates the mock with:
//   IMOQPGM OBJ(EXAUDIT) PARMS((*CHAR 20)) BEHAVIOR(*STRICT)
// A strict mock sends IMQ0100 for a call that no IMOQWHEN matches.
// ------------------------------------------------------------------
ctl-opt main(main);

/copy QRPGLESRC,IMOQ_H

// The dependency this example calls. It is a mock created by the
// driver EXSTRICT; no real object exists.

// EXAUDIT (*PGM): record an audit event
dcl-pr writeAudit extpgm('EXAUDIT');
  event char(20) const;
end-pr;

/copy QRPGLESRC,EXAMPLE_H

dcl-proc main;
  dcl-s rejected ind;

  imoq('IMOQRESET');

  // LOGIN events are allowed. The stub has no answer; it only matches.
  imoq('IMOQWHEN OBJ(EXAUDIT) ARGS((1 *EQ LOGIN))');

  writeAudit('LOGIN');

  monitor;
    writeAudit('DELETE');
  on-error;
    rejected = *on;
  endmon;

  expect(rejected : 'DELETE was not expected, so the call fails');
  expect(%scan('Unexpected call to EXAUDIT' : imoq_lastError()) > 0
         : 'imoq_lastError() explains the unexpected call');
end-proc;
