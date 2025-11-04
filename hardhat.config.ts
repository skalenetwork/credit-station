import hardhatToolboxMochaEthersPlugin from "@nomicfoundation/hardhat-toolbox-mocha-ethers";
import { configVariable, defineConfig } from "hardhat/config";

export default defineConfig({
  plugins: [hardhatToolboxMochaEthersPlugin],
  solidity: {
    version: "0.8.30",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      }
    }
  },
  networks: {
    custom: {
      type: "http",
      url: configVariable("ENDPOINT"),
      accounts: [configVariable("PRIVATE_KEY")]
    }
  },
  verify: {
    etherscan: {
      apiKey: configVariable("ETHERSCAN")
    }
  }
});
