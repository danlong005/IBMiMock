# IBMiMock

**IBMIMOCK** is a mocking framework for RPG unit tests on IBM i, in the spirit of
Mockito and Moq.

Your CL test driver runs a few commands. They replace the programs and service
programs your code calls with **mocks in QTEMP**. Your tests decide what those
mocks return, check how they were called, and remove them when done. It needs
no changes to the code under test, and no real customers, tax tables or files.

```
MOCKPGM    OBJ(CUSTLKUP) PARMS((*CHAR 10) (*CHAR 50) (*IND))
MOCKWHEN   OBJ(CUSTLKUP) ARGS((1 *EQ C001)) SETPARM((2 'ACME') (3 '1'))
   ... run the code under test ...
MOCKVERIFY OBJ(CUSTLKUP) ARGS((1 *EQ C001)) TIMES(*ONCE)
MOCKRMV
```

## Features

- **Mocks for `*PGM` and `*SRVPGM` dependencies.** A service program mock copies
  the real exports and signatures, so callers bound with `*LIBL` activate it
  without errors.
- **Stubbing:**
  - return values, output parameters and escape messages
  - argument matchers (`*EQ`, `*GT`, `*LIKE`, `*OMIT`, …)
  - consecutive answers and `TIMES(n)` limits
  - loose or strict mocks
- **Verification:** exact, at-least, at-most and never counts,
  `MOCKNOMORE`, and argument capture. Failure messages list the calls that
  actually happened.
- **No recompiles between tests.** Stubs are stored as data, so you create
  mocks once per driver and restub them in every test.
- **Works from CL and RPG.** The commands run in CL drivers, and the `MOCK_H`
  copybook wraps them for RPGUnit (or any RPG) tests.
- **Built-in safety checks.** IBMIMOCK tells you when a mock would be ignored
  because the library list or a hard-coded binding bypasses QTEMP.

## Quick start

On the IBM i (IBM i 7.4 or later):

```
git clone https://github.com/danlong005/IBMiMock.git /home/ME/IBMiMock

CRTBNDCL PGM(QTEMP/BUILD) SRCSTMF('/home/ME/IBMiMock/QCLLESRC/BUILD.clle')
CALL     QTEMP/BUILD PARM('IBMIMOCK' '/home/ME/IBMiMock' '*YES')
```

`BUILD` creates the library and its source files, copies the repository into
source members, compiles everything, and (with `'*YES'`) runs the self-tests.
Then add `IBMIMOCK` to your test driver's library list, and bind your test
programs to service program `IBMIMOCK/MOCKENG`.

A test in RPG looks like this:

```rpgle
dcl-proc test_total_adds_tax export;
  dcl-s name char(50);
  mock('MOCKWHEN OBJ(TAXSRV) PROC(CALCTAX) RETURN(''6.00'')');

  aEqual('106.00' : %char(order_total('C001' : 100 : 'PA' : name)));
  assert(mock_ok('MOCKVERIFY OBJ(TAXSRV) PROC(CALCTAX) TIMES(*ONCE)')
         : mock_lastError());
end-proc;
```

## Documentation

New to mocking on IBM i? Start with the **[Examples](docs/EXAMPLES.md)**:
about fifteen short programs, each showing one feature, with the key code
explained.

The **[Programmer's Guide](docs/PROGRAMMERS_GUIDE.md)** covers everything:
- how mocks replace real objects, and the rules that make that work
- installing and rebuilding
- a step-by-step first test
- stubbing and verification recipes
- writing tests in RPG
- troubleshooting and messages
- a command reference

## Repository layout

The repository is laid out like an IBM i library: each folder is a source
physical file.

| Folder | Contents |
|---|---|
| `QRPGLESRC` | Engine (`MOCKENG`, `MOCKGEN`, `MOCKCDC`), copybooks `MOCK_H` and `MOCKENG_H` |
| `QCLLESRC` | `BUILD`, the `MOCKINST` installer, command processing programs `MCK*C` |
| `QCMDSRC` | Command definitions `MOCKPGM` … `MOCKCHK` |
| `QSRVSRC` | Binder source for `MOCKENG` |
| `examples` | Example code ([documented here](docs/EXAMPLES.md)), in the same source-file folders (`QRPGLESRC`, `QCLLESRC`, `QSRVSRC`) |
| `docs` | Programmer's Guide and Examples |

The engine's unit tests, `MOCKTEST` and `MOCKENG_T` (with the `MOCKTST_H`
harness), stay with the library code. The `examples` folder holds two kinds of
example:
- **Feature examples:** `EX*` members, run by `EXAMPLES`, one feature each.
- **End-to-end demo:** code under test `DEMOCUT`, its dependencies `DEMODEP`
  and `DEMOSRV`, tests `DEMOCUT_T`, and driver `MOCKDEMO`.

`BUILD` copies and runs the examples only when you pass `'*YES'`.
