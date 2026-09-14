**free
// ------------------------------------------------------------------
// DEMOCUT - iMoq demo code under test (*SRVPGM).
// Uses program DEMODEP (dynamic call) and service program DEMOSRV
// (bound call). Bind with BNDSRVPGM((*LIBL/DEMOSRV)).
// ------------------------------------------------------------------
ctl-opt nomain;

dcl-pr demoDep extpgm('DEMODEP');
  custId char(10) const;
  custName char(50);
  found ind;
end-pr;

dcl-pr demo_calcTax packed(11:2) extproc('DEMO_CALCTAX');
  amount packed(11:2) const;
  state char(2) const;
end-pr;

// Order total = amount + tax
//   -1 = unknown customer, -2 = customer lookup failed
dcl-proc demo_orderTotal export;
  dcl-pi *n packed(11:2);
    custId char(10) const;
    amount packed(11:2) const;
    state char(2) const;
    custName char(50);
  end-pi;
  dcl-s found ind inz(*off);

  custName = *blanks;
  monitor;
    demoDep(custId : custName : found);
  on-error;
    return -2;
  endmon;
  if not found;
    return -1;
  endif;
  return amount + demo_calcTax(amount : state);
end-proc;
