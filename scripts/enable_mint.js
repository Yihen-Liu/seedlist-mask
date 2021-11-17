const { ethers } = require("hardhat")
const fs = require("fs")
const hre = require("hardhat");

async function main() {
    const accounts = await hre.ethers.getSigners();
    const signer = accounts[0];

    const MaskContract = await hre.ethers.getContractFactory("RandomMask");
    const encrypt_machine = "0x6d89587672fb830A6B9Fb66E665528A38779e4c1";
    const mask_addr = "0x96EAE123Ea4439D443042bD8699DE32a5940Ad5D";
    const mask = new hre.ethers.Contract(mask_addr, MaskContract.interface, signer)

    let transactionResponse = await mask.addMinter(encrypt_machine);
    let receipt = await transactionResponse.wait(1);
    console.log("enable encrypt machine mint nft ability successed.");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
