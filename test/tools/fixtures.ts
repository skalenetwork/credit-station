
import { network } from "hardhat";
import { deployMainnet } from "../../migrations/deployMainnet.js";
import { deploySchain } from "../../migrations/deploySchain.js";
const { ethers, networkHelpers } = await network.connect();

// Fixtures

const deployMainnetFixture = async () => {
    const [owner, receiver] = await ethers.getSigners();
    const contracts = await deployMainnet(owner, receiver, "test");
    const token = await ethers.deployContract("Token", ["Test Token", "TTK"]);
    return { ...contracts, token };
}

const deploySchainFixture = async () => {
    const [owner] = await ethers.getSigners();
    const contracts = await deploySchain(owner, "test");
    return contracts;
}

const allowToken = async () => {
    const contracts = await deployMainnetFixture();
    const { creditStation, token } = contracts;
    const price = ethers.parseEther("1");
    await creditStation.setPrice(token, price);
    return contracts;
}

const registerAgent = async () => {
    const contracts = await deploySchainFixture();
    const { accessManager } = contracts;
    const [, agent] = await ethers.getSigners();
    await accessManager.grantRole(
        await accessManager.FULFILL_AGENT_ROLE(),
        agent,
        0
    );
    return contracts;
}

// External functions

export const cleanMainnetDeployment = async () => networkHelpers.loadFixture(deployMainnetFixture);
export const cleanSchainDeployment = async () => networkHelpers.loadFixture(deploySchainFixture);
export const mainnetWithAllowedToken = async () => networkHelpers.loadFixture(allowToken);
export const schainWithAgent = async () => networkHelpers.loadFixture(registerAgent);
