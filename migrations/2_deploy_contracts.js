const WhitelistedStorage = artifacts.require('./WhitelistedStorage.sol')
const AlitheiaS1 = artifacts.require('./AlitheiaS1.sol')
const AlitheiaNonS1 = artifacts.require('./AlitheiaNonS1.sol')
const MasterAdmin = artifacts.require('./MasterAdmin.sol')
const Sector = artifacts.require('./Sector.sol')
const ProjectProxy = artifacts.require('./ProjectProxy.sol')
const ProjectDelegate = artifacts.require('./ProjectDelegate.sol')

const fs = require('fs')
const contractsOutputFile = 'build/contracts.json'
let jsonOutput = {}

module.exports = function(deployer) {
  let storage, s1Token, nonS1Token, masterAdmin

	deployer.then(() => {
    return WhitelistedStorage.new() 
	}).then((_storage) => {
    storage = _storage
    addToJSON("WhitelistedStorage", storage.address)
    return AlitheiaNonS1.new()
  }).then((_nonS1Token) => {
    nonS1Token = _nonS1Token
    addToJSON("NonS1Token", nonS1Token.address)
    return AlitheiaS1.new(nonS1Token.address)
  }).then((_s1Token) => {
    s1Token = _s1Token
    addToJSON("S1Token", s1Token.address)
    _project = deployProject(storage.address, s1Token.address, nonS1Token.address)
  }).then(() => {
    sector = Sector.new(storage.address, 1, s1Token.address, nonS1Token.address)
    addToJSON("Sector", sector.address)
  }).catch((err) => {
    console.error(err)
  })
}

function deployProject (
  storageAddress,
  s1TokenAddress,
  nonS1TokenAddress
) {
  console.log(`deploying contracts for project`)
  return ProjectDelegate.new(storageAddress).then((projectDelegate) => {
    console.log(`deployed project delegate: ${projectDelegate.address}`)
    addToJSON("Project Delegate", projectDelegate.address)
    return ProjectProxy.new(
      storageAddress,
      projectDelegate.address,
      s1TokenAddress,
      nonS1TokenAddress
    )
  })
  .then((projectProxy) => {
    console.log(`deployed project proxy instance: ${projectProxy.address}`)
    addToJSON("Project Proxy", projectProxy.address)
    return ProjectDelegate.at(projectProxy.address)
  })
}

function addToJSON (displayName, address) {
  console.log(`Adding ${displayName} to JSON with address ${address}`)
  jsonOutput[displayName] = address
  fs.writeFile(contractsOutputFile, JSON.stringify(jsonOutput, null, 2), function (err) {
    if (err) {
      return console.log(err)
    }
  })
}