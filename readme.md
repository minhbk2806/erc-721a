# Drippy Zombie 
## Guide : https://ethereum.org/en/developers/tutorials/how-to-write-and-deploy-an-nft/

## Tool : https://remix.ethereum.org/

## Step to pre-sale mint :  
- Deploy smart contract
- Set pause statue to "false" by function : setPaused(status bool)
- Set pre-sale stat time by function : setPreSaleStartTime(timestamp uint32) (epoch timestamp)
- Set white-list who can pre-sale mint : setWhitelist(whiteList address[])
- Presale mint by function : preSaleMint (pre-sale amount is 0.04 eth )
