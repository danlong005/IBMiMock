**free
// ------------------------------------------------------------------
// MOCKGEN - RPGMOCK source generation
//   * stub source for *PGM and *SRVPGM mocks -> QTEMP/MOCKSRC(obj)
//   * export list from binder source         <- QTEMP/MOCKBND(obj)
// Module of service program MOCKENG.
// ------------------------------------------------------------------
ctl-opt nomain option(*srcstmt:*nodebugio);

/copy QTEMP/MOCKINC,MOCKENG_H

exec sql set option commit = *none, naming = *sql,
  closqlcsr = *endactgrp;

dcl-c LOWER 'abcdefghijklmnopqrstuvwxyz';
dcl-c UPPER 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
dcl-c MAXLINES 20000;

dcl-ds srcRow_t qualified template;
  seq zoned(6:2);
  dat zoned(6:0);
  dta char(228);
end-ds;

dcl-ds gSrc likeds(srcRow_t) dim(20000);
dcl-s gLines int(10);
dcl-s gOverflow ind;

// ==================================================================
// Source member writer
// ==================================================================
dcl-proc srcBegin;
  gLines = 0;
  gOverflow = *off;
end-proc;

dcl-proc srcLine;
  dcl-pi *n;
    text varchar(228) const;
  end-pi;
  if gLines >= MAXLINES;
    gOverflow = *on;
    return;
  endif;
  gLines += 1;
  gSrc(gLines).seq = gLines / 100;
  gSrc(gLines).dat = 0;
  gSrc(gLines).dta = text;
end-proc;

dcl-proc srcWrite;
  dcl-pi *n ind;
    file char(10) const;
    mbr char(10) const;
    msg varchar(512);
  end-pi;
  dcl-s stmt varchar(200);
  dcl-s n int(10);
  dcl-s code int(10);
  dcl-s t varchar(300);

  if gOverflow;
    msg = 'Generated source exceeds ' + %char(MAXLINES) + ' lines';
    return *off;
  endif;

  exec sql drop alias qtemp.mock_srcw;
  stmt = 'CREATE ALIAS QTEMP.MOCK_SRCW FOR QTEMP.' + %trim(file)
       + ' (' + %trim(mbr) + ')';
  exec sql execute immediate :stmt;
  if sqlcode < 0;
    code = sqlcode;
    exec sql get diagnostics condition 1 :t = message_text;
    msg = 'Cannot open QTEMP/' + %trim(file) + '(' + %trim(mbr)
        + '): SQLCODE ' + %char(code) + ' ' + t;
    return *off;
  endif;

  exec sql delete from qtemp.mock_srcw;
  n = gLines;
  exec sql insert into qtemp.mock_srcw (srcseq, srcdat, srcdta)
    :n rows values(:gSrc);
  if sqlcode < 0;
    code = sqlcode;
    exec sql get diagnostics condition 1 :t = message_text;
    msg = 'Cannot write QTEMP/' + %trim(file) + '(' + %trim(mbr)
        + '): SQLCODE ' + %char(code) + ' ' + t;
    exec sql drop alias qtemp.mock_srcw;
    return *off;
  endif;
  exec sql drop alias qtemp.mock_srcw;
  return *on;
end-proc;

