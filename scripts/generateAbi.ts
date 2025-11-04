import {promises as fs} from 'fs';
import { contracts } from '../migrations/deploy.js';
import { network } from "hardhat";
import { getVersion } from './upgrade-tools-stub/version.js';
import { getAbi } from './upgrade-tools-stub/abi.js';
const { ethers } = await network.connect();

type ABI = {[name: string]: []}

const saveToFile = async (abi: ABI) => {
    const version = await getVersion();
    const filename = `data/fair-manager-${version}-abi.json`;
    console.log(`Save to ${filename}`)
    const indent = 4;
    await fs.writeFile(filename, JSON.stringify(abi, null, indent));
}

const main = async () => {
    const allContracts = contracts;
    const abi: ABI = {};
    const factories = Object.fromEntries(await Promise.all(
        allContracts.map(
            async (contractName) => {
                console.log(`Compile ${contractName}`);
                return [contractName, await ethers.getContractFactory(contractName)]
            }
        )
    ));
    for (const contractName of allContracts) {
        console.log(`Load ABI of ${contractName}`);
        abi[contractName] = getAbi(factories[contractName].interface);
    }
    await saveToFile(abi);
}


const successCode = 0;
const failureCode = 1;
main()
    .then(() => process.exit(successCode))
    .catch(error => {
        console.error(error);
        process.exit(failureCode);
    });
