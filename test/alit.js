var Alitheia = artifacts.require("Alitheia");

contract('Alitheia', function(accounts) {
  it("should assert true", function(done) {
    var alit = Alitheia.deployed();
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

  it("should return total Supply", function() {
    var alit;
    return Alitheia.deployed().then(function(instance){
      alit = instance;
      return alit.totalSupply.call();
    }).then(function(result){
      assert.equal(result.toNumber(), (100000000) * (10 ** 18), 'total Supply is wrong');
    })
  });

  it("should transfer 100 tokens from A to B", function() {
    var alit;
    return Alitheia.deployed().then(function(instance){
      alit = instance;
      return alit.transfer(accounts[1], 100 * (10 ** 18));
    }).then(function(){
      return alit.balanceOf.call(accounts[0]);
    }).then(function(result){
      assert.equal(result.toNumber(), 99999900 * (10**18), 'A balance is wrong');
      return alit.balanceOf.call(accounts[1]);
    }).then(function(result){
      assert.equal(result.toNumber(), 100 * (10**18), 'B balance is wrong');
      return alit.balanceOfGroup.call(accounts[1], 2018, 8);
    }).then(function(result){
      assert.equal(result.toNumber(), 100 * (10**18), 'B balance is wrong for 9, 2018');
      return alit.yearsOfOwner.call(accounts[1]);
    }).then(function(result){
      console.log('Year list - ' + result);
      return alit.monthsOfOwner.call(accounts[1], 2018);
    }).then(function(result){
      console.log('Month list of 2018 - ' + result);
    });
  });

  it("should give C authority to spend A's tokens", function() {
    var curio;
    return Curio.deployed().then(function(instance){
      curio = instance;
      return curio.approve(accounts[2], 100 * (10**18));
    }).then(function(){
      return curio.increaseApproval(accounts[2], 100 * (10**18));
    }).then(function(){
      return curio.decreaseApproval(accounts[2], 50 * (10**18));
    }).then(function(){
      return curio.allowance.call(accounts[0], accounts[2]);
    }).then(function(result){
      assert.equal(result.toNumber(), 150 * (10**18), 'allowance value is wrong');
      return curio.transferFrom(accounts[0], accounts[1], 150 * (10**18), {from: accounts[2]});
    }).then(function(){
      return curio.balanceOf.call(accounts[0]);
    }).then(function(result){
      assert.equal(result.toNumber(), 750 * (10**18), 'A balance is wrong');
      return curio.balanceOf.call(accounts[1]);
    }).then(function(result){
      assert.equal(result.toNumber(), 250 * (10**18), 'B balance is wrong');
    });
  });
});