// ------------------------------------------------------------------
dcl-proc quote;
  dcl-pi *n varchar(4200);
    s varchar(4096) const;
  end-pi;
  dcl-s r varchar(4200);
  dcl-s i int(10);
  for i = 1 to %len(s);
    if %subst(s : i : 1) = '''';
      r += '''''';
    else;
      r += %subst(s : i : 1);
    endif;
  endfor;
  return '''' + r + '''';
end-proc;

dcl-proc num5;
  dcl-pi *n char(5);
    n int(10) const;
  end-pi;
  return %editc(%dec(n : 5 : 0) : 'X');
end-proc;

// Declarations shared by every stub
dcl-proc genCommon;
  srcLine('dcl-ds mock_throw_t qualified template;');
  srcLine('  msgId char(7);');
  srcLine('  msgf char(10);');
  srcLine('  msgfLib char(10);');
  srcLine('  msgDta varchar(512);');
  srcLine('end-ds;');
  srcLine('dcl-pr mock_invoke int(10) extproc(''MOCK_INVOKE'');');
  srcLine('  obj char(10) const;');
  srcLine('  proc varchar(4096) const;');
  srcLine('  parmCount int(10) value;');
  srcLine('  parmPtrs pointer value;');
  srcLine('  rtnPtr pointer value;');
  srcLine('  thr likeds(mock_throw_t);');
  srcLine('end-pr;');
  srcLine('dcl-pr mock_sndEsc extpgm(''QMHSNDPM'');');
  srcLine('  msgId char(7) const;');
  srcLine('  msgf char(20) const;');
  srcLine('  msgDta char(512) const;');
  srcLine('  msgDtaLen int(10) const;');
  srcLine('  msgType char(10) const;');
  srcLine('  callStk char(10) const;');
  srcLine('  callStkCtr int(10) const;');
  srcLine('  msgKey char(4);');
  srcLine('  errCode char(8);');
  srcLine('end-pr;');
end-proc;

// Body shared by every stub: capture addresses, invoke, maybe throw
dcl-proc genBody;
  dcl-pi *n;
    objLit varchar(20) const;
    procLit varchar(4200) const;
    nParms int(10) const;
    rtnExpr varchar(40) const;
  end-pi;
  dcl-s i int(10);

  srcLine('  dcl-s mockPtrs pointer dim(64);');
  srcLine('  dcl-ds mockThr likeds(mock_throw_t);');
  srcLine('  dcl-s mockN int(10);');
  srcLine('  dcl-s mockKey char(4);');
  srcLine('  dcl-s mockEc char(8) inz(*allx''00'');');
  srcLine('  mockN = %parms();');
  srcLine('  if mockN < 0 or mockN > ' + %char(nParms) + ';');
  srcLine('    mockN = ' + %char(nParms) + ';');
  srcLine('  endif;');
  for i = 1 to nParms;
    srcLine('  if mockN >= ' + %char(i) + ';');
    srcLine('    mockPtrs(' + %char(i) + ') = %addr(p' + %char(i) + ');');
    srcLine('  endif;');
  endfor;
  srcLine('  if mock_invoke(' + objLit + ' :');
  srcLine('       ' + procLit + ' :');
  srcLine('       mockN : %addr(mockPtrs) : ' + rtnExpr
        + ' : mockThr) = 1;');
  srcLine('    mock_sndEsc(mockThr.msgId : mockThr.msgf + mockThr.msgfLib');
  srcLine('       : mockThr.msgDta : %len(mockThr.msgDta) : ''*ESCAPE''');
  srcLine('       : ''*'' : 1 : mockKey : mockEc);');
  srcLine('  endif;');
end-proc;

// ==================================================================
// mock_genPgm - program stub (64 generic by-reference parameters)
// ==================================================================
dcl-proc mock_genPgm export;
  dcl-pi *n ind;
    obj char(10) const;
    parmCount int(10) value;
    msg varchar(512);
  end-pi;
  dcl-s i int(10);

  msg = '';
  srcBegin();
  srcLine('**free');
  srcLine('// RPGMOCK generated stub for *PGM ' + %trim(obj)
        + ' - do not edit');
  srcLine('ctl-opt option(*srcstmt:*nodebugio);');
  genCommon();
  srcLine('dcl-pi *n;');
  for i = 1 to MOCK_MAXP;
    srcLine('  p' + %char(i) + ' char(1) options(*nopass);');
  endfor;
  srcLine('end-pi;');
  // body uses local-style declarations at module level for a cycle main
  srcLine('dcl-s mockPtrs pointer dim(64);');
  srcLine('dcl-ds mockThr likeds(mock_throw_t);');
  srcLine('dcl-s mockN int(10);');
  srcLine('dcl-s mockKey char(4);');
  srcLine('dcl-s mockEc char(8) inz(*allx''00'');');
  srcLine('mockN = %parms();');
  srcLine('if mockN < 0 or mockN > 64;');
  srcLine('  mockN = 64;');
  srcLine('endif;');
  for i = 1 to MOCK_MAXP;
    srcLine('if mockN >= ' + %char(i) + ';');
    srcLine('  mockPtrs(' + %char(i) + ') = %addr(p' + %char(i) + ');');
    srcLine('endif;');
  endfor;
  srcLine('if mock_invoke(' + quote(%trim(obj)) + ' : ''*PGM'' :');
  srcLine('     mockN : %addr(mockPtrs) : *null : mockThr) = 1;');
  srcLine('  mock_sndEsc(mockThr.msgId : mockThr.msgf + mockThr.msgfLib');
  srcLine('     : mockThr.msgDta : %len(mockThr.msgDta) : ''*ESCAPE''');
  srcLine('     : ''*'' : 1 : mockKey : mockEc);');
  srcLine('endif;');
  srcLine('return;');

  return srcWrite('MOCKSRC' : obj : msg);
