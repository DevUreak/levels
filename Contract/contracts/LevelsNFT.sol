// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "DateTime.sol";

contract LevelsNFT is Ownable, ERC721Enumerable {

    struct TradingTime{
        uint32 openTime;
        uint32 closeTime;
    }
    event Minted(uint indexed tokenId, address addr, string tokenURI);
    event Paybacked(address indexed addr, uint amount);
    event withdrew(address indexed addr, uint amount);

    using Counters for Counters.Counter;
    Counters.Counter private tokenId; // tokenid 
    string public baseUri; // 토큰 URI 
    uint public immutable mintPrice; // 토큰 가격 
    uint32 public immutable maxSupply; // 최대 발행량
    uint32 public immutable totalWallet; // 지갑 갯수
    uint32 public constant DECIMALS = 18;
    uint32 public antiBotInterval; // 안티봇 인터벌
    TradingTime public tradingTime; // 마켓 거래 시간
    //mapping (uint => string) public tokenURIs; // tokenuris
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
            mintPrice = _mintPrice;
            tradingTime.openTime = _openTime;
            tradingTime.closeTime = _closeTime;
            for(uint32 i =0 ; i< _withdrawWallet.length ; i++){
                withdrawIndex[i] = _withdrawWallet[i];
                withdrawWallet[_withdrawWallet[i]] = 0;
                index += 1;
            }
            totalWallet = index;
    }
    function setAntiBotInterval(uint32 _interval) external onlyOwner{
        require(antiBotInterval == 0,"donot change");
        antiBotInterval = _interval;
    }

    // 구매
    function mintLevelsNFT() external payable {
        require(msg.sender != address(0),"Address cannot be address 0");
        require(msg.value >= mintPrice*(10**DECIMALS),"not enough Amount");
        require(maxSupply > totalSupply(), "all levelsNFTs are minted");
        require(block.timestamp >= tradingTime.openTime,"not TradingTime_1");
        require(block.timestamp <= tradingTime.closeTime || tradingTime.closeTime == 0,"not TradingTime_2"); 
        require(lastBlockTime[msg.sender]+antiBotInterval < block.timestamp,"Bot is not allowed");

        // payback
        if(msg.value > mintPrice*(10**DECIMALS)){
            uint payback = msg.value - mintPrice*(10**DECIMALS);
            (bool success,) = msg.sender.call{value: payback}("");
            require(success, "payback_transfer_failed");
            emit Paybacked(msg.sender,payback);
        }

        // 수익금 분배 
        uint _payoff = mintPrice*(10**DECIMALS) / totalWallet;
        for(uint i = 0 ; i < totalWallet ; i++ ){
            address account = withdrawIndex[i];
            withdrawWallet[account] += _payoff;
        }

        tokenId.increment();
        uint newItemId = tokenId.current();
        _mint(msg.sender, newItemId);
        lastBlockTime[msg.sender] = block.timestamp;
        emit Minted(newItemId, msg.sender, tokenURI(newItemId));
    }

    // 인출 
    function withdraw() external {
        require(msg.sender != address(0),"Address cannot be address 0");
        require(withdrawWallet[msg.sender] > 0 ,"Lack of withdrawable amount");
        
        uint amount = withdrawWallet[msg.sender];
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "withdraw_transfer_failed");
        delete withdrawWallet[msg.sender];
        emit withdrew(msg.sender,amount);
    }

    // 인출 조회 
    function getWithdraw() public view returns(uint){
        require(msg.sender != address(0),"Address cannot be address 0");
        return withdrawWallet[msg.sender];
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        _requireMinted(_tokenId);
        string memory baseURI = _baseURI();
        return baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

}
