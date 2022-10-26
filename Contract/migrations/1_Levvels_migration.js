// const levvelsNFT = artifacts.require("LevvelsNFT");
// const dateTime = artifacts.require("DateTime");
// const TokenURL = "https://ipfs.io/ipfs/QmSypbjJ2RC1F74RMB6EoyyihWAD3bRygFiG4pfQpGsNZV"
const Router = artifacts.require("Router");
module.exports = async function (deployer,network){

    if(network == "development"){
        //let routerCont;
        await deployer.deploy(Router);
    }
    //nftCont = await levvelsNFT.deployed();
    // await nftCont.getTest().then(result => {
    //     //console.log(result);
    // });

    // await nftCont.getTest().then(result => {
    //     //console.log(result);
    // });

}