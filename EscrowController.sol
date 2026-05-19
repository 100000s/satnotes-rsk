// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract EscrowController is Ownable, Pausable {

    uint256 public totalEscrowed;
    uint256 public totalCirculating;

    uint256 public constant REQUIRED_RATIO = 105;
    uint256 public constant SURPLUS_RATIO = 120;

    bool public ecosystemDisabled;

    mapping(address => bool) public authorizedVaults;
    mapping(address => bool) public authorizedIssuers;

    event EscrowUpdated(
        uint256 totalEscrowed,
        uint256 totalCirculating
    );

    event EcosystemDisabled();

    event EcosystemEnabled();

    modifier onlyAuthorizedVault() {
        require(
            authorizedVaults[msg.sender],
            "Not authorized vault"
        );
        _;
    }

    modifier onlyAuthorizedIssuer() {
        require(
            authorizedIssuers[msg.sender],
            "Not authorized issuer"
        );
        _;
    }

    constructor() Ownable(msg.sender) {}

    function setAuthorizedVault(
        address vault,
        bool status
    ) external onlyOwner {
        authorizedVaults[vault] = status;
    }

    function setAuthorizedIssuer(
        address issuer,
        bool status
    ) external onlyOwner {
        authorizedIssuers[issuer] = status;
    }

    function increaseEscrow(
        uint256 amount
    ) external onlyAuthorizedVault {

        totalEscrowed += amount;

        emit EscrowUpdated(
            totalEscrowed,
            totalCirculating
        );

        _checkEcosystemHealth();
    }

    function decreaseEscrow(
        uint256 amount
    ) external onlyAuthorizedVault {

        require(
            totalEscrowed >= amount,
            "Insufficient escrow"
        );

        totalEscrowed -= amount;

        emit EscrowUpdated(
            totalEscrowed,
            totalCirculating
        );

        _checkEcosystemHealth();
    }

    function increaseCirculation(
        uint256 amount
    ) external onlyAuthorizedIssuer {

        totalCirculating += amount;

        emit EscrowUpdated(
            totalEscrowed,
            totalCirculating
        );

        _checkEcosystemHealth();
    }

    function decreaseCirculation(
        uint256 amount
    ) external onlyAuthorizedIssuer {

        require(
            totalCirculating >= amount,
            "Insufficient circulation"
        );

        totalCirculating -= amount;

        emit EscrowUpdated(
            totalEscrowed,
            totalCirculating
        );

        _checkEcosystemHealth();
    }

    function requiredEscrow()
        public
        view
        returns (uint256)
    {
        return (totalCirculating * REQUIRED_RATIO) / 100;
    }

    function surplusThreshold()
        public
        view
        returns (uint256)
    {
        return (totalCirculating * SURPLUS_RATIO) / 100;
    }

    function ecosystemHealthy()
        public
        view
        returns (bool)
    {
        return totalEscrowed >= requiredEscrow();
    }

    function ecosystemSurplus()
        public
        view
        returns (bool)
    {
        return totalEscrowed > surplusThreshold();
    }

    function disableEcosystem()
        internal
    {
        ecosystemDisabled = true;

        _pause();

        emit EcosystemDisabled();
    }

    function enableEcosystem()
        internal
    {
        ecosystemDisabled = false;

        _unpause();

        emit EcosystemEnabled();
    }

    function _checkEcosystemHealth()
        internal
    {
        if (!ecosystemHealthy()) {

            if (!ecosystemDisabled) {
                disableEcosystem();
            }

        } else {

            if (ecosystemDisabled) {
                enableEcosystem();
            }
        }
    }
}