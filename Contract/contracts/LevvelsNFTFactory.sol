// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract LevvelsNFTFactory is Ownable, ERC721Enumerable {

    struct TradingTime{
        uint32 openTime;
        uint32 closeTime;
    }
    event MintedEvent(uint indexed tokenId, address addr, string tokenURI);
    event PaybackedEvent(address addr, uint amount);
    event WithdrawEvent(address addr, uint amount);

    using Counters for Counters.Counter;
    Counters.Counter private tokenId; // tokenid 
    string public baseUri; // 토큰 URI 
    uint public immutable mintPrice; // 토큰 가격 
    uint32 public immutable maxSupply; // 최대 발행량
    uint32 public immutable totalWallet; // 지갑 갯수
    uint32 public antiBotInterval; // 안티봇 인터벌
    TradingTime public tradingTime; // 마켓 거래 시간
    mapping (uint => address) public withdrawIndex; // 인출 금액 Index
    mapping (address => uint) public withdrawWallet; // 인출 금액
    mapping (address => uint) private lastBlockTime; // 마지막 호출 번호

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _baseUri,
        uint32 _maxSupply,
        uint _mintPrice, 
        uint32 _openTime, 
        uint32 _closeTime, 
        address[] memory _withdrawWallet) ERC721(_tokenName, _tokenSymbol) {
            uint32 index = 0;
            maxSupply = _maxSupply;
            baseUri = _baseUri;
            mintPrice = _mintPrice; // wei형태로 부탁
            tradingTime.openTime = _openTime;
            tradingTime.closeTime = _closeTime;
            for(uint32 i =0 ; i< _withdrawWallet.length ; i++){
                withdrawIndex[i] = _withdrawWallet[i];
                withdrawWallet[_withdrawWallet[i]] = 0;
                index += 1;
            }
            totalWallet = index;
    }
    // 인터벌 간격 설정 
    function setAntiBotInterval(uint32 _interval) external{
        require(antiBotInterval == 0,"donot change");
        antiBotInterval = _interval;
    }

    // 구매
    function buyNFT(address sender) external payable onlyOwner { // 라우터만 호출 가능
        require(sender != address(0),"Address cannot be address 0"); 
        require(msg.value >= mintPrice,"not enough Amount");
        require(maxSupply > totalSupply(), "all levvelsNFTs are minted");
        require(block.timestamp >= tradingTime.openTime,"not TradingTime_1");
        require(block.timestamp <= tradingTime.closeTime || tradingTime.closeTime == 0,"not TradingTime_2"); 
        require(lastBlockTime[sender]+antiBotInterval < block.timestamp,"Bot is not allowed");

        // payback
        if(msg.value > mintPrice){
            uint payback = msg.value - mintPrice;
            (bool success,) = sender.call{value: payback}("");
            require(success, "payback_transfer_failed");
            emit PaybackedEvent(sender,payback);
        }

        // 수익금 분배 
        uint _payoff = mintPrice / totalWallet;
        for(uint i = 0 ; i < totalWallet ; i++ ){
            address account = withdrawIndex[i];
            withdrawWallet[account] += _payoff;
        }

        tokenId.increment();
        uint newItemId = tokenId.current();
        _mint(sender, newItemId);
        lastBlockTime[sender] = block.timestamp;
        emit MintedEvent(newItemId, sender, tokenURI(newItemId));
    }

    // 인출 
    function withdraw(address sender) external onlyOwner {
        require(sender != address(0),"Address cannot be address 0");
        require(withdrawWallet[sender] > 0 ,"Lack of withdrawable amount");
        
        uint amount = withdrawWallet[sender];
        (bool success,) = sender.call{value: amount}("");
        require(success, "withdraw_transfer_failed");
        delete withdrawWallet[sender];
        emit WithdrawEvent(sender,amount);
    }

    // 인출 조회 
    function getWithdraw(address sender) public view onlyOwner returns(uint) {
        require(sender != address(0),"Address cannot be address 0");
        return withdrawWallet[sender];
    }

    // URI 조회
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        _requireMinted(_tokenId);
        string memory baseURI = _baseURI();
        return baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

}
