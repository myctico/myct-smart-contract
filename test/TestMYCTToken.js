const MYCTToken = artifacts.require("./MYCTToken.sol");

contract("MYCTToken test", async accounts => {

	it("Check starting distribution", async () => {    
		let instance = await MYCTToken.deployed();	

	    let PROJECT = await instance.balanceOf.call(process.env.PROJECT);
	    assert.equal(PROJECT.valueOf(), 3000000000000000);

	    let BONUS = await instance.balanceOf.call(process.env.BONUS);
	    assert.equal(BONUS.valueOf(), 1000000000000000);

	    let BOUNTY = await instance.balanceOf.call(process.env.BOUNTY);
	    assert.equal(BOUNTY.valueOf(), 250000000000000);

	    let ADVISER = await instance.balanceOf.call(process.env.ADVISER);
	    assert.equal(ADVISER.valueOf(), 250000000000000);
	});
});