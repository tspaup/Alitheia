var WhiteList = artifacts.require("./WhiteList.sol");
var AlitheiaNonS1 = artifacts.require("./AlitheiaNonS1.sol");

module.exports = function(deployer){
	deployer.deploy(WhiteList).then(function(){
		return deployer.deploy(AlitheiaNonS1, WhiteList.address);
	});
}