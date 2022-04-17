const Achievvecoin = artifacts.require("Achievvecoin");
const BUSD = artifacts.require("BUSD")
const LP = artifacts.require("LP")
const AMM = artifacts.require("AMM");


module.exports = function (deployer, network, accounts) {
  deployer.then(async () => {
    await deployer.deploy(Achievvecoin , 1000);
    await deployer.deploy(BUSD , 1000);
    await deployer.deploy(LP , 1000);
    await deployer.deploy(AMM, Achievvecoin.address , BUSD.address , LP.address);
  })
}
