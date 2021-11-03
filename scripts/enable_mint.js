const { ethers } = require("hardhat")
const fs = require("fs")
const hre = require("hardhat");

async function main() {
    const accounts = await hre.ethers.getSigners();
    const signer = accounts[0];

    const MaskContract = await hre.ethers.getContractFactory("RandomMask");
    const keyspace_addr = "0xd700a119D906e8e48f868F01865741Aca2718A17";
    const mask_addr = "0x988721B1350D549c2478664FAB3eCD5522A19908";
    const mask = new hre.ethers.Contract(mask_addr, MaskContract.interface, signer)

    let transactionResponse = await mask.addMinter(keyspace_addr);
    let receipt = await transactionResponse.wait(1);
    console.log("enable keyspace mint nft ability successed.");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
