# RPGMOCK: mocking commands for RPG unit tests

RPGMOCK lets a CL test driver replace the programs and service programs that
your code calls with **mocks in QTEMP**. Tests control what the mocks return,
check how they were called, and remove them afterwards. The design borrows
from Mockito and Moq.

```
MOCKPGM    OBJ(CUSTLKUP) PARMS((*CHAR 10) (*CHAR 50) (*IND))
MOCKWHEN   OBJ(CUSTLKUP) ARGS((1 *EQ C001)) SETPARM((2 'ACME') (3 '1'))
   ... run the code under test ...
MOCKVERIFY OBJ(CUSTLKUP) ARGS((1 *EQ C001)) TIMES(*ONCE)
MOCKRMV
```

- Every command you run is a CL `*CMD` with a CL command processing program.
- The engine, service program `MOCKENG`, is ILE RPG. It keeps state in QTEMP
  SQL tables and generates the stub source.
- New to RPGMOCK? Start with the [Programmer's Guide](docs/PROGRAMMERS_GUIDE.md).
- Stubbing is stored as data. Changing what a mock answers never requires a
  recompile, so you build mocks once per driver and restub them in every test.

## How it works

| Dependency | When IBM i resolves it | What RPGMOCK does |
|---|---|---|
| `*PGM` (`CALLP` with `EXTPGM`, CL `CALL`) | At call time, through the library list | Compiles a generic stub program named after the real program into QTEMP. The stub accepts up to 64 parameters. |
| `*SRVPGM` bound procedure | When the caller is activated. The binder saved the library you bound with. | Retrieves the real export list and **signatures** (`RTVBNDSRC`) and generates a stub service program with the same name, exports, and signatures in QTEMP. |

Each stub call is handled by `MOCK_INVOKE` in `MOCKENG`:
1. It records the arguments in `QTEMP/MOCK_CALL` and `QTEMP/MOCK_CARG`.
2. It picks the newest `MOCKWHEN` whose argument matchers accept the call and
   that still has uses left.
3. That stub's answer is applied: `SETPARM` writes output parameters, `RETURN`
   sets the return value, and `THROW` sends an escape message to the caller.

### Rules the framework enforces

1. **QTEMP must come before the real object in the library list.** The current
   library (`*CURLIB`) and product libraries are searched **before** QTEMP.
   The repo scripts make the target library `*CURLIB`. `MOCKPGM` and
   `MOCKBUILD` fail with **MCK0010** when the mock is hidden. The fix in a
   driver:
   ```
   CHGCURLIB  CURLIB(*CRTDFT)
   ADDLIBLE   LIB(MYLIB) POSITION(*LAST)
   ```
2. **Bind service programs through `*LIBL`**, for example
   `BNDSRVPGM((*LIBL/TAXSRV))` or a binding directory entry with `*LIBL`. A
   caller bound to `MYLIB/TAXSRV` ignores the mock. `MOCKCHK PGM(MYLIB/CALLER)`
   reports this (MCK0021).
3. **Create mocks before the code under test is activated.** A program that
   already activated the real service program keeps it until its activation
   group ends. The same applies in reverse after `MOCKRMV`.
4. **QTEMP belongs to one job.** Mocks, compiles, and test runs must happen in
   the same job, so run them from one CL driver. Each SSH session or submitted
   job is a new job.

## Install

RPGMOCK is laid out like an IBM i library. Each folder in this repository is a
source physical file:

| Folder / source file | Members |
|---|---|
| `QRPGLESRC` | `MOCKENG`, `MOCKGEN` (SQLRPGLE), `MOCKCDC`, copybooks `MOCKENG_H` and `MOCK_H` |
| `QCLLESRC` | `BUILD`, `MOCKINST`, `MCK*C` command processing programs |
| `QCMDSRC` | The `MOCK*` command definitions |
| `QSRVSRC` | `MOCKENG` binder source |

Test and demo members live in the same folders: `DEMO*`, `*_T`, `MOCKTST_H`,
`MOCKTEST` and `MOCKDEMO`.

### Build from the repository

1. Put the repository in the IFS, for example with git in PASE:
   ```
   git clone https://github.com/danlong005/IBMiMock.git /home/ME/IBMiMock
   ```
   Or download it and copy the folders to the IFS.
2. Compile the build program straight from the IFS:
   ```
   CRTBNDCL PGM(QTEMP/BUILD) SRCSTMF('/home/ME/IBMiMock/QCLLESRC/BUILD.clle')
   ```
3. Run it, naming the library to build into and the repository directory:
   ```
   CALL QTEMP/BUILD PARM('RPGMOCK' '/home/ME/IBMiMock')
   CALL QTEMP/BUILD PARM('RPGMOCK' '/home/ME/IBMiMock' '*YES')
   ```
   The third parameter `*YES` also runs the self-tests.

`BUILD` does the following:
1. Creates the library if it doesn't exist, plus the four source files.
2. Copies every file into a member of the same name, using the extension as the
   source type (for example `MOCKENG.sqlrpgle` becomes `MOCKENG`, type
   `SQLRPGLE`). The copy is logged to `build.log` in the repository directory.
3. Compiles and runs `MOCKINST`.

- A quoted `CALL` parameter is only reliable up to 32 characters. For a longer
  path, run `CHGCURDIR DIR('/the/long/path/IBMiMock')` and pass `'*CURDIR'`,
  which is also the default.
- The self-tests change the current library and library list of the job that
  runs them.

### Rebuild from source members

If the members are already in the source files (after editing them with SEU or
RDi, for example), rebuild with `CALL RPGMOCK/MOCKINST PARM('RPGMOCK')`. An
optional second parameter names a different library holding the source files.

The build creates:

| Object | Purpose |
|---|---|
| `MOCKPGM` … `MOCKCHK` `*CMD` + `MCK*C` `*PGM` | Commands and their CL processing programs |
| `MOCKENG` `*SRVPGM` (ACTGRP `RPGMOCK`) | Engine: codec, matchers, stub runtime, verification, source generation |
| `MOCKMSGF` `*MSGF` | `MCKnnnn` messages |

Requirements: IBM i 7.4 or later. It was built and tested on 7.5. It does not
need RPGUnit; it works with or without it.

## Commands

The mock is identified by `OBJ(name)`. Service program mocks also take
`PROC(exportName)`; for program mocks, omit `PROC`.

| Command | Mockito / Moq equivalent | What it does |
|---|---|---|
| `MOCKPGM OBJ() PARMS((type len dec) …) BEHAVIOR(*LOOSE\|*STRICT)` | `mock(X.class)` / `new Mock<X>(behavior)` | Creates a `*PGM` mock in QTEMP |
| `MOCKSRVPGM OBJ() BEHAVIOR() SRCFILE(*RTV\|lib/file) SRCMBR()` | `mock()` | Starts a `*SRVPGM` mock. Exports and signatures come from `RTVBNDSRC` of the real object, or from your binder source. |
| `MOCKPROC OBJ() PROC() RTNTYPE(type len dec) PARMS((type len dec passing) …)` | – | Declares the interface of one export |
| `MOCKBUILD OBJ()` | – | Generates and creates the `*SRVPGM` mock in QTEMP |
| `MOCKWHEN OBJ() PROC() ARGS() RETURN() SETPARM() THROW() TIMES()` | `when().thenReturn()/thenThrow()`, `Setup().Returns()/Callback()/Throws()` | Adds stubbed behavior |
| `MOCKVERIFY OBJ() PROC() ARGS() TIMES(*ONCE\|*NEVER\|*EXACTLY n\|*ATLEAST n\|*ATMOST n)` | `verify(m, times(n))` / `Verify(Times)` | Sends escape message **MCK0200** if the check fails |
| `MOCKNOMORE OBJ(*ALL\|name)` | `verifyNoMoreInteractions` | Fails (MCK0201) if a recorded call was not verified |
| `MOCKGETARG OBJ() PROC() CALL(*LAST\|*FIRST\|n) PARM(n) RTNVAL(&var)` | `ArgumentCaptor` | Returns a captured argument (CL programs only; `&var` is `*CHAR 256`) |
| `MOCKCOUNT OBJ() PROC() ARGS() RTNVAL(&n)` | – | Returns the number of matching calls (CL programs only; `&n` is `*DEC 10 0`) |
| `MOCKRESET OBJ(*ALL\|name) SCOPE(*ALL\|*CALLS\|*STUBS)` | `reset()` / `clearInvocations()` | Clears stubs and/or recorded calls, keeping the objects |
| `MOCKRMV OBJ(*ALL\|name)` | – | Deletes mock objects and their state from QTEMP |
| `MOCKCHK PGM(*NONE\|lib/pgm)` | – | Reports hidden mocks, unbuilt mocks, and non-`*LIBL` bindings (MCK0021) |

### Layouts

The types are `*CHAR`, `*VARCHAR`, `*PACKED`, `*ZONED`, `*INT`, `*UNS`
(3/5/10/20), `*FLOAT` (4/8), `*IND`, `*DATE`, `*TIME`, `*TIMESTAMP` (ISO
format), and `*PTR` (`*NULL` only).

- Service program parameters also take a passing style: `*REF` (default),
  `*CONST`, or `*VALUE`. You can put it in the decimals slot, so
  `(*CHAR 2 *CONST)` and `(*PACKED 11 2 *CONST)` both work.
- A program mock records parameters beyond `PARMS` as `*UNDECLARED`. To match
  or set a parameter, declare it.
- A service program export without `MOCKPROC` gets a stub with no parameters
  and no return value. It still records calls and honors `*STRICT` and
  `THROW`. Declare every export whose return value the code under test uses.

### Stubbing (`MOCKWHEN`)

- `ARGS((parm matcher value) …)` takes these matchers: `*EQ` (default), `*NE`,
  `*GT`, `*GE`, `*LT`, `*LE`, `*LIKE` (`%` and `_` wildcards), `*BLANK`,
  `*ANY`, `*OMIT` (passed as `*OMIT`), and `*NOTPASSED` (omitted through
  `*NOPASS`). Numeric parameters compare numerically, so `100` matches
  `100.00`.
- `RETURN('1.00' '2.00')` gives consecutive answers; the last one repeats
  (like `thenReturn(a, b)`).
- `SETPARM((2 'ACME') (3 '1'))` writes output parameters.
- `THROW(CPF9898 QCPFMSG *LIBL 'text')` sends an escape message to the caller.
  `THROW(*MOCK)` sends MCK0101.
- `TIMES(n)` answers n calls, after which the stub is skipped. The default is
  `*ALWAYS`.
- **The newest matching stub wins.** Put general stubs in setup and specific
  ones in the test.
- A call that no stub matches works like this:
  - `*LOOSE` leaves parameters untouched and returns zero or blanks.
  - `*STRICT` sends **MCK0100** `Unexpected call to …`.

Values are checked against the declared layout when you run `MOCKWHEN`. For
example, `RETURN('12345678901.99')` for `*PACKED 11 2` is rejected with MCK0014.

## Using it from a CL test driver

```
PGM
  CHGJOB     INQMSGRPY(*DFT)
  CHGCURLIB  CURLIB(*CRTDFT)                 /* keep MYLIB behind QTEMP */
  ADDLIBLE   LIB(MYLIB) POSITION(*LAST)
  ADDLIBLE   LIB(RPGUNIT) POSITION(*LAST)

  /* 1. mocks - before anything is activated */
  MOCKPGM    OBJ(CUSTLKUP) PARMS((*CHAR 10) (*CHAR 50) (*IND))
  MOCKSRVPGM OBJ(TAXSRV) BEHAVIOR(*STRICT)
  MOCKPROC   OBJ(TAXSRV) PROC(CALCTAX) RTNTYPE(*PACKED 11 2) +
               PARMS((*PACKED 11 2 *CONST) (*CHAR 2 *CONST))
  MOCKBUILD  OBJ(TAXSRV)

  /* 2. code under test, bound through *LIBL */
  CRTRPGMOD  MODULE(QTEMP/ORDERSRV) SRCFILE(MYLIB/QRPGLESRC)
  CRTSRVPGM  SRVPGM(MYLIB/ORDERSRV) MODULE(QTEMP/ORDERSRV) +
               EXPORT(*ALL) BNDSRVPGM((*LIBL/TAXSRV))
  MOCKCHK    PGM(MYLIB/ORDERSRV)

  /* 3. tests (bind MOCKENG for the MOCK_H procedures) */
  RUCRTRPG   TSTPGM(MYLIB/ORDERSRV_T) SRCFILE(MYLIB/QRPGLESRC) +
               BNDSRVPGM(MYLIB/ORDERSRV MYLIB/MOCKENG)
  RUCALLTST  TSTPGM(MYLIB/ORDERSRV_T)

  /* 4. clean up */
  MOCKRMV
ENDPGM
```

A failed `MOCKVERIFY` in a driver is an escape message you can monitor:

```
MOCKVERIFY OBJ(CUSTLKUP) ARGS((1 *EQ C001)) TIMES(*ONCE)
MONMSG     MSGID(MCK0200) EXEC(...)
```

The message explains the failure:

```
Verification failed: expected CUSTLKUP to be called exactly 1 time(s) with
(1 *EQ 'C001') but it matched 0 time(s). Recorded calls: #1('C002', '', '')
#2('C003', '', '')
```

## Using it from RPG tests (`MOCK_H`)

Copy `MOCK_H` into the test module and bind `MOCKENG`.

| Procedure | Purpose |
|---|---|
| `mock(cmd)` | Runs a MOCK command. Sends escape MCK0300 on failure (use it for setup). |
| `mock_ok(cmd)` | Runs a MOCK command. Returns `*off` on failure (use it for assertions). |
| `mock_lastError()` | Text of the last failure: a verification message, an unexpected strict call, or a bad parameter |
| `mock_arg(obj : proc : callNo \| MOCK_LAST : parmNo)` | Captured argument as text, or `*OMIT` / `*NOTPASSED` |
| `mock_count(obj : proc)` | Number of recorded calls |

An RPGUnit example (not run on this machine, where RPGUnit is not installed):

```rpgle
**free
ctl-opt nomain;
/include RPGUNIT/RPGUNIT1,TESTCASE
/copy MYLIB/QRPGLESRC,MOCK_H

dcl-proc SETUP export;
  mock('MOCKRESET');
end-proc;

dcl-proc test_orderTotal_addsTax export;
  dcl-s name char(50);
  mock('MOCKWHEN OBJ(CUSTLKUP) ARGS((1 *EQ C001)) +
        SETPARM((2 ''ACME'') (3 ''1''))');
  mock('MOCKWHEN OBJ(TAXSRV) PROC(CALCTAX) RETURN(''6.00'')');

  aEqual('106.00' : %char(order_total('C001' : 100 : 'PA' : name)));
  assert(mock_ok('MOCKVERIFY OBJ(TAXSRV) PROC(CALCTAX) +
                  ARGS((2 *EQ PA)) TIMES(*ONCE)') : mock_lastError());
  aEqual('PA' : mock_arg('TAXSRV' : 'CALCTAX' : MOCK_LAST : 2));
end-proc;
```

`QRPGLESRC/DEMOCUT_T.rpgle` is a complete working example. It uses a small
built-in harness instead of RPGUnit.

## Debugging

- State is kept in plain QTEMP tables, which you can query from the job:
  - `QTEMP.MOCK_OBJ`, `QTEMP.MOCK_PROC`, `QTEMP.MOCK_SIG`: mocks and layouts
  - `QTEMP.MOCK_STUB`, `QTEMP.MOCK_SARG`, `QTEMP.MOCK_SRTN`, `QTEMP.MOCK_SSET`:
    stubs
  - `QTEMP.MOCK_CALL`, `QTEMP.MOCK_CARG`: recorded calls
- Generated stub source is in `QTEMP/MOCKSRC`; binder source is in
  `QTEMP/MOCKBND`.
- If a stub fails to compile, the command recompiles it with `OUTPUT(*PRINT)`
  and sends MCK0015.

## Limits

- Programs: up to 64 parameters. Commands: up to 64 `ARGS` or `SETPARM`
  entries and 32 `RETURN` values, each at most 256 characters. Captured values
  are truncated to 1024 characters.
- `*VARCHAR` cannot be passed `*VALUE`. Dates and times use ISO format.
- Data exports are mocked as `char(n)` storage of the real size.
- Every stub call runs a few SQL statements against QTEMP. That is fine for
  unit tests but not for performance tests.
- `MOCKGETARG` and `MOCKCOUNT` return CL variables, so they only run in CL
  programs. From RPG, use `mock_arg` and `mock_count`.

## Self-tests

| Member | What it covers |
|---|---|
| `QCLLESRC/MOCKTEST` → `QRPGLESRC/MOCKENG_T` | Codec round trips for every type, rejected values, decimal data errors, matchers |
| `QCLLESRC/MOCKDEMO` → `QRPGLESRC/DEMOCUT_T` | End to end: a hidden-mock check, `*PGM` and strict `*SRVPGM` mocks, stubs, throws, consecutive returns, argument capture, verification messages, CL `MOCKCOUNT`/`MOCKGETARG`/`MOCKVERIFY`, bad-binding detection, cleanup |

Run both with `CALL QTEMP/BUILD PARM('RPGMOCK' '/home/ME/IBMiMock' '*YES')`, or after a build with `CALL RPGMOCK/MOCKTEST PARM('RPGMOCK')` and `CALL RPGMOCK/MOCKDEMO PARM('RPGMOCK')`.
