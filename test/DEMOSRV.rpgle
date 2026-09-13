**free
// ------------------------------------------------------------------
// DEMOSRV - RPGMOCK demo dependency (*SRVPGM): tax service.
// ------------------------------------------------------------------
ctl-opt nomain;

dcl-proc demo_calcTax export;
  dcl-pi *n packed(11:2);
    amount packed(11:2) const;
    state char(2) const;
  end-pi;
  return %dech(amount * 0.10 : 11 : 2);
end-proc;

dcl-proc demo_taxRate export;
  dcl-pi *n packed(5:4);
    state char(2) const;
  end-pi;
  return 0.1;
end-proc;