end-proc;

// ==================================================================
// mock_genSrv - service program stub module
// ==================================================================
dcl-proc mock_genSrv export;
  dcl-pi *n ind;
    obj char(10) const;
    msg varchar(512);
  end-pi;
  dcl-s procs varchar(4096) dim(2000);
  dcl-s kinds char(4) dim(2000);
  dcl-s sizes int(10) dim(2000);
  dcl-s nProcs int(10);
  dcl-s nm varchar(4096);
  dcl-s kind char(4);
  dcl-s size int(10);
  dcl-s i int(10);
  dcl-s j int(10);
  dcl-s pname varchar(20);
  dcl-s rtn varchar(80);
  dcl-s typ varchar(64);
  dcl-s opt varchar(40);
  dcl-ds def likeds(mock_def_t);
  dcl-ds defs likeds(mock_def_t) dim(64);
  dcl-ds rtnDef likeds(mock_def_t);
  dcl-s nDefs int(10);
  dcl-s hasRtn ind;
  dcl-s parmNo int(5);

  msg = '';
  exec sql declare cGenProc cursor for
    select proc, kind, datasize from qtemp.mock_proc
     where obj = :obj order by seq;
  exec sql open cGenProc;
  dow sqlcode = 0 and nProcs < 2000;
    exec sql fetch next from cGenProc into :nm, :kind, :size;
    if sqlcode <> 0;
      leave;
    endif;
    nProcs += 1;
    procs(nProcs) = nm;
    kinds(nProcs) = kind;
    sizes(nProcs) = size;
  enddo;
  exec sql close cGenProc;

  if nProcs = 0;
    msg = 'Mock ' + %trim(obj) + ' has no exports';
    return *off;
  endif;

  srcBegin();
  srcLine('**free');
  srcLine('// RPGMOCK generated stub for *SRVPGM ' + %trim(obj)
        + ' - do not edit');
  srcLine('ctl-opt nomain option(*srcstmt:*nodebugio);');
  genCommon();

  // data exports first (global declarations)
  for i = 1 to nProcs;
    if kinds(i) = 'DATA';
      if %len(procs(i)) > 180;
        msg = 'Export name too long for RPGMOCK: ' + %subst(procs(i):1:60);
        return *off;
      endif;
      srcLine('dcl-s MOCKD' + num5(i) + ' char(' + %char(sizes(i))
            + ') export(');
      srcLine('  ' + quote(procs(i)) + ');');
    endif;
  endfor;

  for i = 1 to nProcs;
    if kinds(i) = 'DATA';
      iter;
    endif;
    if %len(procs(i)) > 180;
      msg = 'Export name too long for RPGMOCK: ' + %subst(procs(i):1:60);
      return *off;
    endif;

    // signature
    clear defs;
    clear rtnDef;
    nDefs = 0;
    hasRtn = *off;
    nm = procs(i);
    exec sql declare cGenSig cursor for
      select parmno, type, len, dec, passing from qtemp.mock_sig
       where obj = :obj and proc = :nm order by parmno;
    exec sql open cGenSig;
    dow sqlcode = 0;
      exec sql fetch next from cGenSig
        into :parmNo, :def.type, :def.len, :def.dec, :def.passing;
      if sqlcode <> 0;
        leave;
      endif;
      if parmNo = 0;
        rtnDef = def;
        hasRtn = *on;
      elseif parmNo <= MOCK_MAXP;
        defs(parmNo) = def;
        if parmNo > nDefs;
          nDefs = parmNo;
        endif;
      endif;
    enddo;
    exec sql close cGenSig;

    pname = 'MOCKP' + num5(i);
    rtn = '';
    if hasRtn;
      rtn = ' ' + mock_rpgType(rtnDef);
    endif;

    srcLine('');
    srcLine('// ' + %subst(procs(i) : 1 : %min(%len(procs(i)) : 200)));
    srcLine('dcl-proc ' + pname + ' export;');
    srcLine('  dcl-pi *n' + rtn + ' extproc(');
    srcLine('    ' + quote(procs(i)) + ');');
    for j = 1 to nDefs;
      srcLine('    p' + %char(j) + ' ' + parmDecl(defs(j)) + ';');
    endfor;
    srcLine('  end-pi;');
    if hasRtn;
      srcLine('  dcl-s mockRtn ' + mock_rpgType(rtnDef) + ' inz;');
      genBody(quote(%trim(obj)) : quote(procs(i)) : nDefs
              : '%addr(mockRtn)');
      srcLine('  return mockRtn;');
    else;
      genBody(quote(%trim(obj)) : quote(procs(i)) : nDefs : '*null');
      srcLine('  return;');
    endif;
    srcLine('end-proc;');
  endfor;

  return srcWrite('MOCKSRC' : obj : msg);
