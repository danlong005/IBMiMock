**free
// ------------------------------------------------------------------
// DEMOCUT_T - RPGMOCK demo tests for DEMOCUT.
// The mocks (DEMODEP *PGM, DEMOSRV *SRVPGM strict) are created by the
// MOCKDEMO driver; each test stubs and verifies them through MOCK_H.
// Written with a tiny harness; in RPGUnit the same mock()/mock_ok()
// calls go inside test procedures with assert().
// ------------------------------------------------------------------
ctl-opt main(runTests) option(*srcstmt:*nodebugio);

/copy QTEMP/MOCKINC,MOCK_H

dcl-pr demo_orderTotal packed(11:2) extproc('DEMO_ORDERTOTAL');
  custId char(10) const;
  amount packed(11:2) const;
  state char(2) const;
  custName char(50);
end-pr;

/copy QTEMP/MOCKINC,MOCKTST_H

dcl-proc runTests;
  dcl-pi *n;
    report char(8000);
    failures int(10);
  end-pi;
  tst_init(report);
  test_stubbedValues();
  test_unknownCustomer();
  test_dependencyThrows();
  test_consecutiveReturns();
  test_argumentCapture();
  test_newestMatchingStubWins();
  test_timesLimit();
  test_likeMatcher();
  test_verifyFailureIsReported();
  test_strictMockRejectsUnstubbedCall();
  test_invalidStubbingIsRejected();
  tst_summary(failures);
end-proc;

