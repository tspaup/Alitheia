var AlitheiaNonS1 = artifacts.require("AlitheiaNonS1");

contract('AlitheiaNonS1', function(accounts) {
  it("should assert true", function(done) {
    var alit = AlitheiaNonS1.deployed();
    assert.isTrue(true);
    done();
  });

  it("should return the balance of token owner", function() {
  	var alit;
  	return Alitheia.deployed().then(function(instance){
  		alit = instance;
  		return alit.balanceOf.call(accounts[0]);
  	}).then(function(result){
  		assert.equal(result.toNumber(), (100000000) * (10 ** 18), 'balance is wrong');
  	})
  });
});