end-proc;

dcl-proc parmDecl;
  dcl-pi *n varchar(120);
    def likeds(mock_def_t) const;
  end-pi;
  select;
  when def.passing = '*VALUE';
    return mock_rpgType(def) + ' value options(*nopass)';
  endsl;
  // *CONST is passed by reference like *REF; declaring it without
  // CONST lets the stub take the parameter's address
  return mock_rpgType(def) + ' options(*nopass:*omit)';
end-proc;

// ==================================================================
// mock_readExports - export symbols of the *CURRENT export block
// ==================================================================
dcl-proc mock_readExports export;
  dcl-pi *n ind;
    obj char(10) const;
    names varchar(4096) dim(2000);
    count int(10);
    msg varchar(512);
  end-pi;
  dcl-s stmt varchar(200);
  dcl-s line char(228);
  dcl-s l varchar(228);
  dcl-s all varchar(200000);
  dcl-s up varchar(200000);
  dcl-s p int(10);
  dcl-s q int(10);
  dcl-s blkStart int(10);
  dcl-s blkEnd int(10);
  dcl-s hdrEnd int(10);
  dcl-s curStart int(10);
  dcl-s curEnd int(10);
  dcl-s code int(10);
  dcl-s t varchar(300);
  dcl-s sym varchar(4096);

  msg = '';
  count = 0;
  clear names;

  exec sql drop alias qtemp.mock_bndr;
  stmt = 'CREATE ALIAS QTEMP.MOCK_BNDR FOR QTEMP.MOCKBND ('
       + %trim(obj) + ')';
  exec sql execute immediate :stmt;
  if sqlcode < 0;
    code = sqlcode;
    exec sql get diagnostics condition 1 :t = message_text;
    msg = 'Cannot read binder source QTEMP/MOCKBND(' + %trim(obj)
        + '): SQLCODE ' + %char(code) + ' ' + t;
    return *off;
  endif;

  // join all lines, dropping continuation characters
  exec sql declare cBnd2 cursor for
    select srcdta from qtemp.mock_bndr order by srcseq;
  exec sql open cBnd2;
  if sqlcode < 0;
    code = sqlcode;
    exec sql get diagnostics condition 1 :t = message_text;
    msg = 'Cannot read binder source QTEMP/MOCKBND(' + %trim(obj)
        + '): SQLCODE ' + %char(code) + ' ' + t;
    exec sql drop alias qtemp.mock_bndr;
    return *off;
  endif;
  dow sqlcode = 0;
    exec sql fetch next from cBnd2 into :line;
    if sqlcode <> 0;
      leave;
    endif;
    l = %trimr(line);
    if %len(l) > 0;
      if %subst(l : %len(l) : 1) = '+';
        l = %subst(l : 1 : %len(l) - 1);
      endif;
    endif;
    if %len(all) + %len(l) + 1 < 200000;
      all += l + ' ';
    endif;
  enddo;
  exec sql close cBnd2;
  exec sql drop alias qtemp.mock_bndr;

  // strip comments
  p = %scan('/*' : all);
  dow p > 0;
    q = %scan('*/' : all : p + 2);
    if q = 0;
      all = %subst(all : 1 : p - 1);
      leave;
    endif;
    all = %subst(all : 1 : p - 1) + ' ' + %subst(all : q + 2);
    p = %scan('/*' : all);
  enddo;
  up = %xlate(LOWER : UPPER : all);

  // locate the *CURRENT block (first block not marked *PRV)
  p = 1;
  dow p <= %len(up);
    blkStart = %scan('STRPGMEXP' : up : p);
    if blkStart = 0;
      leave;
    endif;
    blkEnd = %scan('ENDPGMEXP' : up : blkStart);
    if blkEnd = 0;
      blkEnd = %len(up) + 1;
    endif;
    hdrEnd = %scan('EXPORT' : up : blkStart + 9);
    if hdrEnd = 0 or hdrEnd > blkEnd;
      hdrEnd = blkEnd;
    endif;
    if %scan('*PRV' : %subst(up : blkStart : hdrEnd - blkStart)) = 0;
      curStart = blkStart;
      curEnd = blkEnd;
      leave;
    endif;
    p = blkEnd + 9;
  enddo;

  if curStart = 0;
    msg = 'No STRPGMEXP PGMLVL(*CURRENT) block in the binder source';
    return *off;
  endif;

  // each EXPORT statement
  p = %scan('EXPORT' : up : curStart + 9);
  dow p > 0 and p < curEnd;
    q = p + 6;
    if p > 1 and %subst(up : p - 1 : 1) <> ' ';
      p = %scan('EXPORT' : up : q);
      iter;
    endif;
    sym = parseSymbol(all : up : q);
    if sym <> '' and count < 2000;
      count += 1;
      names(count) = sym;
    endif;
    p = %scan('EXPORT' : up : q);
  enddo;
  return *on;
