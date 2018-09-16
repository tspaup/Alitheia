var AlitheiaNonS1 = artifacts.require("./AlitheiaNonS1.sol");
var AlitheiaS1 = artifacts.require("./AlitheiaS1.sol");

module.exports = function(deployer){
	deployer.deploy(AlitheiaNonS1).then(function(){
		return deployer.deploy(AlitheiaS1, AlitheiaNonS1.address);
	});
}