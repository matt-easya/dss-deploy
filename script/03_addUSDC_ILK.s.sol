// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.12;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {DssDeploy} from "src/DssDeploy.sol";
import {AuthGemJoin5} from "dss-psm/join-5-auth.sol";

interface VatLike {
    function init(bytes32) external;
    function rely(address) external;
    function file(bytes32, bytes32, uint256) external;
}

interface SpotLike {
    function file(bytes32, bytes32, address) external;
    function file(bytes32, bytes32, uint256) external;
    function poke(bytes32) external;
}

interface JugLike {
    function init(bytes32) external;
    function file(bytes32, bytes32, uint256) external;
    function drip(bytes32) external returns (uint256);
}

contract SimplePip {
    bytes32 private val;

    function set(uint256 wad) external {
        val = bytes32(wad);
    }

    function peek() external view returns (bytes32, bool) {
        return (val, true);
    }
}

contract AddUSDCPSM is Script {
    function run() external {
        // Required env
        address dssDeployAddr = vm.envAddress("DSS_DEPLOY");
        address USDC_TOKEN = vm.envAddress("USDC_TOKEN");
        
        // Constants
        bytes32 ILK = vm.envBytes32("ILK_USDC");
        uint256 RAD = 10 ** 45;
        
        // PSM Parameters
        uint256 mat = 1e27; // 100% collateralization for PSM
        uint256 lineIlk = 5_000_000 * RAD; // 5m DAI debt ceiling
        uint256 dust = 0; // 0 DAI minimum (PSM should allow any size)
        uint256 duty = 0; // 0% stability fee for PSM

        vm.startBroadcast();

        // Get core addresses from DssDeploy
        DssDeploy deploy = DssDeploy(dssDeployAddr);
        VatLike vat = VatLike(address(deploy.vat()));
        SpotLike spotter = SpotLike(address(deploy.spotter()));
        JugLike jug = JugLike(address(deploy.jug()));

        // 1) Initialize the USDC ilk in Vat
        vat.init(ILK);

        // 2) Deploy the USDC GemJoin adapter
        AuthGemJoin5 join = new AuthGemJoin5(
            address(vat),
            ILK,
            USDC_TOKEN
        );
        
        // Authorize the GemJoin
        vat.rely(address(join));

        // 3) Set up oracle & risk params for PSM
        // Deploy oracle that always returns 1.0 USD
        SimplePip pip = new SimplePip();
        
        // Set oracle price to 1e27 (1.0 USD in ray)
        pip.set(1e27);
        
        // Set oracle
        spotter.file(ILK, "pip", address(pip));
        
        // Set 100% collateralization
        spotter.file(ILK, "mat", mat);
        
        // Initialize jug for the ilk
        jug.init(ILK);
        
        jug.drip(ILK);
        
        // Set debt ceiling
        vat.file(ILK, "line", lineIlk);
        
        // Set minimum vault debt
        vat.file(ILK, "dust", dust);
        
        // Update spot price
        spotter.poke(ILK);

        // Log addresses for .envrc
        console2.log("USDC_TOKEN=", USDC_TOKEN);
        console2.log("GEM_JOIN_USDC=", address(join));
        console2.log("PIP_USDC=", address(pip));

        vm.stopBroadcast();
    }
}