end-proc;

// ------------------------------------------------------------------
// parseSymbol - value after EXPORT: SYMBOL(x), SYMBOL("x"), x or "x"
// ------------------------------------------------------------------
dcl-proc parseSymbol;
  dcl-pi *n varchar(4096);
    all varchar(200000) const;
    up varchar(200000) const;
    pos int(10);
  end-pi;
  dcl-s p int(10);
  dcl-s q int(10);
  dcl-s paren ind;

  p = pos;
  dow p <= %len(all) and %subst(all : p : 1) = ' ';
    p += 1;
  enddo;
  if p > %len(all);
    return '';
  endif;

  if %subst(up : p : 7) = 'SYMBOL(';
    p += 7;
    paren = *on;
    dow p <= %len(all) and %subst(all : p : 1) = ' ';
      p += 1;
    enddo;
  elseif %subst(all : p : 1) = '(';
    p += 1;
    paren = *on;
  endif;

  if %subst(all : p : 1) = '"';
    q = %scan('"' : all : p + 1);
    if q = 0;
      return '';
    endif;
    pos = q + 1;
    if q = p + 1;
      return '';
    endif;
    return %subst(all : p + 1 : q - p - 1);
  endif;

  q = p;
  dow q <= %len(all);
    if %subst(all : q : 1) = ' ' or %subst(all : q : 1) = ')'
       or %subst(all : q : 1) = '(';
      leave;
    endif;
    q += 1;
  enddo;
  pos = q;
  if q = p;
    return '';
  endif;
  if not paren and %subst(up : p : q - p) = 'SYMBOL';
    return '';
  endif;
  return %subst(up : p : q - p);
end-proc;
