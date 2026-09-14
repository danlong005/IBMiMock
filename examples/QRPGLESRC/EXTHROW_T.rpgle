**free
// ------------------------------------------------------------------
// EXTHROW_T - Make a dependency fail with an escape message
//
// Features: IMOQWHEN THROW(msgid msgf library 'message data')
// The caller sees a normal escape message, so MONITOR works as usual.
// Run it with the driver EXTHROW.
// ------------------------------------------------------------------
ctl-opt main(main);

/copy QRPGLESRC,IMOQ_H

// The dependency this example calls. It is a mock created by the
// driver EXTHROW; no real object exists.

// EXCUST (*PGM): look up a customer name
dcl-pr getCustomer extpgm('EXCUST');
  custId char(5) const;
  name char(30);
  found ind;
end-pr;

/copy QRPGLESRC,EXAMPLE_H

dcl-proc main;
  dcl-s name char(30);
  dcl-s found ind;
  dcl-s failed ind;

  imoq('IMOQRESET');

  // THROW takes one set of parentheses
  imoq('IMOQWHEN OBJ(EXCUST) +
        THROW(CPF9898 QCPFMSG *LIBL ''Customer file is locked'')');

  monitor;
    getCustomer('C0001' : name : found);
  on-error;
    failed = *on;
  endmon;

  expect(failed : 'EXCUST sends an escape message');
end-proc;
