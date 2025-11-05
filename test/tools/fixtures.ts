
import { network } from "hardhat";
import { deployMainnet } from "../../migrations/deployMainnet.js";
import { deploySchain } from "../../migrations/deploySchain.js";
const { ethers, networkHelpers } = await network.connect();

// Fixtures

const deployMainnetFixture = async () => {
    const [owner, receiver] = await ethers.getSigners();
    const contracts = await deployMainnet(owner, receiver);
    const token = await ethers.deployContract("Token", ["Test Token", "TTK"]);
    return { ...contracts, token };
}

const deploySchainFixture = async () => {
    const [owner] = await ethers.getSigners();
    const contracts = await deploySchain(owner);
    return contracts;
}

// External functions

export const cleanMainnetDeployment = async () => networkHelpers.loadFixture(deployMainnetFixture);
export const cleanSchainDeployment = async () => networkHelpers.loadFixture(deploySchainFixture);
