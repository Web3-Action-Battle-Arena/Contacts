module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();

  console.log(deployer);
  await deploy("Web3Arena1155", {
    from: deployer,
    args: [],
  });
};

module.exports.tags = ["Affiliate"];
