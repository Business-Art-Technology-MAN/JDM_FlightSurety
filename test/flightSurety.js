
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
            
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false);
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
      
  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

      await config.flightSuretyData.setOperatingStatus(false);

      let reverted = false;
      try 
      {
          await config.flightSurety.setTestingMode(true);
      }
      catch(e) {
          reverted = true;
      }
      assert.equal(reverted, true, "Access not blocked for requireIsOperational");      

      // Set it back for other tests to work
      await config.flightSuretyData.setOperatingStatus(true);

  });

  it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {
    
    // ARRANGE
    let newAirline = accounts[2];

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(newAirline, {from: config.firstAirline});
    }
    catch(e) {

    }
    let result = await config.flightSuretyData.isAirline.call(newAirline); 

    // ASSERT
    assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

  });

  it('(airline) test funding an Airline using fund()', async () => {
    
    // ARRANGE
    const minFund = web3.utils.toWei('10', 'ether');
    const b4bal = await web3.eth.getBalance(config.flightSuretyData.address);
     

    // ACT
    try {
        await config.flightSuretyApp.fund_airline({from: config.firstAirline, value: minFund});
    }
    catch(e) {
            console.log(e);
    }
    
    const result = await config.flightSuretyData.is_funded_airline.call(config.firstAirline); 
    const bal_tmp = (await web3.eth.getBalance(config.flightSuretyData.address));
    const bal_after = new BigNumber(bal_tmp);
    
    let b4 = new BigNumber(b4bal);
    
    let final_bal = b4.plus(new BigNumber(minFund))
    
    // ASSERT
    assert.equal(result, true, "Airline should have been marked as funded");
    assert.equal(final_bal.isEqualTo(bal_after), true, "Airline should have provided funding");
    
  });

  it('(Multi-party Consensus) prove airlines require votes when num airlines > 4.', async () => {
    
    // ARRANGE
    const minFund = web3.utils.toWei('10', 'ether');
    
    const tmpAddress = accounts[3];

    // ACT
    try {
        
        let tmp = await config.flightSuretyData.first_airline();
        

        await config.flightSuretyApp.fund_airline({from: accounts[3], value: minFund});
        await config.flightSuretyApp.fund_airline({from: accounts[4], value: minFund});
        await config.flightSuretyApp.fund_airline({from: accounts[5], value: minFund});
        await config.flightSuretyApp.fund_airline({from: accounts[6], value: minFund});
        
        
        await config.flightSuretyApp.registerAirline(accounts[3], { from: config.firstAirline })
        await config.flightSuretyApp.registerAirline(accounts[4], { from: config.firstAirline });
        await config.flightSuretyApp.registerAirline(accounts[5], { from: config.firstAirline });
        await config.flightSuretyApp.registerAirline(accounts[6], { from: config.firstAirline });
       let jnk = await config.flightSuretyData.get_airline_count()
       console.log(jnk.toString())

    }
    catch(e) {
            console.log(e);
    }
    
    let result = await config.flightSuretyData.isAirline(accounts[6])
    // ASSERT
    assert.equal(result, false, "Airline should have not have been registered.");
    //assert.equal(final_bal.isEqualTo(bal_after), true, "Airline should have provided funding");
    
  });

  it('(Multi-party Consensus) prove half of airlines voted for new airline registartion airlines > 4.', async () => {
    
    // ARRANGE
    const minFund = web3.utils.toWei('10', 'ether');
    
    // ACT
    try {
        
       await config.flightSuretyApp.registerAirline(accounts[6], {from: accounts[3]})
       await config.flightSuretyApp.registerAirline(accounts[6], {from: accounts[4]})
       await config.flightSuretyApp.registerAirline(accounts[6], {from: accounts[5]})


    }
    catch(e) {
            console.log(e);
    }
    
    let result = await config.flightSuretyData.isAirline(accounts[6])
    // ASSERT
    assert.equal(result, true, "Airline should have been registered.");
    //assert.equal(final_bal.isEqualTo(bal_after), true, "Airline should have provided funding");
    
  });

  it('(Multi-party Consensus) prove sponsor airlines can only vote once.', async () => {
    
    // ARRANGE
    const minFund = web3.utils.toWei('10', 'ether');
    let result = false;
    // ACT
    try {
        
       await config.flightSuretyApp.registerAirline(accounts[6], {from: accounts[3]})
       


    }
    catch(e) {
         result = true;  
    }
    
    //let result = await config.flightSuretyData.isAirline(accounts[6])
    // ASSERT
    assert.equal(result, true, "Airlines should only be allowed to vote once.");
    //assert.equal(final_bal.isEqualTo(bal_after), true, "Airline should have provided funding");
    
  });


});
