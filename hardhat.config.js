require("dotenv").config();
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-ethers");
require("hardhat-deploy");
require("hardhat-deploy-ethers");

const PRIVATE_KEY =
  "c56ca8a7b51ecda7ee02bb11054789914a218c1d773cd9225d22df0325c1710c";

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.17",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },

  namedAccounts: {
    deployer: {
      default: 0,
    },
  },
  paths: {
    artifacts: "artifacts",
    cache: "cache",
    deploy: "deploy",
    deployments: "deployments",
    imports: "imports",
    sources: "contracts",
    tests: "test",
  },
  networks: {
    "cronos-testnet": {
      url: "https://evm-t3.cronos.org/",
      accounts: [PRIVATE_KEY],
    },
  },
};
