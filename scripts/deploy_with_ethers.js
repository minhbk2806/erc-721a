async function main() {
    const DrippyZombies = await ethers.getContractFactory("DrippyZombies")
  
    // Start deployment, returning a promise that resolves to a contract object
    const myNFT = await DrippyZombies.deploy("abcd", "CND", "ddd", "dddd")
    await myNFT.deployed()
    console.log("Contract deployed to address:", myNFT.address)
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error)
      process.exit(1)
    })
  