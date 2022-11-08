import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

import { createPluginRepo } from "../helpers";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  console.log(`\nCreating plugin repos.`);

  console.warn(
    "Please make sure pluginRepo is not created more than once with the same name."
  );

  await createPluginRepo(
    hre,
    "CounterV1",
    "CounterV1PluginSetup",
    [0, 1, 0],
    "0x"
  );
};
export default func;
func.tags = ["Create_Register_Plugins"];
