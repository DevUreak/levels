const cont_router = artifacts.require('../contracts/Router');
const cont_NFTFactory = artifacts.require('../contracts/LevelsNFTFactory');
const Web3 = require('web3');

let _router;
const tokenURI = "https://ipfs.io/ipfs/QmSypbjJ2RC1F74RMB6EoyyihWAD3bRygFiG4pfQpGsNZV";
const maxsupply = 1000;
const mintPrice = "0.5"; // ETH
const nowDate = parseInt(Date.now()/1000);
let withdrawWallet; // 지갑 목록

contract("Router_Test",(accounts) =>{
    before("Setting Deployed", async ()=>{
       _router = await cont_router.deployed();
       withdrawWallet = [accounts[0],accounts[1],accounts[2]];
    });

    describe("[#1 No market time limit. Miting Pirce : "+mintPrice+" ETH]", () =>{
        let contaddr; 
        it("NFT initialization",async ()=>{
            const result = await _router.CreateLevelsNFT(
                "LevelsNFT_1",
                "LFT1",
                tokenURI,
                maxsupply,
                Web3.utils.toWei(mintPrice,"ether"),
                0,
                0,
                withdrawWallet
            );
            assert.ok(result.receipt.status == true, "Transaction Fail");
            let log;
            for (var i = 0; i < result.receipt.logs.length; i++) {
                log = result.receipt.logs[i];
                if (log.event == "CreateNFT") 
                  break;
            }
            assert.ok(log.args.APIndex.toNumber() == 0 && log.args.contAddr != '', "Failed to parse event data for 'Create NFT");
            contaddr = log.args.contAddr;
        });
        
        it("NFT purchase: 0.5 ETH, non-refundable",async ()=>{
            const result = await _router._buyNFT(0,{
                value : Web3.utils.toWei(mintPrice,"ether"),
                from : accounts[0]
            })
            assert.ok(result.receipt.status == true,"buyNFT Transaction Fail");

            const contract = await cont_NFTFactory.at(contaddr);
            const owner = await contract.ownerOf(1);
            assert.ok(owner === accounts[0],"Donot have NFT");
        })

        it("NFT purchase: 1ETH, refundable",async ()=>{
            const result = await _router._buyNFT(0,{
                value : Web3.utils.toWei(String(1),"ether"), // 1 eth 
                from : accounts[1]
            })
            assert.ok(result.receipt.status == true, "buyNFT Transaction Fail");
            let event = await result.receipt.rawLogs.some(l => { 
                return l.topics[0] === Web3.utils.keccak256("PaybackedEvent(address,uint256)")
            });
            assert.ok(event,"Refund Fail")
        })

        it("Anti Bot interval Test",async ()=>{
            try{
                const tx = await _router._buyNFT(0,{
                    value : Web3.utils.toWei(mintPrice,"ether"),
                    from : accounts[1]
                })
                assert.ok(tx.receipt.status == false, "buyNFT Transaction Fail");
            }catch(err){
                assert(String(err.data.stack).includes("Bot is not allowed"),"Anti Bot Issue")
            }
        })
    });

    describe("[#2 Market opening and closing times are included. (ex.2022.11.01 ~ 2022.11.03) ]", () =>{
        it("Open Time Check",async ()=>{
            const tx = await _router.CreateLevelsNFT(
                "LevelsNFT_2",
                "LFT2",
                tokenURI,
                maxsupply,
                Web3.utils.toWei(mintPrice,"ether"),
                (nowDate+30),
                (nowDate+60),
                withdrawWallet
            );
            assert.ok(tx.receipt.status == true, "Transaction Fail");
            try{
                const tx_1 = await _router._buyNFT(1,{
                    value : Web3.utils.toWei(mintPrice,"ether"),
                    from : accounts[0]
                })
                assert.ok(tx_1.receipt.status == false,"buyNFT Transaction Fail");
            }catch(err){
                assert(String(err.data.stack).includes("TradingTime_1"),"Market Open Time Issue")
            }
        });

        it("Close Time Check",async ()=>{
            const tx = await _router.CreateLevelsNFT(
                "LevelsNFT_3",
                "LFT3",
                tokenURI,
                maxsupply,
                Web3.utils.toWei(mintPrice,"ether"),
                nowDate,
                (nowDate-60),
                withdrawWallet
            );
            assert.ok(tx.receipt.status == true, "Transaction Fail");
            try{
                const tx_1 = await _router._buyNFT(2,{
                    value : Web3.utils.toWei(mintPrice,"ether"),
                    from : accounts[0]
                })
                assert.ok(tx_1.receipt.status == false,"buyNFT Transaction Fail");
            }catch(err){
                assert(String(err.data.stack).includes("TradingTime_2"),"Market Close Time Issue")
            }
        });
    })

    describe("[#3 Withdraw Test ]", () =>{
        it("NFT minting ",async ()=>{
            const tx = await _router.CreateLevelsNFT(
                "LevelsNFT_4",
                "LFT4",
                tokenURI,
                maxsupply,
                Web3.utils.toWei(mintPrice,"ether"),
                0,
                0,
                withdrawWallet
            );
            assert.ok(tx.receipt.status == true, "Transaction Fail");

            const tx_1 = await _router._buyNFT(3,{
                value : Web3.utils.toWei(mintPrice,"ether"),
                from : accounts[0]
            })
            assert.ok(tx_1.receipt.status == true, "buyNFT Transaction Fail");
        })

        it("Withdrawable amount test",async ()=>{
            const tx = await _router._getWithdraw(3,{
                from : accounts[0]
            }) 
            assert.ok(tx > 0,"getWithdraw Transaction Fail_1");

            const tx_1 = await _router._getWithdraw(3,{
                from : accounts[1]
            }) 
            assert.ok(tx_1 > 0,"getWithdraw Transaction Fail_2");

            const tx_2 = await _router._getWithdraw(3,{
                from : accounts[2]
            }) 
            assert.ok(tx_2 > 0,"getWithdraw Transaction Fail_3");
            assert.ok(String(tx) === String(tx_1) && String(tx_1) === String(tx_2),"The revenue distribution is wrong")
        })

        it("Withdraw Test",async () =>{
            let befor,after;
            const tx_1 = await _router._getWithdraw(3,{
                from : accounts[1]
            }) 
            assert.ok(tx_1 > 0,"getWithdraw Transaction Fail");
            let balance = await web3.eth.getBalance(accounts[1]); 
            befor = String(Number(tx_1)+Number(balance)).substring(0,3);
  
            const tx_2 = await _router._withdraw(3,{
                from : accounts[1]
            }) 
            assert.ok(tx_2.receipt.status == true,"Withdraw Transaction Fail");
            after = String(await web3.eth.getBalance(accounts[1])).substring(0,3); 
            assert.ok(after === befor,"Withdrawal amount does not match");
        })
    })

})