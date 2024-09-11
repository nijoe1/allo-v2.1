// SPDX-License-Identifier = MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {TransparentUpgradeableProxy} from
    "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";

import {Allo} from "contracts/core/Allo.sol";
import {ContractFactory} from "contracts/factories/ContractFactory.sol";
import {DeployAllo} from "script/core/DeployAllo.sol";

contract DeployAlloWithFactory is DeployAllo {
    error NO_CONTRACT_FACTORY();

    function _deploy() internal override returns (address _contract, string memory _contractName) {
        (
            address owner,
            address registry,
            address treasury,
            uint256 percentFee,
            uint256 baseFee,
            address trustedForwarder,
            address proxyAdmin
        ) = _getAlloParams();

        address alloImplementation = address(new Allo());

        console.log("Contract: Allo implementation");
        console.log("Deployed contract at address: %s", alloImplementation);
        console.log("");

        if (proxyAdmin == address(0)) {
            ProxyAdmin admin = new ProxyAdmin();
            admin.transferOwnership(owner);
            proxyAdmin = address(admin);

            console.log("Contract name: ProxyAdmin");
            console.log("Deployed contract at address: %s", proxyAdmin);
            console.log("");
        }

        address factory = _getContractFactory();
        if (factory == address(0)) revert NO_CONTRACT_FACTORY();

        bytes memory creationCode = abi.encodePacked(
            type(TransparentUpgradeableProxy).creationCode,
            abi.encode(
                alloImplementation,
                proxyAdmin, // initial owner address for proxy admin
                abi.encodeCall(
                    Allo.initialize, (owner, registry, payable(treasury), percentFee, baseFee, trustedForwarder)
                )
            )
        );
        _contract = ContractFactory(factory).deploy("Allo", "v2.1", creationCode);
        _contractName = "Allo";
    }

    function _getContractFactory() internal view returns (address factory) {
        // Mainnet
        if (block.chainid == 1) {
            factory = 0xE195743480D1591B79106FF9B296A0cD38aDa807;
        }
        // Goerli
        else if (block.chainid == 5) {
            factory = 0xE195743480D1591B79106FF9B296A0cD38aDa807;
        }
        // Sepolia
        else if (block.chainid == 11155111) {
            factory = 0xE195743480D1591B79106FF9B296A0cD38aDa807;
        }
        // Optimism
        else if (block.chainid == 10) {
            factory = 0xE195743480D1591B79106FF9B296A0cD38aDa807;
        }
        // Optimism Goerli
        else if (block.chainid == 420) {
            factory = 0xE195743480D1591B79106FF9B296A0cD38aDa807;
        }
        // Celo Mainnet
        else if (block.chainid == 42220) {
            factory = 0xE195743480D1591B79106FF9B296A0cD38aDa807;
        }
        // Celo Testnet Alfajores
        else if (block.chainid == 44787) {
            factory = 0xE195743480D1591B79106FF9B296A0cD38aDa807;
        }
        // Polygon Mainnet
        else if (block.chainid == 137) {
            factory = 0xE195743480D1591B79106FF9B296A0cD38aDa807;
        }
        // Mumbai
        else if (block.chainid == 80001) {
            factory = 0xE195743480D1591B79106FF9B296A0cD38aDa807;
        }
        // Arbitrum One
        else if (block.chainid == 42161) {
            factory = 0xE195743480D1591B79106FF9B296A0cD38aDa807;
        }
        // Arbitrum Sepolia
        else if (block.chainid == 421614) {
            factory = 0xE195743480D1591B79106FF9B296A0cD38aDa807;
        }
        // Base Mainnet
        else if (block.chainid == 8453) {
            factory = 0xE195743480D1591B79106FF9B296A0cD38aDa807;
        }
        // Base Testnet Goerli
        else if (block.chainid == 84531) {
            factory = 0xE195743480D1591B79106FF9B296A0cD38aDa807;
        }
        // Optimism Sepolia
        else if (block.chainid == 11155420) {
            factory = 0xE195743480D1591B79106FF9B296A0cD38aDa807;
        }
        // Fuji
        else if (block.chainid == 43113) {
            factory = 0xE195743480D1591B79106FF9B296A0cD38aDa807;
        }
        // Avalanche Mainnet
        else if (block.chainid == 43114) {
            factory = 0xE195743480D1591B79106FF9B296A0cD38aDa807;
        }
        // Scroll
        else if (block.chainid == 534352) {
            factory = 0xE195743480D1591B79106FF9B296A0cD38aDa807;
        }
        // Fantom
        else if (block.chainid == 250) {
            factory = 0xE195743480D1591B79106FF9B296A0cD38aDa807;
        }
        // Fantom Testnet
        else if (block.chainid == 4002) {
            factory = 0xE195743480D1591B79106FF9B296A0cD38aDa807;
        }
        // ZkSync Mainnet
        else if (block.chainid == 324) {
            factory = 0x0000000000000000000000000000000000000000;
        }
        // ZkSync Sepolia Testnet
        else if (block.chainid == 300) {
            factory = 0x0000000000000000000000000000000000000000;
        }
        // Filecoin Mainnet
        else if (block.chainid == 314) {
            factory = 0x7DE1218DCDC3628F839b19a3aF5ACF092C35BcDE;
        }
        // Filecoin Calibration Testnet
        else if (block.chainid == 314159) {
            factory = 0x45181C4fD52d4d350380B3D42091b80065c702Ef;
        }
        // Sei Devnet
        else if (block.chainid == 713715) {
            factory = 0x7DE1218DCDC3628F839b19a3aF5ACF092C35BcDE;
        } else if (block.chainid == 1329) {
            factory = 0x7DE1218DCDC3628F839b19a3aF5ACF092C35BcDE;
        }
        // Lukso Mainnet
        else if (block.chainid == 42) {
            factory = 0x1133eA7Af70876e64665ecD07C0A0476d09465a1;
        }
        // Lukso Testnet
        else if (block.chainid == 4201) {
            factory = 0x7DE1218DCDC3628F839b19a3aF5ACF092C35BcDE;
        }
        // Local chain
        else if (block.chainid == 31337) {
            // For local test deployments set the ContractFactory address or modify this block to deploy the contract
            factory = 0x0000000000000000000000000000000000000000;
        } else {
            revert NETWORK_NOT_SUPPORTED();
        }
    }
}
