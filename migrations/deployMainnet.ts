import { ethers } from "hardhat";
import chalk from "chalk";
import { AddressLike } from "ethers";
import { getVersion, verify } from "@skalenetwork/upgrade-tools";
import { deployAccessManager, deployCreditStation, storeAddresses, successCode, failureCode, transferOwnership } from "./deploy";

const OWNER_PARAMETER = "OWNER";
const RECEIVER_PARAMETER = "RECEIVER";
const SOURCE_ID_PARAMETER = "SOURCE_ID";
const ID_OFFSET_PARAMETER = "ID_OFFSET";

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

    if (process.env[OWNER_PARAMETER]) {
        console.log(chalk.gray(`OWNER is set to ${owner}`));
    } else {
        console.log(chalk.yellow(`OWNER is not set`));
        console.log(chalk.yellow(`Using deployer address: ${owner}`));
    }
    if (process.env[RECEIVER_PARAMETER]) {
        console.log(chalk.gray(`RECEIVER is set to ${receiver}`));
    } else {
        console.log(chalk.yellow(`RECEIVER is not set`));
        console.log(chalk.yellow(`Using deployer address: ${receiver}`));
    }
    if (process.env[SOURCE_ID_PARAMETER] && process.env[ID_OFFSET_PARAMETER]) {
        console.log(chalk.gray(`SOURCE_ID is set to ${process.env[SOURCE_ID_PARAMETER]}`));
        console.log(chalk.gray(`ID_OFFSET is set to ${process.env[ID_OFFSET_PARAMETER]}`));
    } else if (!process.env[SOURCE_ID_PARAMETER] && !process.env[ID_OFFSET_PARAMETER]) {
        console.log(chalk.yellow(`SOURCE_ID and ID_OFFSET are not set, skipping payment ID offset`));
    }

    const { accessManager, creditStation } = await deployMainnet(deployer, receiver, await getVersion());

    console.log(chalk.gray("Storing addresses"));
    await storeAddresses(
        ["CreditStationAccessManager", "CreditStation"],
        [accessManager, creditStation],
        "mainnet"
    );

    if (await ethers.resolveAddress(deployer) !== await ethers.resolveAddress(owner)) {
        console.log("Setup permissions");
        await transferOwnership(accessManager, deployer, owner);
    }

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
