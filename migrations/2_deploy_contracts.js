const SafeMath = artifacts.require("./common/SafeMath.sol");
const Rate = artifacts.require("./common/Rate.sol");
const MYCTCrowdSale = artifacts.require("./MYCTCrowdSale.sol");
const MYCTToken = artifacts.require("./MYCTToken.sol");

module.exports = function(deployer, network, accounts) {
  deployer.then(async () => {	

	let math = await deployer.deploy(SafeMath, {overwrite: false});
	let rate = await deployer.deploy(Rate);

	await deployer.link(SafeMath, [MYCTCrowdSale, MYCTToken]);

	let crowdsale = await deployer.deploy(MYCTCrowdSale, process.env.WALLET, 14, 
		1555326000, 
		1555412399, 
		1555412400, 
		1555498799, 
		1555498800, 
		1555585200);

	let token = await deployer.deploy(MYCTToken,
		  		"My City", 
		  		"MYCT", 
		  		crowdsale.address,
		  		process.env.PROJECT,
		  		process.env.BONUS,
		  		process.env.BOUNTY,
		  		process.env.ADVISER);

	await crowdsale.setTokenContract(token.address);
	await crowdsale.setRate(rate.address);
	await crowdsale.updateAgent(process.env.AGENT_INVEST, true);
	await rate.updateAgent(process.env.AGENT_EXCHANGE, true);
    await token.transferOwnership(crowdsale.address);
  });
};