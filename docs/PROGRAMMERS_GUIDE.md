# IBMIMOCK Programmer's Guide

IBMIMOCK gives your CL test driver commands that put stand-in objects in QTEMP. The code under test calls those stand-ins instead of the real programs. Your tests then decide what they answer and check how they were called.

| | |
|---|---|
| Commands and engine | `MOCK*` commands, service program `MOCKENG` |
| Copybook for RPG tests | `MOCK_H` |
| Requires | IBM i 7.4 or later |
| Examples | [One short example per feature](EXAMPLES.md) |
| Project | [IBMiMock on GitHub](../README.md) |

## Contents

1. [The big picture](#1-the-big-picture)
2. [Installing IBMIMOCK](#2-installing-ibmimock)
3. [Four rules](#3-four-rules)
4. [Your first mocked test](#4-your-first-mocked-test)
5. [Describing parameters](#5-describing-parameters)
6. [Stubbing recipes](#6-stubbing-recipes)
7. [Verifying calls](#7-verifying-calls)
8. [Writing tests in RPG](#8-writing-tests-in-rpg)
9. [Test isolation](#9-test-isolation)
10. [Troubleshooting](#10-troubleshooting)
11. [Quick reference](#11-quick-reference)

---

## 1. The big picture

A unit test should exercise one piece of code. When `ORDERSRV` calls the customer lookup program `CUSTLKUP` and the tax service program `TAXSRV`, a real test run needs real customers and real tax tables. With mocks, you replace both dependencies with objects you control:

- **Mock:** a stand-in object with the same name as the real one, created in `QTEMP`.
- **Stub:** a rule for what the mock does when it's called, such as returning `6.00`, filling an output parameter, or throwing an escape message.
- **Verification:** a check, after the code runs, that the mock was called the expected number of times with the expected arguments.

Everything happens in **one job**, driven by a CL program:

| Step | What | Commands |
|---|---|---|
| 1 | Set the library list | `CHGCURLIB *CRTDFT`, `ADDLIBLE MYLIB *LAST` |
| 2 | Create mocks | `MOCKPGM`; `MOCKSRVPGM` + `MOCKPROC` + `MOCKBUILD` |
| 3 | Compile code and tests | `CRTSRVPGM … BNDSRVPGM((*LIBL/TAXSRV))`, `RUCRTRPG` |
| 4 | Run tests | `RUCALLTST` (tests use `MOCKWHEN` / `MOCKVERIFY`) |
| 5 | Clean up | `MOCKRMV` |

The order matters: mocks must exist before anything that uses them is activated.

### Why the mocks get called instead of the real objects

| Dependency | When IBM i finds it | What the mock needs |
|---|---|---|
| `*PGM`, called with `CALLP` + `EXTPGM` or CL `CALL` | At the first call, by searching the library list | QTEMP searched before the library that holds the real program |
| `*SRVPGM` procedure | When the calling program is activated, from the library saved at bind time | The caller bound through `*LIBL`. IBMIMOCK copies the real signatures, so activation accepts the mock. |

Stubs are stored as rows in QTEMP tables, not compiled into the mock. You create a mock *once* per driver, and each test can change what it answers without recompiling.

### What happens on each call

Every stub hands the call to `MOCK_INVOKE` in service program `MOCKENG`:

1. The arguments are recorded in `QTEMP/MOCK_CALL` and `QTEMP/MOCK_CARG`, as they arrived.
2. The newest `MOCKWHEN` whose argument matchers accept the call, and that still has uses left, is chosen.
3. Its answer is applied: `SETPARM` writes output parameters, `RETURN` sets the return value, and `THROW` sends an escape message to the caller. With no matching stub, a loose mock does nothing and a strict mock throws.

---

## 2. Installing IBMIMOCK

IBMIMOCK needs IBM i 7.4 or later; it was built and tested on 7.5. It doesn't need RPGUnit, but works well with it.

### Build from the repository

1. Put the repository in the IFS, for example with git in PASE:
   ```
   git clone https://github.com/danlong005/IBMiMock.git /home/ME/IBMiMock
   ```
   Or download it and copy the `QRPGLESRC`, `QCLLESRC`, `QCMDSRC` and `QSRVSRC` folders to the IFS.
2. Compile the build program straight from the IFS:
   ```
   CRTBNDCL PGM(QTEMP/BUILD) SRCSTMF('/home/ME/IBMiMock/QCLLESRC/BUILD.clle')
   ```
3. Run it, naming the library to build into and the repository directory:
   ```
   CALL QTEMP/BUILD PARM('IBMIMOCK' '/home/ME/IBMiMock')
   CALL QTEMP/BUILD PARM('IBMIMOCK' '/home/ME/IBMiMock' '*YES')
   ```

`BUILD` does the following:

1. Creates the library if it doesn't exist, plus the source files `QRPGLESRC`, `QCLLESRC`, `QCMDSRC` and `QSRVSRC`.
2. Copies every file into a member of the same name, using the extension as the source type (`MOCKENG.sqlrpgle` becomes member `MOCKENG`, type `SQLRPGLE`). The copy is logged to `build.log` in the repository directory.
3. Compiles and runs `MOCKINST`, which builds everything.
4. With `'*YES'` as the third parameter, also runs the self-tests.

- **Long paths:** a quoted `CALL` parameter is only reliable up to 32 characters. For a longer path, run `CHGCURDIR DIR('/the/long/path/IBMiMock')` and pass `'*CURDIR'`, which is also the default.
- **Library creation:** `BUILD` creates the library only if you're authorized to `CRTLIB`. Otherwise, build into an existing library.

### What gets built

| Object | Purpose |
|---|---|
| `MOCKPGM` … `MOCKCHK` `*CMD` | The commands |
| `MCK*C` `*PGM` | Their CL command processing programs |
| `MOCKENG` `*SRVPGM` (activation group `IBMIMOCK`) | Engine: stub runtime, matchers, verification, source generation |
| `MOCKMSGF` `*MSGF` | `MCKnnnn` messages |

To use IBMIMOCK, a test driver needs the library in its library list (anywhere; it holds nothing that gets mocked), and test programs bind service program `MOCKENG`. Copy `MOCK_H` from its `QRPGLESRC` into your tests.

### Rebuild after changing the source

If you edit members in the library (with RDi or SEU, for example), rebuild with:

```
CALL IBMIMOCK/MOCKINST PARM('IBMIMOCK')
```

An optional second parameter names a different library holding the four source files.

### Self-tests

| Driver | Tests | What it covers |
|---|---|---|
| `MOCKTEST` | `MOCKENG_T` | Value conversion for every type, rejected values, decimal data errors, matchers |
| `EXAMPLES` (from `examples/`) | `EXPGM` … `EXFAILMSG`, `EXCL` | One small example per feature; see [Examples](EXAMPLES.md) |
| `MOCKDEMO` (from `examples/`) | `DEMOCUT_T` with `DEMOCUT`, `DEMODEP`, `DEMOSRV` | End to end: hidden-mock detection, program and strict service program mocks, stubs, throws, consecutive returns, argument capture, verification messages, the CL-only commands, bad-binding detection, cleanup |

Run them with `BUILD` and `'*YES'`, which also copies the example source from the repository's `examples` folder into the library. After a build, you can also run them with `CALL IBMIMOCK/MOCKTEST PARM('IBMIMOCK')`, `CALL IBMIMOCK/MOCKDEMO PARM('IBMIMOCK')` and `CALL IBMIMOCK/EXAMPLES PARM('IBMIMOCK')`. Each sends a diagnostic message per test to the job log and ends with a completion message, or with an escape message giving the number of failures. `MOCKDEMO` and `EXAMPLES` change the current library and library list of the job that runs them.

---

## 3. Four rules

Almost every "the real program ran anyway" problem breaks one of these rules. IBMIMOCK checks the first two for you.

### Rule 1: QTEMP must come first

The system portion, product libraries and **the current library** are searched *before* QTEMP. Build scripts and job descriptions often make the development library `*CURLIB`. In a test driver, move it below QTEMP first. Otherwise `MOCKPGM` and `MOCKBUILD` stop with **MCK0010**.

```
CHGCURLIB  CURLIB(*CRTDFT)
ADDLIBLE   LIB(MYLIB) POSITION(*LAST)
```

### Rule 2: Bind service programs through `*LIBL`

Code under test bound with `BNDSRVPGM((MYLIB/TAXSRV))` always activates `MYLIB/TAXSRV`. Use `BNDSRVPGM((*LIBL/TAXSRV))`, or a binding directory entry whose library is `*LIBL`. `MOCKCHK PGM(MYLIB/ORDERSRV)` reports bad bindings as **MCK0021**.

### Rule 3: Create mocks before activation

A program that has already activated the real `TAXSRV` keeps using it until its activation group ends. Create every mock before the first call into the code under test. RPGUnit test programs usually run in `*NEW`, so each `RUCALLTST` starts clean.

### Rule 4: One job

QTEMP belongs to a job. Creating mocks in one SSH session and running tests in another won't work. Put the mocks, compiles and test runs in a single CL driver, and run that driver.

---

## 4. Your first mocked test

The walkthrough uses a small order-pricing service. The same scenario ships as a runnable example in the repository's `examples` folder: `DEMOCUT`, `DEMODEP`, `DEMOSRV` and `DEMOCUT_T` in `examples/QRPGLESRC`, driver `MOCKDEMO` in `examples/QCLLESRC`. `BUILD` with `'*YES'` copies it into the library, and then `CALL IBMIMOCK/MOCKDEMO` shows it passing.

### Step 1: Read the code under test

`ORDERSRV` looks the customer up with a program call, then adds tax from a bound procedure. Note each dependency's parameter list; you'll describe those next.

```rpgle
dcl-pr custLkup extpgm('CUSTLKUP');
  custId   char(10) const;
  custName char(50);
  found    ind;
end-pr;

dcl-pr calcTax packed(11:2) extproc('CALCTAX');
  amount packed(11:2) const;
  state  char(2) const;
end-pr;

dcl-proc order_total export;
  dcl-pi *n packed(11:2);
    custId char(10) const; amount packed(11:2) const;
    state char(2) const;   custName char(50);
  end-pi;
  dcl-s found ind inz(*off);

  monitor;
    custLkup(custId : custName : found);
  on-error;
    return -2;                 // lookup failed
  endmon;
  if not found;
    return -1;                 // unknown customer
  endif;
  return amount + calcTax(amount : state);
end-proc;
```

### Step 2: Write the driver and create the mocks

`MOCKPGM` needs the program's parameter layout. `MOCKSRVPGM` reads the real service program's exports and signatures. `MOCKPROC` describes each procedure whose arguments or return value you care about, and `MOCKBUILD` creates the object.

```
             PGM
             CHGJOB     INQMSGRPY(*DFT)
             CHGCURLIB  CURLIB(*CRTDFT)
             ADDLIBLE   LIB(MYLIB) POSITION(*LAST)
             ADDLIBLE   LIB(RPGUNIT) POSITION(*LAST)

/* Mocks: before anything is compiled against or activated */
             MOCKPGM    OBJ(CUSTLKUP) +
                          PARMS((*CHAR 10) (*CHAR 50) (*IND))
             MOCKSRVPGM OBJ(TAXSRV) BEHAVIOR(*STRICT)
             MOCKPROC   OBJ(TAXSRV) PROC(CALCTAX) +
                          RTNTYPE(*PACKED 11 2) +
                          PARMS((*PACKED 11 2 *CONST) (*CHAR 2 *CONST))
             MOCKBUILD  OBJ(TAXSRV)
```

### Step 3: Compile the code under test and the tests

Bind the service program through `*LIBL`, check with `MOCKCHK`, and bind the test program to `MOCKENG` so it can use `MOCK_H`.

```
             CRTRPGMOD  MODULE(QTEMP/ORDERSRV) SRCFILE(MYLIB/QRPGLESRC)
             CRTSRVPGM  SRVPGM(MYLIB/ORDERSRV) MODULE(QTEMP/ORDERSRV) +
                          EXPORT(*ALL) BNDSRVPGM((*LIBL/TAXSRV))
             MOCKCHK    PGM(MYLIB/ORDERSRV)

             RUCRTRPG   TSTPGM(MYLIB/ORDERSRV_T) SRCFILE(MYLIB/QRPGLESRC) +
                          BNDSRVPGM(MYLIB/ORDERSRV MYLIB/MOCKENG)
             RUCALLTST  TSTPGM(MYLIB/ORDERSRV_T)

             MOCKRMV
             ENDPGM
```

### Step 4: Write a test (stub, act, assert, verify)

Each test resets the mocks, says what they should answer, calls the code, then checks the result and the calls.

```rpgle
**free
ctl-opt nomain;
/include RPGUNIT/RPGUNIT1,TESTCASE
/copy MYLIB/QRPGLESRC,MOCK_H
/copy MYLIB/QRPGLESRC,ORDERSRV_H

dcl-proc SETUP export;
  mock('MOCKRESET');                 // no stubs or calls left from earlier tests
end-proc;

dcl-proc test_total_adds_tax_for_known_customer export;
  dcl-s name char(50);

  // arrange
  mock('MOCKWHEN OBJ(CUSTLKUP) ARGS((1 *EQ C001)) +
        SETPARM((2 ''ACME CORP'') (3 ''1''))');
  mock('MOCKWHEN OBJ(TAXSRV) PROC(CALCTAX) RETURN(''6.00'')');

  // act + assert
  aEqual('106.00' : %char(order_total('C001' : 100 : 'PA' : name)));
  aEqual('ACME CORP' : name);

  // verify
  assert(mock_ok('MOCKVERIFY OBJ(TAXSRV) PROC(CALCTAX) +
                  ARGS((1 *EQ 100) (2 *EQ PA)) TIMES(*ONCE)')
         : mock_lastError());
end-proc;
```

### Step 5: Run the driver and read the result

Compile and call the driver in one job, for example `CALL MYLIB/ORDERDRV` from a 5250 session or with `SBMJOB CMD(CALL MYLIB/ORDERDRV)`. When a verification fails, `assert` reports IBMIMOCK's explanation:

```
Verification failed: expected TAXSRV.CALCTAX to be called exactly 1 time(s)
with (1 *EQ '100', 2 *EQ 'PA') but it matched 0 time(s).
Recorded calls: #7('100.00', 'NJ')
```

---

## 5. Describing parameters

IBMIMOCK doesn't read prototypes. You describe each parameter as `(type length decimals)`, plus a passing style for service program procedures. Copy the layout straight from the prototype:

| RPG declaration | `MOCKPGM PARMS` / `RTNTYPE` | `MOCKPROC PARMS` |
|---|---|---|
| `char(10)` | `(*CHAR 10)` | `(*CHAR 10)` |
| `char(10) const` | `(*CHAR 10)` | `(*CHAR 10 *CONST)` |
| `varchar(50)` | `(*VARCHAR 50)` | `(*VARCHAR 50)` |
| `packed(11:2) const` | `(*PACKED 11 2)` | `(*PACKED 11 2 *CONST)` |
| `zoned(7:0)` | `(*ZONED 7 0)` | `(*ZONED 7 0)` |
| `int(10) value` | n/a (programs pass by reference) | `(*INT 10 0 *VALUE)` |
| `uns(5)` / `float(8)` | `(*UNS 5)` / `(*FLOAT 8)` | same |
| `ind` | `(*IND)` | `(*IND)` |
| `date` / `time` / `timestamp` (*ISO) | `(*DATE)` `(*TIME)` `(*TIMESTAMP)` | same |
| `pointer` | `(*PTR)` | `(*PTR)` |
| `likeds(cust_t)` (all-character subfields) | `(*CHAR 120)` using `%size(cust_t)` | same |

### Things to know

- **The passing style can go in the decimals slot.** `(*CHAR 2 *CONST)` and `(*PACKED 11 2 *CONST)` both work. The full form is `(*CHAR 2 0 *CONST)`.
- **You only need to declare what you use.** A program mock records extra parameters as `*UNDECLARED`. You can still use `*ANY`, `*OMIT` and `*NOTPASSED` matchers on them, but not value matchers or `SETPARM`.
- **Declare every export whose return value matters.** A service program export without `MOCKPROC` gets a stub with no parameters and no return value. It records calls and can throw, but a caller that reads its return value gets unpredictable data.
- **Data structures:** describe a DS parameter as one `*CHAR` of its size. Matching and `SETPARM` then work on the whole record as text, which only makes sense when the subfields are character.
- **Export names:** `PROC` is matched exactly first, then case-insensitively. RPG exports are uppercase unless the prototype uses `EXTPROC(*DCLCASE)` or a quoted name.
- **Changed an interface?** Run `MOCKPROC` again, then `MOCKBUILD`. Stubs alone never need a rebuild.
- **No real service program on the system?** By default `MOCKSRVPGM` reads exports and signatures from the real object (`SRCFILE(*RTV)`). Pass its binder source instead with `SRCFILE(lib/QSRVSRC) SRCMBR(name)`; every `*PRV` block is kept.

---

## 6. Stubbing recipes

Every recipe is a `MOCKWHEN` command. From RPG, wrap it in `mock('…')` and double the quotes. From CL, write it as shown.

Values are checked against the declared layout when `MOCKWHEN` runs, so a mistake such as `RETURN('12345678901.99')` for `*PACKED 11 2` fails right away with **MCK0014** instead of at call time.

### Return a value

Service program procedures with a declared `RTNTYPE`:

```
MOCKWHEN OBJ(TAXSRV) PROC(CALCTAX) RETURN('6.00')
```

### Fill output parameters

This is how program mocks "answer": they write into the caller's variables.

```
MOCKWHEN OBJ(CUSTLKUP) SETPARM((2 'ACME CORP') (3 '1'))
```

Values are text, converted to the declared type: `'12.50'` for packed, `'1'`/`'0'` or `'*ON'`/`'*OFF'` for indicators, `'2026-09-13'` for dates. Parameters passed `*VALUE` or `*OMIT` can't be set.

### Answer only for certain arguments

```
MOCKWHEN OBJ(TAXSRV) PROC(CALCTAX) ARGS((2 *EQ NY)) RETURN('8.88')
MOCKWHEN OBJ(TAXSRV) PROC(CALCTAX) ARGS((1 *GT 1000)) RETURN('99.00')
MOCKWHEN OBJ(CUSTLKUP) ARGS((1 *LIKE 'C_9%')) SETPARM((3 '1'))
```

The matchers are `*EQ` (default), `*NE`, `*GT`, `*GE`, `*LT`, `*LE`, `*LIKE` (`%` any text, `_` one character), `*BLANK` (blanks, or zero for numbers), `*ANY`, `*OMIT` and `*NOTPASSED`. Numeric parameters compare as numbers, so `100` matches `100.00`. Character comparisons ignore trailing blanks. All matchers in one `ARGS` must match.

### A default answer plus special cases

The newest matching stub wins.

```
MOCKWHEN OBJ(TAXSRV) PROC(CALCTAX) RETURN('5.00')                  /* default  */
MOCKWHEN OBJ(TAXSRV) PROC(CALCTAX) ARGS((2 *EQ NY)) RETURN('8.88') /* override */
```

IBMIMOCK checks stubs from newest to oldest and uses the first one that matches and has uses left. Define broad stubs first (for example in `SETUP`) and narrow ones in the test.

### Different answers on successive calls

```
MOCKWHEN OBJ(TAXSRV) PROC(CALCTAX) RETURN('1.00' '2.00')
/* calls return 1.00, 2.00, 2.00, 2.00 ... */
```

The last value repeats. Use this for retry loops and paging. You can list up to 32 values.

### Answer only a limited number of times

```
MOCKWHEN OBJ(CUSTLKUP) SETPARM((3 '1')) TIMES(1)
/* first call: found; later calls fall through to older stubs or the default behavior */
```

### Simulate a failure

`THROW` sends an escape message to the caller.

```
MOCKWHEN OBJ(CUSTLKUP) THROW(CPF9898 QCPFMSG *LIBL 'Customer DB down')
MOCKWHEN OBJ(TAXSRV) PROC(CALCTAX) THROW(*MOCK *MOCK *LIBL 'rate table locked')
```

The code under test sees an ordinary escape message, so `MONITOR` and `MONMSG` behave exactly as in production. `THROW` takes **one** set of parentheses. `*MOCK` sends **MCK0101**.

### Fail on any call you didn't expect

Use `BEHAVIOR(*STRICT)` on `MOCKPGM` or `MOCKSRVPGM`.

A `*LOOSE` mock (the default) answers an unmatched call by leaving parameters untouched and returning zero or blanks. A `*STRICT` mock sends **MCK0100** `Unexpected call to TAXSRV.CALCTAX('100.00', 'TX')`, which fails the test at the call that shouldn't have happened.

---

## 7. Verifying calls

Every call to a mock is recorded with a snapshot of its arguments as they arrived. Verification checks that record.

```
MOCKVERIFY OBJ(TAXSRV) PROC(CALCTAX) TIMES(*ONCE)
MOCKVERIFY OBJ(TAXSRV) PROC(CALCTAX) TIMES(*NEVER)
MOCKVERIFY OBJ(TAXSRV) PROC(CALCTAX) ARGS((2 *EQ PA)) TIMES(*EXACTLY 3)
MOCKVERIFY OBJ(CUSTLKUP) ARGS((1 *LIKE 'C%')) TIMES(*ATLEAST 1)
MOCKVERIFY OBJ(CUSTLKUP) TIMES(*ATMOST 2)
MOCKNOMORE                    /* every recorded call has been verified */
```

| Command | What it does |
|---|---|
| `MOCKVERIFY` | Sends **MCK0200** when the count of matching calls is wrong. On success, the matching calls are marked verified. |
| `MOCKNOMORE` | Sends **MCK0201** listing any call no successful `MOCKVERIFY` covered. Use it to catch surprise interactions. |
| `MOCKGETARG` | Returns one captured argument to a CL variable (`*CHAR 256`). Use `CALL(*FIRST\|*LAST\|n)`. |
| `MOCKCOUNT` | Returns the number of matching calls to a CL variable (`*DEC 10 0`). |

### Capturing arguments

When a matcher can't express the check, for example a computed value, capture the argument and assert on it.

From an RPG test:

```rpgle
aEqual('25.50' : mock_arg('TAXSRV' : 'CALCTAX' : MOCK_LAST : 1));
iEqual(2 : mock_count('CUSTLKUP' : MOCK_PGM));
```

From a CL driver:

```
             DCL        VAR(&ARG) TYPE(*CHAR) LEN(256)
             DCL        VAR(&CNT) TYPE(*DEC) LEN(10 0)
             MOCKGETARG OBJ(CUSTLKUP) PARM(1) CALL(*LAST) RTNVAL(&ARG)
             MOCKCOUNT  OBJ(CUSTLKUP) RTNVAL(&CNT)
             MOCKVERIFY OBJ(CUSTLKUP) TIMES(*NEVER)
             MONMSG     MSGID(MCK0200) EXEC(GOTO FAILED)
```

Captured values are text: numbers are normalized (`25.50`, `-1`), trailing blanks are removed, and missing arguments come back as `*OMIT` or `*NOTPASSED`.

---

## 8. Writing tests in RPG

Copy `MOCK_H` into the test module and bind service program `MOCKENG`. For a complete working example, see `examples/QRPGLESRC/DEMOCUT_T.rpgle` (driven by `examples/QCLLESRC/MOCKDEMO.clle`). Every MOCK command runs through one of two wrappers:

| Procedure | On failure | Use it for |
|---|---|---|
| `mock(cmd)` | Sends escape **MCK0300**; RPGUnit reports the test as an error | Setup: `MOCKWHEN`, `MOCKRESET` |
| `mock_ok(cmd)` | Returns `*off` | Assertions: `assert(mock_ok('MOCKVERIFY …') : mock_lastError())` |
| `mock_lastError()` | n/a | The message behind the last failure, including strict-mode calls |
| `mock_arg(obj : proc : call : parm)` | Returns `*ERROR …` | Argument capture (`MOCK_LAST` for the last call) |
| `mock_count(obj : proc)` | Returns `-1` | Call counts (`MOCK_PGM` as the procedure for program mocks) |

### Quoting inside RPG strings

- Command values that contain blanks or lowercase letters need CL quotes, and inside an RPG literal each one is doubled: `SETPARM((2 ''ACME CORP''))`.
- Split long commands with `+` at the end of the line. Leading blanks on the next line are skipped, so leave the space before the `+`.
- Lists of entries use two sets of parentheses: `ARGS((1 *EQ C001) (2 *ANY))`. Single groups use one: `THROW(CPF9898 QCPFMSG *LIBL ''text'')`. If `mock_lastError()` starts with `CPF0006` (errors in command), check the quotes and parentheses; running the same command from a command line shows the exact problem.

> **Tip: stub from CL or from RPG.** The commands work the same in both. Creating mocks belongs in CL (it compiles objects). Stubbing and verification usually belong in the test procedure, next to the assertion they support.

---

## 9. Test isolation

| Command | Clears | Keeps | When |
|---|---|---|---|
| `MOCKRESET` | Stubs and recorded calls for all mocks | Mock objects and layouts | In `SETUP`, before every test |
| `MOCKRESET SCOPE(*CALLS)` | Recorded calls | Stubs | Between the arrange and act phases of a long test |
| `MOCKRESET OBJ(TAXSRV) SCOPE(*STUBS)` | One mock's stubs | Everything else | Switching one dependency's behavior |
| `MOCKRMV OBJ(TAXSRV)` | The mock object and its state | Other mocks | The real object is needed again in this job |
| `MOCKRMV` | All mocks, QTEMP tables and generated source | n/a | At the end of the driver |

- Remove mocks *after* the test program has ended. A program still active in the job keeps whatever it activated.
- Rerunning `MOCKPGM` or `MOCKSRVPGM` for an existing name replaces the mock and forgets its stubs and calls.
- If the driver ends without `MOCKRMV`, nothing is left behind: QTEMP is discarded with the job.

---

## 10. Troubleshooting

### Symptoms

| What you see | Likely cause | Fix |
|---|---|---|
| The real program or service program runs | Its library is `*CURLIB` or a product library; a hard-coded binding; or it was activated before the mock existed | Run `MOCKCHK PGM(lib/caller)`, then follow rules 1–3 |
| Stubbed values never show up | The matcher doesn't match what was actually passed | Inspect with `mock_arg`, or read the recorded calls in the `MOCKVERIFY` message |
| Return value is always zero or blank | No stub matched a `*LOOSE` mock, or the export has no `MOCKPROC` | Declare `RTNTYPE`; use `*STRICT` to catch unmatched calls |
| Signature violation when activating the code under test | It was bound against a signature the real service program no longer exports | Rebind the code under test; the mock copies the real object's current signatures |
| `mock()` fails with CPF0006 | Command syntax: quotes or parentheses | See [Quoting inside RPG strings](#quoting-inside-rpg-strings) |
| Job waits on an inquiry message | An unmonitored error in a driver run over SSH | Start drivers with `CHGJOB INQMSGRPY(*DFT)` and a program-level `MONMSG` |

### Messages

| ID | Meaning |
|---|---|
| MCK0010 | The mock is hidden by an object earlier in the library list |
| MCK0011 | No mock with that name exists in this job |
| MCK0012 | Unknown export, a `PROC` given for a program mock, or a data export used as a procedure |
| MCK0013 | The real service program or its binder source couldn't be found |
| MCK0014 | Invalid layout or value, such as an overflow, a bad indicator, or an undeclared parameter |
| MCK0015 | The stub didn't build. The listing is spooled; the source is in `QTEMP/MOCKSRC` |
| MCK0020 / MCK0021 | `MOCKCHK` finding / summary |
| MCK0100 | A strict mock received a call no stub matched |
| MCK0101 | Sent by `THROW(*MOCK …)` |
| MCK0200 / MCK0201 | Verification failed / unverified interactions |
| MCK0202 | `MOCKGETARG`: no call with that number |
| MCK0300 | A command run through `mock()` failed; the text explains why |

### Looking inside

A mock's state is kept in ordinary QTEMP tables, which you can query from the driver's job (for example with STRSQL in an interactive session that ran the commands):

```sql
select * from qtemp.mock_call order by callid;       -- every recorded call
select * from qtemp.mock_carg where callid = 7;     -- its arguments
select * from qtemp.mock_stub;                         -- active stubs
select * from qtemp.mock_sig;                          -- declared layouts
```

---

## 11. Quick reference

The mock is identified by `OBJ(name)`. Service program mocks also take `PROC(exportName)`; for program mocks, omit `PROC`.

| Command | Key parameters | Mockito / Moq equivalent |
|---|---|---|
| `MOCKPGM` | `OBJ` · `PARMS((type len dec) …)` · `BEHAVIOR(*LOOSE\|*STRICT)` | `mock(X.class)` / `new Mock<X>(behavior)` |
| `MOCKSRVPGM` | `OBJ` · `BEHAVIOR` · `SRCFILE(*RTV\|lib/file)` · `SRCMBR(*OBJ\|name)` | `mock(X.class)` |
| `MOCKPROC` | `OBJ` · `PROC` · `RTNTYPE(type len dec)` · `PARMS((type len dec\|passing [passing]) …)` | – |
| `MOCKBUILD` | `OBJ` | – |
| `MOCKWHEN` | `OBJ` · `PROC(*PGM\|name)` · `ARGS((n matcher value) …)` · `RETURN(v …)` · `SETPARM((n value) …)` · `THROW(msgid msgf lib data)` · `TIMES(*ALWAYS\|n)` | `when().thenReturn()/thenThrow()` / `Setup().Returns()/Callback()/Throws()` |
| `MOCKVERIFY` | `OBJ` · `PROC` · `ARGS` · `TIMES(*ONCE\|*NEVER\|*EXACTLY n\|*ATLEAST n\|*ATMOST n)` | `verify(m, times(n))` / `Verify(Times)` |
| `MOCKNOMORE` | `OBJ(*ALL\|name)` | `verifyNoMoreInteractions()` / `VerifyNoOtherCalls()` |
| `MOCKGETARG` | `OBJ` · `PARM(n)` · `RTNVAL(&char256)` · `PROC` · `CALL(*LAST\|*FIRST\|n)` · CL programs only | `ArgumentCaptor` |
| `MOCKCOUNT` | `OBJ` · `RTNVAL(&dec10)` · `PROC` · `ARGS` · CL programs only | – |
| `MOCKRESET` | `OBJ(*ALL\|name)` · `SCOPE(*ALL\|*CALLS\|*STUBS)` | `reset()` / `clearInvocations()` |
| `MOCKRMV` | `OBJ(*ALL\|name)` | – |
| `MOCKCHK` | `PGM(*NONE\|lib/name)` | – |

### Limits

- Up to 64 parameters per program or procedure, 64 `ARGS`/`SETPARM` entries and 32 `RETURN` values. Command values are at most 256 characters.
- Captured argument text is cut at 1,024 characters. Dates and times use ISO format.
- `*VARCHAR` can't be passed `*VALUE`. A data export is mocked as `char(n)` storage of the real size.
- Each stub call runs a few SQL statements against QTEMP. That's fast enough for unit tests, but mocks aren't meant for performance runs.

---

IBMIMOCK is developed in the [IBMiMock repository](../README.md). See [Installing IBMIMOCK](#2-installing-ibmimock) to build it and run its self-tests.
