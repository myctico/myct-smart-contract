const MYCTCrowsSale = artifacts.require("./MYCTCrowdSale.sol");

contract("MYCTCrowsSale test", async accounts => {

	it("Check stage period", async () => {    
		let instance = await MYCTCrowsSale.deployed();	

	    let stage01 = await instance.Stages.call(0);
	    let stage02 = await instance.Stages.call(1);
	    let stage03 = await instance.Stages.call(2);
	    
	    assert.equal(stage01.startsAt.toNumber(), 3000000000000000);
	});

});