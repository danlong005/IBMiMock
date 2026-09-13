**free
// ------------------------------------------------------------------
// DEMODEP - RPGMOCK demo dependency (*PGM): customer lookup.
// The "real" program only knows customer REAL01.
// ------------------------------------------------------------------
ctl-opt dftactgrp(*no) actgrp(*caller);

dcl-pi *n;
  custId char(10) const;
  custName char(50);
  found ind;
end-pi;

if custId = 'REAL01';
  custName = 'Real Customer';
  found = *on;
else;
  custName = *blanks;
  found = *off;
endif;
return;
