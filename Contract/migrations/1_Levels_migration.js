const levelsNFT = artifacts.require("LevelsNFT");
const dateTime = artifacts.require("DateTime");
const TokenURL = "https://ipfs.io/ipfs/QmSypbjJ2RC1F74RMB6EoyyihWAD3bRygFiG4pfQpGsNZV"
module.exports = async function (deployer){

    let nftCont;
    await deployer.deploy(levelsNFT,"111",11);
    await deployer.deploy(dateTime);
    nftCont = await levelsNFT.deployed();

    // await nftCont.getTest().then(result => {
    //     //console.log(result);
    // });

    // await nftCont.getTest().then(result => {
    //     //console.log(result);
    // });

}