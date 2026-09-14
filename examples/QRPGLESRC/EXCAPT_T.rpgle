**free
// ------------------------------------------------------------------
// EXCAPT_T - Look at the arguments a dependency received
//
// Features: imoq_arg(obj : proc : callNo : parmNo), imoq_count()
// Captured values are text. Use IMOQ_LAST for the most recent call
// and IMOQ_PGM as the procedure name for program mocks.
// Run it with the driver EXCAPT.
// ------------------------------------------------------------------
ctl-opt main(main);

/copy QRPGLESRC,IMOQ_H

// The dependencies this example calls. They are mocks created by
// the driver EXCAPT; no real objects exist.

// EXCUST (*PGM): look up a customer name
dcl-pr getCustomer extpgm('EXCUST');
  custId char(5) const;
  name char(30);
  found ind;
end-pr;

// EXPRICE (*SRVPGM), procedure EX_PRICE: price of an item
dcl-pr getPrice packed(7:2) extproc('EX_PRICE');
  item char(5) const;
end-pr;

// EXPRICE (*SRVPGM), procedure EX_DISCOUNT: discount for an amount
dcl-pr getDiscount packed(7:2) extproc('EX_DISCOUNT');
  amount packed(7:2) const;
  code char(10) const options(*nopass:*omit);
end-pr;

/copy QRPGLESRC,EXAMPLE_H

dcl-proc main;
  dcl-s name char(30);
  dcl-s found ind;

  imoq('IMOQRESET');

  getPrice('A0001');
  getPrice('B0002');
  getDiscount(250.00 : 'SPRING');
  getCustomer('C0042' : name : found);

  expect(imoq_count('EXPRICE' : 'EX_PRICE') = 2 : 'EX_PRICE called twice');
  expect(imoq_arg('EXPRICE' : 'EX_PRICE' : 1 : 1) = 'A0001'
         : 'first call, parameter 1');
  expect(imoq_arg('EXPRICE' : 'EX_PRICE' : IMOQ_LAST : 1) = 'B0002'
         : 'last call, parameter 1');
  expect(imoq_arg('EXPRICE' : 'EX_DISCOUNT' : IMOQ_LAST : 1) = '250.00'
         : 'numbers come back as text');
  expect(imoq_arg('EXPRICE' : 'EX_DISCOUNT' : IMOQ_LAST : 2) = 'SPRING'
         : 'discount code');
  expect(imoq_arg('EXCUST' : IMOQ_PGM : IMOQ_LAST : 1) = 'C0042'
         : 'program mock argument');
end-proc;
