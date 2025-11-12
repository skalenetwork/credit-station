import { ethers } from "hardhat";
import chalk from "chalk";
import { AddressLike } from "ethers";
import { getVersion, verify } from "@skalenetwork/upgrade-tools";
import { deployAccessManager, deployCreditStation, storeAddresses, successCode, failureCode } from "./deploy";

const OWNER_PARAMETER = "OWNER";
const RECEIVER_PARAMETER = "RECEIVER";

export const deployMainnet = async (owner: AddressLike, receiver: AddressLike, version: string) => {
    const accessManager = await deployAccessManager(owner);
    const creditStation = await deployCreditStation(accessManager, receiver, version);
    return {
        accessManager,
        creditStation
    }
}

const main = async () => {
    const [deployer] = await ethers.getSigners();
    const owner = process.env[OWNER_PARAMETER] || await ethers.resolveAddress(deployer);
    const receiver = process.env[RECEIVER_PARAMETER] || await ethers.resolveAddress(deployer);

    if (!process.env[OWNER_PARAMETER]) {
        console.log(chalk.yellow(`OWNER is not set`));
        console.log(chalk.yellow(`Using deployer address: ${owner}`));
    }
    if (!process.env[RECEIVER_PARAMETER]) {
        console.log(chalk.yellow(`RECEIVER is not set`));
        console.log(chalk.yellow(`Using deployer address: ${receiver}`));
    }

    const { accessManager, creditStation } = await deployMainnet(owner, receiver, await getVersion());

    console.log(chalk.gray("Storing addresses"));
    await storeAddresses(
        ["CreditStationAccessManager", "CreditStation"],
        [accessManager, creditStation],
        "mainnet"
    );

    console.log("Verify");
    const coder = ethers.AbiCoder.defaultAbiCoder();
    await verify(
        "CreditStationAccessManager",
        accessManager,
        coder.encode(
            ["address"],
            [await ethers.resolveAddress(owner)]
        ).slice(2));

    await verify(
        "CreditStation",
        creditStation,
        coder.encode(
            ["address", "address"],
            [await ethers.resolveAddress(accessManager), await ethers.resolveAddress(receiver)]
        ).slice(2));

    console.log("Done");
}

if (require.main === module) {
    main()
        .then(() => process.exit(successCode))
        .catch(error => {
            console.error(error);
            process.exit(failureCode);
        });
}
