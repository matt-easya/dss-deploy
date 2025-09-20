// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.12;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

interface VatLike {
    function file(bytes32, bytes32, uint256) external;

    function file(bytes32, uint256) external;

    function ilks(
        bytes32
    )
        external
        view
        returns (
            uint256 Art,
            uint256 rate,
            uint256 spot,
            uint256 line,
            uint256 dust
        );
}

interface SpotLike {
    function file(bytes32, bytes32, uint256) external;

    function poke(bytes32) external;
}

interface JugLike {
    function init(bytes32) external;

    function file(bytes32, bytes32, uint256) external;

    function drip(bytes32) external;
}

interface DogLike {
    function file(bytes32, bytes32, uint256) external;

    function file(bytes32, uint256) external;
}

contract InitIlk is Script {
    function run() external {
        bytes32 ILK = vm.envBytes32("ILK"); // e.g. bytes32("WXRP-A")
        address VAT = vm.envAddress("VAT");
        address SPOT = vm.envAddress("SPOT");
        address JUG = vm.envAddress("JUG");
        address DOG = vm.envAddress("DOG");

        // Parameters in Maker units
        uint256 RAY = 10 ** 27;
        uint256 RAD = 10 ** 45;

        // 150 percent LR
        uint256 mat = 150e25; // 1.50 * 1e27
        // Global line and ilk line
        uint256 lineIlk = 5_000_000 * RAD; // 5m DAI debt ceiling
        uint256 lineGlobal = 5_000_000 * RAD;

        // Minimum vault debt
        uint256 dust = 50 * RAD; // 50 DAI minimum

        vm.startBroadcast();

        // Stability fee
        JugLike(JUG).drip(ILK);

        // Liquidation ratio
        SpotLike(SPOT).file(ILK, "mat", mat);

        // Debt ceilings
        VatLike(VAT).file(ILK, "line", lineIlk);
        VatLike(VAT).file("Line", lineGlobal);

        // Dust
        VatLike(VAT).file(ILK, "dust", dust);

        // Dog hole limits, generous defaults
        DogLike(DOG).file("Hole", lineGlobal);
        DogLike(DOG).file(ILK, "hole", lineIlk);

        // Recompute spot from pip and par

        SpotLike(SPOT).poke(ILK);

        vm.stopBroadcast();
    }
}
