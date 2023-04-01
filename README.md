## 사용 기술
  - Truffle  
  - Solidity  
  - openzeppelin

## 테스트 환경 
- ganache

## 실행 방법 
```
git clone git@github.com:DevUreak/levvels.git
cd Contract 
npm install 
truffle console --network development
compile --all 
test
```

## 로컬 배포시 확인 사항 
truffle-config.json port, ip, network_id 확인 및 수정


## 요구 기능 
- NFT 구매 기능 
- NFT 수익 인출 기능 
- NFT 수익 인출 조회 기능 
- 구매,인출 테스트 구현

## 추가 기능 
- Factory 형태로 구현 
- Bot 방지 시스템 

## 기능 설명 
- Router를 통해서만 필수 LevvelsNFT 구매,수익 함수를 수행  
- Router 
    * CreateLevvelsNFT
      + Levvels 브랜드의 NFT를 생성
      + 생성될때 이벤트를 통해 API key와 컨트랙트 주소를 반환

    * _buyNFT
      + 해당 브랜드의 NFT를 구매 

    * _withdraw
      + 등록된 지갑에서 자신의 수익을 인출
 
    * _getWithdraw
      + 등록된 지갑에서 자신의 출금가능한 수익을 조회

    * _tokenURI
      + 해당 브랜드의 tokenURI를 조회

커밋 테스트 ~ 