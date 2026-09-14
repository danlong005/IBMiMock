# IBMIMOCK Examples

The `examples` folder has one short program for each IBMIMOCK feature. This page
walks through them in a sensible reading order: what each one teaches, the lines
that matter, and what to notice.

For the concepts behind the examples, see the
[Programmer's Guide](PROGRAMMERS_GUIDE.md).

## Contents

- [Running the examples](#running-the-examples)
- [How the examples are set up](#how-the-examples-are-set-up)
- [Anatomy of an example](#anatomy-of-an-example)
- Creating mocks and answering calls
  - [EXPGM: mock a program and fill in output parameters](#expgm-mock-a-program-and-fill-in-output-parameters)
  - [EXRETURN: return a value from a service program procedure](#exreturn-return-a-value-from-a-service-program-procedure)
  - [EXMATCH: answer based on the arguments](#exmatch-answer-based-on-the-arguments)
  - [EXOVERRIDE: a default answer plus a special case](#exoverride-a-default-answer-plus-a-special-case)
  - [EXSEQUENCE: different answers on successive calls](#exsequence-different-answers-on-successive-calls)
  - [EXTIMES: answer only a limited number of calls](#extimes-answer-only-a-limited-number-of-calls)
  - [EXTHROW: make a dependency fail](#exthrow-make-a-dependency-fail)
  - [EXSTRICT: fail on unexpected calls](#exstrict-fail-on-unexpected-calls)
  - [EXOMIT: optional parameters](#exomit-optional-parameters)
- Checking what happened
  - [EXVERIFY: check how often something was called](#exverify-check-how-often-something-was-called)
  - [EXNOMORE: make sure nothing else was called](#exnomore-make-sure-nothing-else-was-called)
  - [EXCAPTURE: look at the arguments](#excapture-look-at-the-arguments)
  - [EXFAILMSG: read a failed verification](#exfailmsg-read-a-failed-verification)
- Test housekeeping
  - [EXRESET: clear calls or stubs between tests](#exreset-clear-calls-or-stubs-between-tests)
  - [EXCL: use the mocks from CL](#excl-use-the-mocks-from-cl)
  - [EXAMPLES: a complete test driver](#examples-a-complete-test-driver)
- [The end-to-end demo](#the-end-to-end-demo)
- [Writing your own test](#writing-your-own-test)

---

## Running the examples

Build IBMIMOCK with the examples, then run the driver:

```
CALL QTEMP/BUILD PARM('IBMIMOCK' '/home/ME/IBMiMock' '*YES')
CALL IBMIMOCK/EXAMPLES PARM('IBMIMOCK')
```

`EXAMPLES` writes one line per example to the job log:

```
ok   EXPGM
ok   EXRETURN
...
ok   EXCL
ok   MOCKCHK
EXAMPLES: all examples passed
```

When an example fails, the line names the expectation that failed, for example
`FAIL EXRETURN - EX_PRICE returns 19.99`. `EXAMPLES` changes the current library
and library list of the job that runs it.

## How the examples are set up

To keep each example tiny, the examples call three dependencies **directly**
instead of going through separate code under test. None of these dependencies
exists as a real object. The driver `EXAMPLES` creates all three as mocks
before running anything.

| Mock | Type | Plays the part of | Interface |
|---|---|---|---|
| `EXCUST` | `*PGM` | Customer lookup | `custId char(5) const`, `name char(30)`, `found ind` |
| `EXAUDIT` | `*PGM`, strict | Audit trail | `event char(20) const` |
| `EXPRICE` | `*SRVPGM` | Pricing service | `EX_PRICE(item char(5) const) packed(7:2)`<br>`EX_DISCOUNT(amount packed(7:2) const : code char(10) const options(*nopass:*omit)) packed(7:2)`<br>`EX_LOG(text char(50) const)` |

The prototypes live in
[`examples/QRPGLESRC/EXAMPLE_H`](../examples/QRPGLESRC/EXAMPLE_H.rpgleinc) as
`getCustomer`, `writeAudit`, `getPrice`, `getDiscount` and `logMessage`.

In a real project, the mocks stand in for programs and service programs that
already exist. Your tests call your own code, and that code calls the mocks.
[The end-to-end demo](#the-end-to-end-demo) shows that complete setup.

## Anatomy of an example

Every RPG example is a small linear-main program:

```rpgle
**free
ctl-opt main(main);

/copy QTEMP/MOCKINC,MOCK_H          // mock(), mock_ok(), mock_arg() ...
/copy QTEMP/MOCKINC,EXAMPLE_H       // dependency prototypes + expect()

dcl-proc main;
  mock('MOCKRESET');                // 1. start clean

  mock('MOCKWHEN ...');             // 2. say what the mock should do

  // 3. call something and check the result
  expect(getPrice('A0001') = 19.99 : 'EX_PRICE returns 19.99');

  // 4. optionally verify the calls
  expect(mock_ok('MOCKVERIFY ...') : mock_lastError());
end-proc;
```

- **`mock(cmd)`** runs any MOCK command, and stops the example with MCK0300 if
  the command fails.
- **`mock_ok(cmd)`** runs a MOCK command and returns `*off` if it fails. It suits
  verifications.
- **`expect(condition : description)`** stops the example with that description
  when the condition is false.
- **Quoting:** inside an RPG string, every quote that CL needs is doubled:
  `RETURN(''19.99'')`.

---

## Creating mocks and answering calls

### EXPGM: mock a program and fill in output parameters

[`examples/QRPGLESRC/EXPGM.rpgle`](../examples/QRPGLESRC/EXPGM.rpgle)

A program "answers" by writing into the caller's parameters, which is what
`SETPARM` does.

```rpgle
// Driver: MOCKPGM OBJ(EXCUST) PARMS((*CHAR 5) (*CHAR 30) (*IND))
mock('MOCKWHEN OBJ(EXCUST) +
      SETPARM((2 ''Ada Lovelace'') (3 ''1''))');

getCustomer('C0001' : name : found);

expect(name = 'Ada Lovelace' : 'name is set by SETPARM');
expect(found : 'found is set by SETPARM');
```

What to notice:
- **Parameters are numbered from 1.** `SETPARM((2 …))` writes the second
  parameter.
- **Values are text.** They're converted to the type declared on `MOCKPGM
  PARMS`: `'1'` becomes an indicator that is on.
- **Program mocks don't need `PROC`.**

### EXRETURN: return a value from a service program procedure

[`examples/QRPGLESRC/EXRETURN.rpgle`](../examples/QRPGLESRC/EXRETURN.rpgle)

```rpgle
// Driver: MOCKSRVPGM OBJ(EXPRICE) SRCFILE(lib/QSRVSRC) SRCMBR(EXPRICE)
//         MOCKPROC   OBJ(EXPRICE) PROC(EX_PRICE) RTNTYPE(*PACKED 7 2)
//                      PARMS((*CHAR 5 *CONST))
//         MOCKBUILD  OBJ(EXPRICE)
mock('MOCKWHEN OBJ(EXPRICE) PROC(EX_PRICE) RETURN(''19.99'')');

expect(getPrice('A0001') = 19.99 : 'EX_PRICE returns 19.99');
expect(getPrice('B0002') = 19.99 : 'no ARGS, so every call matches');
```

What to notice:
- **Three commands create a service program mock.** `MOCKSRVPGM` reads the
  exports, `MOCKPROC` describes the procedure, and `MOCKBUILD` creates the
  object.
- **`RETURN` needs a return type.** It only works for procedures declared with
  `RTNTYPE`.
- **Without `ARGS`, a stub matches every call.**

### EXMATCH: answer based on the arguments

[`examples/QRPGLESRC/EXMATCH.rpgle`](../examples/QRPGLESRC/EXMATCH.rpgle)

```rpgle
mock('MOCKWHEN OBJ(EXPRICE) PROC(EX_PRICE) +
      ARGS((1 *EQ A0001)) RETURN(''1.00'')');
mock('MOCKWHEN OBJ(EXPRICE) PROC(EX_PRICE) +
      ARGS((1 *LIKE ''B%'')) RETURN(''2.00'')');
mock('MOCKWHEN OBJ(EXPRICE) PROC(EX_PRICE) +
      ARGS((1 *BLANK)) RETURN(''0.50'')');
mock('MOCKWHEN OBJ(EXPRICE) PROC(EX_DISCOUNT) +
      ARGS((1 *GT 100)) RETURN(''10.00'')');

expect(getPrice('A0001') = 1.00 : '*EQ A0001');
expect(getPrice('B7777') = 2.00 : '*LIKE B%');
expect(getPrice(' ') = 0.50 : '*BLANK');
expect(getDiscount(150.00) = 10.00 : '*GT 100');
expect(getPrice('Z9999') = 0 : 'no match returns zero');
```

What to notice:
- **`ARGS` entries are `(parameter matcher value)`.** Every entry must match for
  the stub to answer.
- **The matchers are** `*EQ`, `*NE`, `*GT`, `*GE`, `*LT`, `*LE`, `*LIKE` (`%` is
  any text, `_` is one character), `*BLANK`, `*ANY`, `*OMIT` and `*NOTPASSED`.
- **Numbers compare as numbers**, so `150.00` is greater than `100`.
- **A loose mock returns zero or blanks when nothing matches.**

### EXOVERRIDE: a default answer plus a special case

[`examples/QRPGLESRC/EXOVERRIDE.rpgle`](../examples/QRPGLESRC/EXOVERRIDE.rpgle)

```rpgle
mock('MOCKWHEN OBJ(EXPRICE) PROC(EX_PRICE) RETURN(''5.00'')');   // default
mock('MOCKWHEN OBJ(EXPRICE) PROC(EX_PRICE) +
      ARGS((1 *EQ GOLD1)) RETURN(''99.00'')');                 // special case

expect(getPrice('GOLD1') = 99.00 : 'special case wins for GOLD1');
expect(getPrice('PLAIN') = 5.00 : 'everything else gets the default');
```

What to notice:
- **The newest matching stub wins.** Stubs are checked from newest to oldest.
- **Typical use:** set general answers in your test setup, and add special cases
  inside individual tests.

### EXSEQUENCE: different answers on successive calls

[`examples/QRPGLESRC/EXSEQUENCE.rpgle`](../examples/QRPGLESRC/EXSEQUENCE.rpgle)

```rpgle
mock('MOCKWHEN OBJ(EXPRICE) PROC(EX_PRICE) +
      RETURN(''1.00'' ''2.00'' ''3.00'')');

expect(getPrice('A0001') = 1.00 : 'call 1 returns 1.00');
expect(getPrice('A0001') = 2.00 : 'call 2 returns 2.00');
expect(getPrice('A0001') = 3.00 : 'call 3 returns 3.00');
expect(getPrice('A0001') = 3.00 : 'call 4 repeats the last value');
```

What to notice:
- **List several values in `RETURN`.** They're returned in order, and the last
  one repeats.
- **Use this for loops and retries,** for example "fails twice, then succeeds".

### EXTIMES: answer only a limited number of calls

[`examples/QRPGLESRC/EXTIMES.rpgle`](../examples/QRPGLESRC/EXTIMES.rpgle)

```rpgle
mock('MOCKWHEN OBJ(EXPRICE) PROC(EX_PRICE) RETURN(''10.00'')');
mock('MOCKWHEN OBJ(EXPRICE) PROC(EX_PRICE) RETURN(''0.00'') TIMES(2)');

expect(getPrice('A0001') = 0.00 : 'call 1 is free');
expect(getPrice('A0001') = 0.00 : 'call 2 is free');
expect(getPrice('A0001') = 10.00 : 'call 3 uses the older stub');
```

What to notice:
- **`TIMES(n)` limits a stub to n calls.** After that it's skipped, and older
  stubs answer again.
- **The default is `TIMES(*ALWAYS)`.**

### EXTHROW: make a dependency fail

[`examples/QRPGLESRC/EXTHROW.rpgle`](../examples/QRPGLESRC/EXTHROW.rpgle)

```rpgle
mock('MOCKWHEN OBJ(EXCUST) +
      THROW(CPF9898 QCPFMSG *LIBL ''Customer file is locked'')');

monitor;
  getCustomer('C0001' : name : found);
on-error;
  failed = *on;
endmon;

expect(failed : 'EXCUST sends an escape message');
```

What to notice:
- **The format is `THROW(message-id message-file library 'message data')`.** It
  takes one set of parentheses.
- **The caller gets a normal escape message**, so error handling can be tested
  exactly as it runs in production.
- **`THROW(*MOCK)`** sends IBMIMOCK's own MCK0101.

### EXSTRICT: fail on unexpected calls

[`examples/QRPGLESRC/EXSTRICT.rpgle`](../examples/QRPGLESRC/EXSTRICT.rpgle)

```rpgle
// Driver: MOCKPGM OBJ(EXAUDIT) PARMS((*CHAR 20)) BEHAVIOR(*STRICT)
mock('MOCKWHEN OBJ(EXAUDIT) ARGS((1 *EQ LOGIN))');

writeAudit('LOGIN');              // allowed

monitor;
  writeAudit('DELETE');           // not allowed
on-error;
  rejected = *on;
endmon;

expect(rejected : 'DELETE was not expected, so the call fails');
expect(%scan('Unexpected call to EXAUDIT' : mock_lastError()) > 0
       : 'mock_lastError() explains the unexpected call');
```

What to notice:
- **A strict mock rejects unmatched calls.** Any call that no `MOCKWHEN` matches
  gets escape message MCK0100.
- **A `MOCKWHEN` doesn't need an answer.** Here it only marks `LOGIN` as an
  allowed call.
- **Strictness belongs to the mock object.** Choose it on `MOCKPGM` or
  `MOCKSRVPGM`.

### EXOMIT: optional parameters

[`examples/QRPGLESRC/EXOMIT.rpgle`](../examples/QRPGLESRC/EXOMIT.rpgle)

```rpgle
// EX_DISCOUNT's second parameter is options(*nopass:*omit)
mock('MOCKWHEN OBJ(EXPRICE) PROC(EX_DISCOUNT) +
      ARGS((1 *ANY) (2 *NOTPASSED)) RETURN(''1.00'')');
mock('MOCKWHEN OBJ(EXPRICE) PROC(EX_DISCOUNT) +
      ARGS((2 *OMIT)) RETURN(''2.00'')');
mock('MOCKWHEN OBJ(EXPRICE) PROC(EX_DISCOUNT) +
      ARGS((2 *EQ VIP)) RETURN(''3.00'')');

expect(getDiscount(100) = 1.00 : 'code not passed');
expect(getDiscount(100 : *omit) = 2.00 : 'code passed as *OMIT');
expect(getDiscount(100 : 'VIP') = 3.00 : 'code VIP');

expect(mock_arg('EXPRICE' : 'EX_DISCOUNT' : 1 : 2) = '*NOTPASSED' : ...);
expect(mock_arg('EXPRICE' : 'EX_DISCOUNT' : 2 : 2) = '*OMIT' : ...);
```

What to notice:
- **`*NOTPASSED` and `*OMIT` are different.** `*NOTPASSED` matches a parameter
  that was left off the call (`*NOPASS`). `*OMIT` matches one passed as
  `*OMIT`.
- **`*ANY` matches anything,** including missing parameters.
- **`mock_arg` reports missing parameters** as `*NOTPASSED` or `*OMIT`.

---

## Checking what happened

### EXVERIFY: check how often something was called

[`examples/QRPGLESRC/EXVERIFY.rpgle`](../examples/QRPGLESRC/EXVERIFY.rpgle)

```rpgle
logMessage('started');
logMessage('working');
logMessage('working');

expect(mock_ok('MOCKVERIFY OBJ(EXPRICE) PROC(EX_LOG) +
                TIMES(*EXACTLY 3)') : mock_lastError());
expect(mock_ok('MOCKVERIFY OBJ(EXPRICE) PROC(EX_LOG) +
                ARGS((1 *EQ ''working'')) TIMES(*EXACTLY 2)')
       : mock_lastError());
expect(mock_ok('MOCKVERIFY OBJ(EXPRICE) PROC(EX_LOG) +
                ARGS((1 *EQ ''started'')) TIMES(*ONCE)')
       : mock_lastError());
expect(mock_ok('MOCKVERIFY OBJ(EXPRICE) PROC(EX_LOG) +
                ARGS((1 *EQ ''stopped'')) TIMES(*NEVER)')
       : mock_lastError());
```

What to notice:
- **The `TIMES` forms are** `*ONCE`, `*NEVER`, `*EXACTLY n`, `*ATLEAST n` and
  `*ATMOST n`. The default is `*EXACTLY 1`.
- **Add `ARGS` to count only the matching calls.**
- **Quote mixed-case values.** An unquoted `working` would be uppercased by CL.
- **Pass `mock_lastError()` as the assertion message** so a failure explains
  itself.

### EXNOMORE: make sure nothing else was called

[`examples/QRPGLESRC/EXNOMORE.rpgle`](../examples/QRPGLESRC/EXNOMORE.rpgle)

```rpgle
logMessage('hello');
getPrice('A0001');

expect(mock_ok('MOCKVERIFY OBJ(EXPRICE) PROC(EX_LOG)') : mock_lastError());
expect(not mock_ok('MOCKNOMORE') : 'the EX_PRICE call is not verified yet');

expect(mock_ok('MOCKVERIFY OBJ(EXPRICE) PROC(EX_PRICE)') : mock_lastError());
expect(mock_ok('MOCKNOMORE') : 'every call is now verified');
```

What to notice:
- **A successful `MOCKVERIFY` marks its matching calls as verified.**
- **`MOCKNOMORE` catches surprise calls.** It fails while any recorded call is
  still unverified.
- **Limit it with `OBJ(name)`** to check just one mock.

### EXCAPTURE: look at the arguments

[`examples/QRPGLESRC/EXCAPTURE.rpgle`](../examples/QRPGLESRC/EXCAPTURE.rpgle)

```rpgle
getPrice('A0001');
getPrice('B0002');
getDiscount(250.00 : 'SPRING');
getCustomer('C0042' : name : found);

expect(mock_count('EXPRICE' : 'EX_PRICE') = 2 : 'EX_PRICE called twice');
expect(mock_arg('EXPRICE' : 'EX_PRICE' : 1 : 1) = 'A0001' : ...);
expect(mock_arg('EXPRICE' : 'EX_PRICE' : MOCK_LAST : 1) = 'B0002' : ...);
expect(mock_arg('EXPRICE' : 'EX_DISCOUNT' : MOCK_LAST : 1) = '250.00' : ...);
expect(mock_arg('EXCUST' : MOCK_PGM : MOCK_LAST : 1) = 'C0042' : ...);
```

What to notice:
- **The call is `mock_arg(mock : procedure : call number : parameter number)`.**
- **`MOCK_LAST` picks the most recent call**, and `MOCK_PGM` is the procedure
  name for program mocks.
- **Values come back as text:** numbers formatted like `250.00`, trailing blanks
  removed.
- **Capture when a matcher can't express the check,** such as a value computed
  by the code under test.

### EXFAILMSG: read a failed verification

[`examples/QRPGLESRC/EXFAILMSG.rpgle`](../examples/QRPGLESRC/EXFAILMSG.rpgle)

```rpgle
getPrice('A0001');

expect(not mock_ok('MOCKVERIFY OBJ(EXPRICE) PROC(EX_PRICE) +
                    ARGS((1 *EQ B0002))') : 'verification fails');

message = mock_lastError();
```

`message` now contains:

```
Verification failed: expected EXPRICE.EX_PRICE to be called exactly 1 time(s)
with (1 *EQ 'B0002') but it matched 0 time(s). Recorded calls: #1('A0001')
```

What to notice:
- **The message lists the calls that really happened**, which is usually all
  you need to spot the bug.
- **`mock()` sends an escape message instead.** It fails with MCK0300, so use
  `mock()` for setup and `mock_ok()` for checks.

---

## Test housekeeping

### EXRESET: clear calls or stubs between tests

[`examples/QRPGLESRC/EXRESET.rpgle`](../examples/QRPGLESRC/EXRESET.rpgle)

```rpgle
mock('MOCKWHEN OBJ(EXPRICE) PROC(EX_PRICE) RETURN(''7.00'')');
getPrice('A0001');

mock('MOCKRESET OBJ(EXPRICE) SCOPE(*CALLS)');     // forget calls, keep stub
expect(mock_count('EXPRICE' : 'EX_PRICE') = 0 : 'calls cleared');
expect(getPrice('A0001') = 7.00 : 'stub still answers');

mock('MOCKRESET OBJ(EXPRICE) SCOPE(*STUBS)');     // forget stub, keep calls
expect(getPrice('A0001') = 0 : 'no stub left, loose mock returns zero');
expect(mock_count('EXPRICE' : 'EX_PRICE') = 2 : 'calls were kept');
```

What to notice:
- **`MOCKRESET` with no parameters clears everything for every mock.** Put it
  in your test setup.
- **`MOCKRESET` never deletes mock objects**, so there's nothing to rebuild.
  `MOCKRMV` is the command that removes mocks.

### EXCL: use the mocks from CL

[`examples/QCLLESRC/EXCL.clle`](../examples/QCLLESRC/EXCL.clle)

```
MOCKWHEN   OBJ(EXCUST) ARGS((1 *EQ C0042)) +
             SETPARM((2 'Grace Hopper') (3 '1'))
CALL       PGM(EXCUST) PARM('C0042' &NAME &FOUND)

MOCKCOUNT  OBJ(EXCUST) RTNVAL(&COUNT)             /* &COUNT *DEC 10 0 */
MOCKGETARG OBJ(EXCUST) PARM(1) CALL(*LAST) RTNVAL(&ARG)   /* *CHAR 256 */

MOCKVERIFY OBJ(EXCUST) ARGS((1 *EQ C0042)) TIMES(*ONCE)
MOCKVERIFY OBJ(EXCUST) TIMES(*NEVER)
MONMSG     MSGID(MCK0200) EXEC(CHGVAR VAR(&FAILED) VALUE('1'))
```

What to notice:
- **The same commands work in CL,** without the doubled quotes.
- **`MOCKCOUNT` and `MOCKGETARG` only work in CL programs,** because they return
  values into CL variables. RPG uses `mock_count` and `mock_arg`.
- **A failed `MOCKVERIFY` sends MCK0200,** which CL can monitor.

### EXAMPLES: a complete test driver

[`examples/QCLLESRC/EXAMPLES.clle`](../examples/QCLLESRC/EXAMPLES.clle)

The driver is a template for your own test drivers:

```
/* 1. The library must come after QTEMP */
CHGCURLIB  CURLIB(*CRTDFT)
RMVLIBLE   LIB(&LIB)
MONMSG     MSGID(CPF2104)
ADDLIBLE   LIB(&LIB) POSITION(*LAST)

/* 2. Create the mocks before anything uses them */
MOCKPGM    OBJ(EXCUST) PARMS((*CHAR 5) (*CHAR 30) (*IND))
MOCKPGM    OBJ(EXAUDIT) PARMS((*CHAR 20)) BEHAVIOR(*STRICT)
MOCKSRVPGM OBJ(EXPRICE) SRCFILE(&SRCLIB/QSRVSRC) SRCMBR(EXPRICE)
MOCKPROC   OBJ(EXPRICE) PROC(EX_PRICE) RTNTYPE(*PACKED 7 2) +
             PARMS((*CHAR 5 *CONST))
MOCKPROC   OBJ(EXPRICE) PROC(EX_DISCOUNT) RTNTYPE(*PACKED 7 2) +
             PARMS((*PACKED 7 2 *CONST) (*CHAR 10 *CONST))
MOCKPROC   OBJ(EXPRICE) PROC(EX_LOG) PARMS((*CHAR 50 *CONST))
MOCKBUILD  OBJ(EXPRICE)

/* 3. Compile and run the tests, binding through *LIBL */
CRTRPGMOD  MODULE(QTEMP/&EX) SRCFILE(&SRCLIB/QRPGLESRC) SRCMBR(&EX)
CRTPGM     PGM(&LIB/&EX) MODULE(QTEMP/&EX) +
             BNDSRVPGM((*LIBL/EXPRICE) (&LIB/MOCKENG)) ACTGRP(*NEW)
CALL       PGM(&LIB/&EX)
MOCKCHK    PGM(&LIB/EXRETURN)

/* 4. Remove the mocks */
MOCKRMV
```

What to notice:
- **Library list:** the current library is searched before QTEMP, so the
  driver moves the library behind QTEMP first.
- **Mocks come first.** They exist before any test program is compiled or
  activated.
- **`MOCKSRVPGM SRCFILE/SRCMBR` needs no real object.** It builds a service
  program mock from binder source, for a service program that doesn't exist
  yet.
- **Bind through `*LIBL`.** Test programs bind `*LIBL/EXPRICE`, so they
  activate the QTEMP mock. They also bind `MOCKENG` for the `MOCK_H`
  procedures.
- **`MOCKCHK` finds problems early,** confirming nothing bypasses the mocks.

---

## The end-to-end demo

The feature examples call mocks directly. The demo shows the real-world shape:
a service program under test (`DEMOCUT`) calls a program (`DEMODEP`) and a
service program (`DEMOSRV`). The tests (`DEMOCUT_T`) replace both dependencies
with mocks and test `DEMOCUT` itself.

| Member | Role |
|---|---|
| [`DEMOCUT`](../examples/QRPGLESRC/DEMOCUT.rpgle) | Code under test: order total = amount + tax |
| [`DEMODEP`](../examples/QRPGLESRC/DEMODEP.rpgle) | Real customer lookup program, mocked in the tests |
| [`DEMOSRV`](../examples/QRPGLESRC/DEMOSRV.rpgle) | Real tax service program, mocked strict in the tests |
| [`DEMOCUT_T`](../examples/QRPGLESRC/DEMOCUT_T.rpgle) | Tests for `DEMOCUT` |
| [`MOCKDEMO`](../examples/QCLLESRC/MOCKDEMO.clle) | Driver: builds the real objects, creates the mocks, runs the tests, checks library list and binding problems, cleans up |

Run it with `CALL IBMIMOCK/MOCKDEMO PARM('IBMIMOCK')`. The
[Programmer's Guide](PROGRAMMERS_GUIDE.md#4-your-first-mocked-test) walks
through the same scenario step by step.

## Writing your own test

1. **Driver:** copy `EXAMPLES`. Replace its `MOCKPGM`/`MOCKSRVPGM` commands with
   your real dependencies, and its compile steps with your code under test and
   test programs.
2. **Test program:** copy the example closest to what you need. Replace the
   `EXAMPLE_H` prototypes with your own code's prototypes, and `expect()` with
   your test framework's assertions (for example RPGUnit's `assert`).
3. **Keep the order:** reset → stub → call → assert → verify.
