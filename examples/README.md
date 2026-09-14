# iMoq examples

This folder holds the iMoq example code, laid out like the library's
source files (`QRPGLESRC`, `QCLLESRC`, `QSRVSRC`):

- **Feature examples:** one per feature. Each is a test program
  `QRPGLESRC/EX…_T` plus a small driver `QCLLESRC/EX…`. `QCLLESRC/EXAMPLES`
  runs them all.
- **End-to-end demo:** `DEMOCUT`, `DEMODEP`, `DEMOSRV` and `DEMOCUT_T`, run by
  the `QCLLESRC/IMOQDEMO` driver.

**[docs/EXAMPLES.md](../docs/EXAMPLES.md)** explains every example, with the
key code and what to notice.
