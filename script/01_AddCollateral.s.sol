// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.12;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {DssDeploy} from "src/DssDeploy.sol";
import {GemJoin} from "dss/join.sol";
import {Clipper} from "dss/clip.sol";
import {DSToken} from "ds-token/token.sol";

contract SimplePip {
    bytes32 private val;

    function set(uint256 wad) external {
        val = bytes32(wad);
    }

    function peek() external view returns (bytes32, bool) {
        return (val, true);
    }
}

contract AddCollateral is Script {
    function run() external {
        // Required env
        address dssDeployAddr = vm.envAddress("DSS_DEPLOY");
        uint256 PRICE = vm.envUint("PRICE"); // e.g. 1e18 = $1.00

        // Constants
        bytes32 ILK = vm.envBytes32("ILK");
        uint256 ONE_MILLION = 1_000_000 ether;

        vm.startBroadcast();

        // 1) Deploy ERC-20 (DSToken) and mint to deployer
        // DSToken wXRP = new DSToken("wXRP");
        // wXRP.setName("Wrapped XRP");
        // wXRP.mint(msg.sender, ONE_MILLION);

        // 2) Deploy a simple price feed (pip) and set the initial price
        SimplePip pip = new SimplePip();
        pip.set(PRICE);

        // 3) Get core addresses from DssDeploy
        DssDeploy deploy = DssDeploy(dssDeployAddr);

        // 4) Deploy GemJoin for the new collateral
        GemJoin join = new GemJoin(
            address(deploy.vat()),
            ILK,
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
        );

        // 5) Allow GemJoin to be trusted by the Vat via DssDeploy step call
        //    and finish wiring the ilk via deployCollateralClip (uses Dog + Clipper path)
        deploy.deployCollateralClip(
            ILK,
            address(join),
            address(pip),
            address(0)
        );

        // Log addresses to paste into .envrc
        console2.log("TOKEN=", 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
        console2.log("JOIN=", address(join));
        console2.log("PIP=", address(pip));
        // Read back clip from the deployer mapping
        (, Clipper clip, ) = deploy.ilks(ILK);
        console2.log("CLIP=", address(clip));

        vm.stopBroadcast();
    }
}
