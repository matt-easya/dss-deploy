// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.12;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {Controller} from "src/Controller.sol";

interface DssDeployLike {
    function vat() external view returns (address);
    function daiJoin() external view returns (address);
    function dai() external view returns (address);
}

interface ControllerLike {
    function setCollateralConfig(bytes32, address, address, bytes32) external;
    function setDaiTokenId(bytes32) external;
    function setDaiToken(address) external;
    function setPsm(address, address) external;
}

contract DeployController is Script {
    function run() external {
        // Required env
        address dssDeployAddr = vm.envAddress("DSS_DEPLOY");
        address INTERCHAIN_TOKEN_SERVICE = vm.envAddress("ITS");
        address CDP_MANAGER = vm.envAddress("CDP_MANAGER");
        
        // Token IDs for interchain transfers (these would be set by Axelar)
        bytes32 XRP_TOKEN_ID = vm.envBytes32("XRP_TOKEN_ID");
        bytes32 DAI_TOKEN_ID = vm.envBytes32("DAI_TOKEN_ID");
        bytes32 USDC_TOKEN_ID = vm.envBytes32("USDC_TOKEN_ID");
        
        // Ilk names
        bytes32 XRP_ILK = vm.envBytes32("ILK"); // e.g., "WXRP-A"
        bytes32 USDC_ILK = vm.envBytes32("ILK_USDC"); // e.g., "USDC-A"
        
        vm.startBroadcast();

        // Get core addresses from DssDeploy
        DssDeployLike deploy = DssDeployLike(dssDeployAddr);
        address vat = deploy.vat();
        address daiJoin = deploy.daiJoin();
        address daiToken = deploy.dai();
        
        // Get addresses from previous deployments
        address USDC_JOIN = vm.envAddress("USDC_JOIN");
        address USDC_TOKEN = vm.envAddress("USDC_TOKEN");
        address PSM = vm.envAddress("PSM");

        // Deploy the Controller
        Controller controller = new Controller(
            INTERCHAIN_TOKEN_SERVICE,
            CDP_MANAGER,
            vat,
            daiJoin
        );

        // Configure the Controller
        ControllerLike controllerInterface = ControllerLike(address(controller));
        
        // Set DAI token configuration
        controllerInterface.setDaiTokenId(DAI_TOKEN_ID);
        controllerInterface.setDaiToken(daiToken);
        
        // Set PSM configuration
        controllerInterface.setPsm(PSM, USDC_TOKEN);
        
        // Configure XRP collateral
        console2.log("Setting XRP config:");
        console2.log("  Ilk:", string(abi.encodePacked(XRP_ILK)));
        console2.log("  Token:", vm.envAddress("TOKEN"));
        console2.log("  Join:", vm.envAddress("JOIN"));
        console2.log("  Token ID:", uint256(XRP_TOKEN_ID));
        
        address xrpToken = vm.envAddress("TOKEN");
        address xrpJoin = vm.envAddress("JOIN");
        
        controllerInterface.setCollateralConfig(
            XRP_ILK,
            xrpToken,
            xrpJoin,
            XRP_TOKEN_ID
        );
        
        // Configure USDC collateral
        controllerInterface.setCollateralConfig(
            USDC_ILK,
            USDC_TOKEN,
            USDC_JOIN,
            USDC_TOKEN_ID
        );

        // Log addresses for .envrc
        console2.log("CONTROLLER=", address(controller));
        console2.log("INTERCHAIN_TOKEN_SERVICE=", INTERCHAIN_TOKEN_SERVICE);
        console2.log("XRP_TOKEN_ID=0x", uint256(XRP_TOKEN_ID));
        console2.log("DAI_TOKEN_ID=0x", uint256(DAI_TOKEN_ID));
        console2.log("USDC_TOKEN_ID=0x", uint256(USDC_TOKEN_ID));

        vm.stopBroadcast();
    }
}
