**free
// ------------------------------------------------------------------
// EXCAPTURE - Look at the arguments a dependency received
//
// Features: mock_arg(obj : proc : callNo : parmNo), mock_count()
// Captured values are text. Use MOCK_LAST for the most recent call
// and MOCK_PGM as the procedure name for program mocks.
// ------------------------------------------------------------------
ctl-opt main(main);

/copy QTEMP/MOCKINC,MOCK_H
/copy QTEMP/MOCKINC,EXAMPLE_H

dcl-proc main;
  dcl-s name char(30);
  dcl-s found ind;

  mock('MOCKRESET');

  getPrice('A0001');
  getPrice('B0002');
  getDiscount(250.00 : 'SPRING');
  getCustomer('C0042' : name : found);

  expect(mock_count('EXPRICE' : 'EX_PRICE') = 2 : 'EX_PRICE called twice');
  expect(mock_arg('EXPRICE' : 'EX_PRICE' : 1 : 1) = 'A0001'
         : 'first call, parameter 1');
  expect(mock_arg('EXPRICE' : 'EX_PRICE' : MOCK_LAST : 1) = 'B0002'
         : 'last call, parameter 1');
  expect(mock_arg('EXPRICE' : 'EX_DISCOUNT' : MOCK_LAST : 1) = '250.00'
         : 'numbers come back as text');
  expect(mock_arg('EXPRICE' : 'EX_DISCOUNT' : MOCK_LAST : 2) = 'SPRING'
         : 'discount code');
  expect(mock_arg('EXCUST' : MOCK_PGM : MOCK_LAST : 1) = 'C0042'
         : 'program mock argument');
end-proc;
