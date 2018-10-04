import { expect } from 'chai'
import { web3 } from './helpers/w3'
import expectRevert from './helpers/expectRevert'
import { hasEvent } from './helpers/event'
const AlitheiaNonS1 = artifacts.require('AlitheiaNonS1')
const AlitheiaS1 = artifacts.require('AlitheiaS1')

contract('AlitheiaS1', () => {
  let accounts, nonS1Token, s1Token
  beforeEach(async () => {
    accounts = await web3.eth.getAccounts()
    nonS1Token = await AlitheiaNonS1.new()
    s1Token = await AlitheiaS1.new(nonS1Token.address)

    await nonS1Token.setS1TokenAddress(s1Token.address, { from: accounts[0] })
    await nonS1Token.mint(accounts[0], 500000000, { from: accounts[0] })
    await nonS1Token.mint(accounts[1], 500000, { from: accounts[0] })
    await s1Token.mint(accounts[1], 1000000, { from: accounts[0] } )
  })

  describe('totalBalanceOf', () => {
    it('should equal sum of nonS1 and S1 token balance', async () => {
      const data = await s1Token.totalBalanceOf(accounts[1])
      expect(data.toNumber()).to.equal(1000000 + 500000)
    })
  })

  describe('Non S1 transfer and S1 Converting', () => {
    it('should equal to Non S1 = 3000 among 6000 for Account 1. 3000 are converted to S1', async () => {
      await nonS1Token.transferTest(accounts[2], 1000, 2015, 9, 1, { from: accounts[0] })
      await nonS1Token.transferTest(accounts[2], 2000, 2015, 9, 2, { from: accounts[0] })
      await nonS1Token.transferTest(accounts[2], 3000, 2018, 9, 1, { from: accounts[0] })
      
      const data = await nonS1Token.getUnlockedBalanceOf(accounts[2]) 
      console.log('unlocked token - ' + data)

      const data2 = await s1Token.convertNonS1Tokens({ from: accounts[2] })
      console.log('converted token - ' + JSON.stringify(data2))

      const balance = await nonS1Token.balanceOf(accounts[2])
      assert.equal(balance.toNumber(), 3000, 'Balance is wrong!');
    })
  })

  /*describe('balanceOf', () => {
    it('should calculate dividend owed and reflect in balance', async () => {
      await s1Token.createDividendEvent(200000)
      const totalBalanceOf = await s1Token.totalBalanceOf(accounts[1])
      const currentGlobalDividendEventId = await s1Token.getCurrentGlobalDividendEventId()
      const dividendEventIdForAddress = await s1Token.getDividendEventIdForAddress(accounts[1])
      const dividendOwed = await s1Token.calculateDividendOwed(accounts[1])
      const dividendAmount = await s1Token.getAmountForDividendId(1)
      const totalSupplyAtDividendEvent = await s1Token.getTotalSupplyAtEventForDividendId(1)

      expect(totalBalanceOf.toNumber()).to.equal(1500597)
      expect(currentGlobalDividendEventId.toNumber()).to.equal(1)
      expect(dividendEventIdForAddress.toNumber()).to.equal(0)
      expect(dividendOwed.toNumber()).to.equal(597)
      expect(dividendAmount.toNumber()).to.equal(200000)
      expect(totalSupplyAtDividendEvent.toNumber()).to.equal(501700000)
    })
  })*/
})