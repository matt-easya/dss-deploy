// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.12;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {DssDeploy, VatFab, JugFab, VowFab, CatFab, DogFab, DaiFab, DaiJoinFab, FlapFab, FlipFab, FlopFab, ClipFab, CalcFab, SpotFab, PotFab, CureFab, EndFab, ESMFab, PauseFab} from "src/DssDeploy.sol";

contract DeployDss is Script {
    function run() external {
        // Read required params from env
        address GOV = vm.envAddress("GOV");
        address AUTHORITY = vm.envAddress("AUTHORITY"); // or set to address(0)
        uint256 CHAIN_ID = vm.envUint("CHAIN_ID"); // e.g. 31337 or 1
        uint256 PAUSE_DELAY = vm.envUint("PAUSE_DELAY"); // e.g. 3600
        uint256 ESM_MIN = vm.envUint("ESM_MIN"); // e.g. 100000e18
        address EOA = vm.envAddress("EOA");
        uint256 GP = vm.envOr("GAS_PRICE_WEI", uint256(1_000_000_000)); // 1 gwei default
        vm.txGasPrice(GP);
        vm.startBroadcast();

        // Deploy core deployer and register fabs
        DssDeploy deploy = new DssDeploy();
        deploy.addFabs1(
            new VatFab(),
            new JugFab(),
            new VowFab(),
            new CatFab(),
            new DogFab(),
            new DaiFab(),
            new DaiJoinFab()
        );
        deploy.addFabs2(
            new FlapFab(),
            new FlopFab(),
            new FlipFab(),
            new ClipFab(),
            new CalcFab(),
            new SpotFab(),
            new PotFab(),
            new CureFab(),
            new EndFab(),
            new ESMFab(),
            new PauseFab()
        );

        // Execute deployment steps
        deploy.deployVat();
        deploy.deployDai(CHAIN_ID);
        deploy.deployTaxation();
        deploy.deployAuctions(GOV);
        deploy.deployLiquidator();
        deploy.deployEnd();
        deploy.deployPause(PAUSE_DELAY, AUTHORITY);
        deploy.deployESM(GOV, ESM_MIN);
        deploy.authEOA(EOA);

        // Log core addresses for .envrc
        console2.log("DSS_DEPLOY=", address(deploy));
        console2.log("VAT=", address(deploy.vat()));
        console2.log("JUG=", address(deploy.jug()));
        console2.log("VOW=", address(deploy.vow()));
        console2.log("CAT=", address(deploy.cat()));
        console2.log("DOG=", address(deploy.dog()));
        console2.log("DAI=", address(deploy.dai()));
        console2.log("DAI_JOIN=", address(deploy.daiJoin()));
        console2.log("FLAP=", address(deploy.flap()));
        console2.log("FLOP=", address(deploy.flop()));
        console2.log("SPOT=", address(deploy.spotter()));
        console2.log("POT=", address(deploy.pot()));
        console2.log("CURE=", address(deploy.cure()));
        console2.log("END=", address(deploy.end()));
        console2.log("ESM=", address(deploy.esm()));
        console2.log("PAUSE=", address(deploy.pause()));
        console2.log("PAUSE_PROXY=", address(deploy.pause().proxy()));

        vm.stopBroadcast();
    }
}
