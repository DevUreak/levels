// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./LevvelsNFTFactory.sol";

contract Router is Ownable {
    event CreateNFT(uint APIndex, address contAddr); // api호출 번호, 계약 주소

    mapping(string => uint32) private mintedName; // 만들어잔 토큰 네임 
    address[] private createdNFT;
    mapping(uint => address) public createdNFTAPI;

    //levvels NFT 생성
    function CreateLevvelsNFT(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _baseUri,
        uint32 _maxSupply,
        uint _mintPrice,
        uint32 _openTime,
        uint32 _closeTime,
        address[] memory _withdrawWallet) external onlyOwner{
            require(mintedName[_tokenName] == 0,"Already Token Name"); // 0없음 1있음 
        LevvelsNFTFactory object = new LevvelsNFTFactory(
            _tokenName,
            _tokenSymbol,
            _baseUri,
            _maxSupply,
            _mintPrice,
            _openTime,
            _closeTime,
            _withdrawWallet
        );
        uint num = createdNFT.length;
        object.setAntiBotInterval(60); //인터벌 설정
        mintedName[_tokenName] = 1;
        createdNFT.push(address(object)); // Add created NFT 
        createdNFTAPI[num] = address(object); // Add push API 
        emit CreateNFT(num, address(object)); //API Response data
    }

    // 구입 
    function _buyNFT(uint APIndex) public payable {
        address _APIndex = createdNFTAPI[APIndex];
        LevvelsNFTFactory(_APIndex).buyNFT{value:msg.value}(msg.sender);
    }
     // 인출  
    function _withdraw(uint APIndex) public payable {
        address _APIndex = createdNFTAPI[APIndex];
        LevvelsNFTFactory(_APIndex).withdraw(msg.sender);
    }

    // 인출 조회 
    function _getWithdraw(uint APIndex) public view returns(uint) {
        address _APIndex = createdNFTAPI[APIndex];
        uint result = LevvelsNFTFactory(_APIndex).getWithdraw(msg.sender);
        return result;
    }

    // URI 조회
    function _tokenURI(uint APIndex,uint tokenId) public view returns (string memory) {
        address _APIndex = createdNFTAPI[APIndex];
        string memory result = LevvelsNFTFactory(_APIndex).tokenURI(tokenId);
        return result;
    } 
    
}