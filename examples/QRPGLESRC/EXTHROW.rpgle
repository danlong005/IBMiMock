**free
// ------------------------------------------------------------------
// EXTHROW - Make a dependency fail with an escape message
//
// Features: MOCKWHEN THROW(msgid msgf library 'message data')
// The caller sees a normal escape message, so MONITOR works as usual.
// ------------------------------------------------------------------
ctl-opt main(main);

/copy QTEMP/MOCKINC,MOCK_H
/copy QTEMP/MOCKINC,EXAMPLE_H

dcl-proc main;
  dcl-s name char(30);
  dcl-s found ind;
  dcl-s failed ind;

  mock('MOCKRESET');

  // THROW takes one set of parentheses
  mock('MOCKWHEN OBJ(EXCUST) +
        THROW(CPF9898 QCPFMSG *LIBL ''Customer file is locked'')');

  monitor;
    getCustomer('C0001' : name : found);
  on-error;
    failed = *on;
  endmon;

  expect(failed : 'EXCUST sends an escape message');
end-proc;
