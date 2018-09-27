import { expect } from 'chai'
import { web3 } from './helpers/w3'
import expectRevert from './helpers/expectRevert'
import { hasEvent } from './helpers/event'
const AlitheiaNonS1 = artifacts.require('AlitheiaNonS1')

contract('AlitheiaNonS1', () => {
  let accounts, nonS1Token
  beforeEach(async () => {
    accounts = await web3.eth.getAccounts()
    nonS1Token = await AlitheiaNonS1.new()
    await nonS1Token.mint(accounts[0], 500000, { from: accounts[0] })
    await nonS1Token.mint(accounts[1], 500000, { from: accounts[0] })
  })

  describe('balanceOf of account1', () => {
    it('should equal to account1 token balance - 500000', async () => {
    	const data = await nonS1Token.balanceOf(accounts[1])
    	assert.equal(data.toNumber(), 500000, 'Balance is wrong!');   
    })
  })

  describe('burn 100000 from account1', () => {
  	it('should equal to account1 token balance - 400000', async () => {
  		await nonS1Token.burn(100000, {from: accounts[1]})
  		const data = await nonS1Token.balanceOf(accounts[1])

    	assert.equal(data.toNumber(), 400000, 'Balance is wrong!');
  	})
  })

  describe('transfer 100000 from account0 to account1', () => {
  	it('should equal to account0 - 400000', async () => {
  		await nonS1Token.transfer(accounts[1], 100000, {from: accounts[0]})
  		const data = await nonS1Token.balanceOf(accounts[0])

    	assert.equal(data.toNumber(), 400000, 'Balance is wrong!');

    	const years = await nonS1Token.getHolderYears(accounts[1], {from: accounts[0]})
    	console.log('account1 years - ' + JSON.stringify(years))

    	const months = await nonS1Token.getHolderMonths(accounts[1], 2018, {from: accounts[0]})
    	console.log('account1 months - ' + JSON.stringify(months))

    	const days = await nonS1Token.getHolderDays(accounts[1], 2018, 9, {from: accounts[0]})
    	console.log('account1 days - ' + JSON.stringify(days))
  	})
  })
});