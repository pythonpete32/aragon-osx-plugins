import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  console.log(`\nDeploying plugins.`);

  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  await deploy("CounterV1PluginSetup", {
    from: deployer,
    args: [],
    log: true,
  });
};
export default func;
func.tags = ["CounterV1PluginSetup"];
