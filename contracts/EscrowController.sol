// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EscrowController is Ownable, Pausable {

    // =========================
    // SYSTEM SUPPLY TRACKING
    // =========================

    uint256 public totalDigitalSatNotes;
    uint256 public totalPhysicalSatNotes;
    uint256 public totalFaceValue;

    // =========================
    // ESCROW ACCOUNTING
    // =========================

    uint256 public escrowBalance;

    // 105% = 10500 basis points
    uint256 public constant MIN_COLLATERAL_RATIO = 10500;

    // =========================
    // SYSTEM STATE FLAGS
    // =========================

    bool public printersEnabled = true;

    constructor() {}

function collateralRatio() public view returns (uint256) {
    if (totalFaceValue == 0) return type(uint256).max;

    return (escrowBalance * 10000) / totalFaceValue;
}

function checkSystemHealth() public {
    if (collateralRatio() < MIN_COLLATERAL_RATIO) {
        printersEnabled = false;
        _pause();
    } else {
        printersEnabled = true;
        _unpause();
    }
}

function depositEscrow() external payable {
    escrowBalance += msg.value;
    checkSystemHealth();
}

function mintDigital(uint256 value) external onlyOwner {
    totalDigitalSatNotes += 1;
    totalFaceValue += value;
    checkSystemHealth();
}

function mintPhysical(uint256 value) external onlyOwner {
    totalPhysicalSatNotes += 1;
    totalFaceValue += value;
    checkSystemHealth();
}

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

// =========================
// FUTURE: TREASURY INTEGRATION HOOK
// =========================

address public treasuryVault;

function setTreasuryVault(address _vault) external onlyOwner {
    treasuryVault = _vault;
}

}