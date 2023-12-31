// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IEAS } from "eas-contracts/IEAS.sol";
import { Attestation } from "eas-contracts/Common.sol";
import { IERC20 } from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";

/**
    @title Ergonomic
    @notice This contract handles the distribution of the royalties to the artists who have 
    contributed to the creation of purchased artwork.
*/

contract RoyaltyManager {

    IEAS public eas;
    IERC20 public token;

    /**
        @notice Mapping of the artists' addresses to their royalties.
    */
    mapping(address => uint256) public balance;

    /**
        @notice Event emitted when the user buys the license of the artwork.
        @param artworkId The uid of attestation record of the purhchased artwork.
        @param amount The price of the purchased artwork.
    */
    event LicensePurchased(bytes32 indexed artworkId, uint256 amount);

    /**
        @notice Event emitted when artist's balance is updated.
        @param artist The address of the artist.
        @param amount The amount of the royalties trasnferred to the artist.
        @param artworkId The uid of attestation record of the purchased artwork.
    */
    event BalanceUpdated(address indexed artist, uint256 amount, bytes32 indexed artworkId);

    /**
        @notice Event emitted when the artist withdraws their royalties.
        @param artist The address of the artist.
        @param amount The amount of the royalties.
    */
    event Withdraw(address indexed artist, uint256 amount);

    /**
        @notice Consturctor of this smart contract.
        @param _easAddress The address of the EAS smart contract.
        @param _tokenAddress The address of the token smart contract.
    */
    constructor(address _easAddress, address _tokenAddress) { 
        eas = IEAS(_easAddress);
        token = IERC20(_tokenAddress);
    }

    /**
        @notice The user will call this function to buy the license of the artwork. The function will 
        update the balances of all artisits who have contributed to the branch of the artwork.
        @param _artworkId The uid of attestation record of the purhchased artwork.
     */
    function buyLicense(bytes32 _artworkId, uint256 amount) external {
        Attestation memory attestation = eas.getAttestation(_artworkId);
        require(amount == _getPrice(attestation.data), "Invalid price");
        console.log("Amount passed correctly");
        uint256 tempAmount = amount;
        console.log("tempAmount: %d", tempAmount);
        emit LicensePurchased(_artworkId, amount);
        token.transferFrom(msg.sender, address(this), amount);
        console.log("Transfer successful");


        if (attestation.refUID == 0) {
            balance[attestation.attester] += tempAmount;
            emit BalanceUpdated(attestation.attester, tempAmount, _artworkId);
            return; // Exit the function after allocating funds to the attester
        }

        while (attestation.refUID != 0) {
            balance[attestation.attester] = tempAmount / 50;
            tempAmount = tempAmount / 50;
            _artworkId = attestation.refUID;
            attestation = eas.getAttestation(_artworkId);
            emit BalanceUpdated(attestation.attester, tempAmount, _artworkId);
        }
    }

    /**
        @notice Artist can call this function to withdraw all of their accumulated balance
        @param _artist The address of the artist
        @param _amount The amount of the balance to be withdrawn
     */
    function withdraw(address _artist, uint256 _amount) external {
        require(balance[_artist] >= _amount, "Insufficient balance");
        balance[_artist] -= _amount;
        token.transfer(_artist, _amount);
        emit Withdraw(_artist, _amount);
    }  

    /**
        @notice Helper function to get the price of the artwork from data tuple from Attestations sturct
        @param data The data tuple from Attestations sturct
     */
    function getPrice(bytes memory data) pure public returns(uint256){
        (,,uint256 price) = abi.decode(data, (string, string, uint256));
        return (price);
   }

   /**
        @notice Function that can be called by the frontned or users directly to get the balance of particular artist
        @param _artist The address of the artist
    */
    function getBalance(address _artist) external view returns(uint256) {
        return balance[_artist];
    }

}
