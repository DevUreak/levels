const assert = require('chai').assert;
const Web3 = require('web3');
const levelsContract = artifacts.require('../contracts/LevelsNFT');

const web3 = new Web3();
let levlesNFT;
web3.setProvider(new Web3.providers.HttpProvider('http://127.0.0.1:7545')); //로컬로 테스트 

contract("LevelsNFT",() =>{
    before("setting deployed", async ()=>{
        levlesNFT = await levelsContract.deployed();
    })


    describe("[Levels Trading Test]", async() =>{

        it("getTest",async ()=>{
            const value = await levlesNFT.getTest();
            assert.ok(value.toString() === "11", "init Value reject")
        });

    });




}) 