// ------------------------------------------------------------------
dcl-proc test_stubbedValues;
  dcl-s total packed(11:2);
  dcl-s name char(50);
  tst_begin('stubbed SETPARM and RETURN values reach the code');
  monitor;
    mock('MOCKRESET');
    mock('MOCKWHEN OBJ(DEMODEP) ARGS((1 *EQ C001)) +
          SETPARM((2 ''ACME CORP'') (3 ''1''))');
    mock('MOCKWHEN OBJ(DEMOSRV) PROC(DEMO_CALCTAX) RETURN(''6.00'')');

    total = demo_orderTotal('C001' : 100 : 'PA' : name);

    tst_eqNum(106.00 : total : 'total');
    tst_eqChar('ACME CORP' : name : 'customer name');
    tst_check(mock_ok('MOCKVERIFY OBJ(DEMODEP) ARGS((1 *EQ C001)) +
              TIMES(*ONCE)') : mock_lastError());
    tst_check(mock_ok('MOCKVERIFY OBJ(DEMOSRV) PROC(DEMO_CALCTAX) +
              ARGS((1 *EQ 100) (2 *EQ PA))') : mock_lastError());
    tst_check(mock_ok('MOCKNOMORE') : mock_lastError());
  on-error;
    tst_error(mock_lastError());
  endmon;
  tst_end();
end-proc;

dcl-proc test_unknownCustomer;
  dcl-s total packed(11:2);
  dcl-s name char(50);
  tst_begin('unknown customer never calculates tax');
  monitor;
    mock('MOCKRESET');
    mock('MOCKWHEN OBJ(DEMODEP) SETPARM((3 ''0''))');

    total = demo_orderTotal('NOPE' : 100 : 'PA' : name);

    tst_eqNum(-1 : total : 'total');
    tst_check(mock_ok('MOCKVERIFY OBJ(DEMOSRV) PROC(DEMO_CALCTAX) +
              TIMES(*NEVER)') : mock_lastError());
  on-error;
    tst_error(mock_lastError());
  endmon;
  tst_end();
end-proc;

dcl-proc test_dependencyThrows;
  dcl-s total packed(11:2);
  dcl-s name char(50);
  tst_begin('THROW sends an escape message the code can monitor');
  monitor;
    mock('MOCKRESET');
    mock('MOCKWHEN OBJ(DEMODEP) +
          THROW(CPF9898 QCPFMSG *LIBL ''Customer DB down'')');

    total = demo_orderTotal('C001' : 100 : 'PA' : name);

    tst_eqNum(-2 : total : 'total');
    tst_eqNum(1 : mock_count('DEMODEP' : MOCK_PGM) : 'DEMODEP calls');
  on-error;
    tst_error(mock_lastError());
  endmon;
  tst_end();
end-proc;

dcl-proc test_consecutiveReturns;
  dcl-s name char(50);
  tst_begin('RETURN list answers in order and repeats the last');
  monitor;
    mock('MOCKRESET');
    mock('MOCKWHEN OBJ(DEMODEP) SETPARM((3 ''1''))');
    mock('MOCKWHEN OBJ(DEMOSRV) PROC(DEMO_CALCTAX) +
          RETURN(''1.00'' ''2.00'')');

    tst_eqNum(11 : demo_orderTotal('C1' : 10 : 'PA' : name) : 'call 1');
    tst_eqNum(12 : demo_orderTotal('C1' : 10 : 'PA' : name) : 'call 2');
    tst_eqNum(12 : demo_orderTotal('C1' : 10 : 'PA' : name) : 'call 3');
    tst_check(mock_ok('MOCKVERIFY OBJ(DEMOSRV) PROC(DEMO_CALCTAX) +
              TIMES(*EXACTLY 3)') : mock_lastError());
  on-error;
    tst_error(mock_lastError());
  endmon;
  tst_end();
end-proc;

dcl-proc test_argumentCapture;
  dcl-s name char(50);
  tst_begin('arguments are captured for inspection');
  monitor;
    mock('MOCKRESET');
    mock('MOCKWHEN OBJ(DEMODEP) SETPARM((3 ''1''))');
    mock('MOCKWHEN OBJ(DEMOSRV) PROC(DEMO_CALCTAX) RETURN(''0'')');

    demo_orderTotal('C777' : 25.5 : 'NJ' : name);

    tst_eqChar('C777' : mock_arg('DEMODEP' : MOCK_PGM : 1 : 1)
             : 'DEMODEP parm 1');
    tst_eqChar('25.50' : mock_arg('DEMOSRV' : 'DEMO_CALCTAX'
             : MOCK_LAST : 1) : 'amount');
    tst_eqChar('NJ' : mock_arg('DEMOSRV' : 'demo_calcTax'
             : MOCK_LAST : 2) : 'state (case-insensitive PROC)');
  on-error;
    tst_error(mock_lastError());
  endmon;
  tst_end();
end-proc;

dcl-proc test_newestMatchingStubWins;
  dcl-s name char(50);
  tst_begin('the newest matching MOCKWHEN answers');
  monitor;
    mock('MOCKRESET');
    mock('MOCKWHEN OBJ(DEMODEP) SETPARM((3 ''1''))');
    mock('MOCKWHEN OBJ(DEMOSRV) PROC(DEMO_CALCTAX) RETURN(''5.00'')');
    mock('MOCKWHEN OBJ(DEMOSRV) PROC(DEMO_CALCTAX) +
          ARGS((2 *EQ NY)) RETURN(''8.88'')');
    mock('MOCKWHEN OBJ(DEMOSRV) PROC(DEMO_CALCTAX) +
          ARGS((1 *GT 1000)) RETURN(''99.00'')');

    tst_eqNum(105.00 : demo_orderTotal('C1' : 100 : 'PA' : name)
            : 'default stub');
    tst_eqNum(108.88 : demo_orderTotal('C1' : 100 : 'NY' : name)
            : 'state NY');
    tst_eqNum(5099.00 : demo_orderTotal('C1' : 5000 : 'PA' : name)
            : 'amount > 1000');
  on-error;
    tst_error(mock_lastError());
  endmon;
  tst_end();
end-proc;

dcl-proc test_timesLimit;
  dcl-s name char(50);
  tst_begin('TIMES(n) stops answering after n calls');
  monitor;
    mock('MOCKRESET');
    mock('MOCKWHEN OBJ(DEMODEP) SETPARM((3 ''1'')) TIMES(1)');
    mock('MOCKWHEN OBJ(DEMOSRV) PROC(DEMO_CALCTAX) RETURN(''0'')');

    tst_eqNum(100 : demo_orderTotal('C1' : 100 : 'PA' : name)
            : 'first call');
    // loose program mock: no match leaves parameters untouched
    tst_eqNum(-1 : demo_orderTotal('C1' : 100 : 'PA' : name)
            : 'second call');
  on-error;
    tst_error(mock_lastError());
  endmon;
  tst_end();
end-proc;

dcl-proc test_likeMatcher;
  dcl-s name char(50);
  tst_begin('*LIKE matches with % and _ wildcards');
  monitor;
    mock('MOCKRESET');
    mock('MOCKWHEN OBJ(DEMODEP) ARGS((1 *LIKE ''C_9%'')) +
          SETPARM((2 ''LIKE HIT'') (3 ''1''))');
    mock('MOCKWHEN OBJ(DEMOSRV) PROC(DEMO_CALCTAX) RETURN(''0'')');

    tst_eqNum(1 : demo_orderTotal('CX900' : 1 : 'PA' : name) : 'match');
    tst_eqChar('LIKE HIT' : name : 'name');
    tst_eqNum(-1 : demo_orderTotal('CX800' : 1 : 'PA' : name)
            : 'no match');
  on-error;
    tst_error(mock_lastError());
  endmon;
  tst_end();
end-proc;

dcl-proc test_verifyFailureIsReported;
  dcl-s name char(50);
  tst_begin('failed verifications explain what happened');
  monitor;
    mock('MOCKRESET');
    mock('MOCKWHEN OBJ(DEMODEP) SETPARM((3 ''1''))');
    mock('MOCKWHEN OBJ(DEMOSRV) PROC(DEMO_CALCTAX) RETURN(''1'')');
    demo_orderTotal('C42' : 10 : 'OH' : name);

    tst_check(not mock_ok('MOCKVERIFY OBJ(DEMODEP) TIMES(*EXACTLY 3)')
            : 'MOCKVERIFY TIMES(*EXACTLY 3) should fail');
    tst_check(%scan('exactly 3 time(s)' : mock_lastError()) > 0
              and %scan('''C42''' : mock_lastError()) > 0
            : 'message should describe the calls: ' + mock_lastError());
    tst_check(not mock_ok('MOCKNOMORE OBJ(DEMOSRV)')
            : 'MOCKNOMORE should fail for unverified DEMOSRV call');
  on-error;
    tst_error(mock_lastError());
  endmon;
  tst_end();
end-proc;

dcl-proc test_strictMockRejectsUnstubbedCall;
  dcl-s name char(50);
  dcl-s total packed(11:2);
  dcl-s caught ind;
  tst_begin('strict mock sends MCK0100 for an unstubbed call');
  monitor;
    mock('MOCKRESET');
    mock('MOCKWHEN OBJ(DEMODEP) SETPARM((3 ''1''))');
    mock('MOCKWHEN OBJ(DEMOSRV) PROC(DEMO_CALCTAX) ARGS((2 *EQ PA)) +
          RETURN(''1'')');
    monitor;
      total = demo_orderTotal('C1' : 10 : 'TX' : name);
    on-error;
      caught = *on;
    endmon;
    tst_check(caught : 'escape message expected, total was '
            + %char(total));
    tst_check(%scan('Unexpected call to DEMOSRV.DEMO_CALCTAX'
                    : mock_lastError()) > 0 : mock_lastError());
  on-error;
    tst_error(mock_lastError());
  endmon;
  tst_end();
end-proc;

dcl-proc test_invalidStubbingIsRejected;
  tst_begin('invalid MOCKWHEN parameters are rejected');
  monitor;
    tst_check(not mock_ok('MOCKWHEN OBJ(DEMOSRV) PROC(NOPE) +
              RETURN(''1'')') : 'unknown procedure accepted');
    tst_check(%scan('does not export' : mock_lastError()) > 0
            : mock_lastError());
    tst_check(not mock_ok('MOCKWHEN OBJ(DEMODEP) SETPARM((3 ''X''))')
            : 'invalid indicator accepted');
    tst_check(not mock_ok('MOCKWHEN OBJ(DEMOSRV) PROC(DEMO_CALCTAX) +
              RETURN(''12345678901.99'')') : 'overflow accepted');
    tst_check(not mock_ok('MOCKWHEN OBJ(DEMODEP) ARGS((9 *EQ X))')
            : 'undeclared parameter accepted');
  on-error;
    tst_error(mock_lastError());
  endmon;
  tst_end();
end-proc;
