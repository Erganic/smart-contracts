// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import { RoyaltyManager } from "../src/RoyaltyManager.sol";
import { IEAS } from "eas-contracts/IEAS.sol";
import { Attestation } from "eas-contracts/Common.sol";
import "forge-std/console.sol";

contract RoyaltyManagerTest is Test {
    RoyaltyManager public manager;
    IEAS public eas;

    function setUp() public {
        uint256 forkId = vm.createFork("sepolia");
        vm.selectFork(forkId);
        manager = new RoyaltyManager(0xC2679fBD37d54388Ce493F1DB75320D236e1815e, 0x51fCe89b9f6D4c530698f181167043e1bB4abf89);
        eas = IEAS(0xC2679fBD37d54388Ce493F1DB75320D236e1815e);
    }

    function testDataDecode() public {
        Attestation memory attestation = eas.getAttestation(0xbd6e229d68570631b6f0f87c95cef6e62b3bbf4fcbf3965892349fe4c1d6f069);
        (,,string memory license) = manager.decodeData(attestation.data);
        console.log("attestation.data", license);

    }
}
