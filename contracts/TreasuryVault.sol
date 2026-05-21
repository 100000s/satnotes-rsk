// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IEscrowController {
    function collateralRatio()
        external
        view
        returns (uint256);

    function syncEscrowBalance(
        uint256 newBalance
    ) external;
}

contract TreasuryVault is
    Ownable,
    ReentrancyGuard
{
    // =========================
    // EXTERNAL CONTRACTS
    // =========================

    IEscrowController
        public escrowController;

    // =========================
    // COLLATERAL CONSTANTS
    // =========================

    uint256 public constant
        MIN_COLLATERAL_RATIO = 10500;

    // =========================
    // BUDGET POOLS
    // =========================

    uint256 public appTeamBudget;
    uint256 public atmTeamBudget;
    uint256 public noteTeamBudget;

    uint256 public finderFeePool;
    uint256 public subsidyPool;
    uint256 public bugBountyPool;

    // =========================
    // OPERATOR POOLS
    // =========================

    uint256 public atmOperatorPool;

    // =========================
    // EVENTS
    // =========================

     event FundsReceived(
        address indexed sender,
        uint256 amount
    );

    event RevenueProcessed(
        string revenueType,
        uint256 amount
    );

    event EscrowFunded(
        uint256 amount
    );

    // =========================
    // CONSTRUCTOR
    // =========================

 constructor(address _escrow)
    {
        escrowController =
            IEscrowController(_escrow);
    }

    // =========================
    // RECEIVE RBTC
    // =========================

    receive() external payable {
        emit FundsReceived(
            msg.sender,
            msg.value
        );
    }

    // =========================
    // COLLATERAL CHECK
    // =========================

 function collateralHealthy()
        public
        view
        returns (bool)
    {
        return
            escrowController
                .collateralRatio()
            >= MIN_COLLATERAL_RATIO;
    }

    // =========================
    // AUCTION REVENUE
    // =========================

function processAuctionRevenue()
        external
        payable
        onlyOwner
    {
        uint256 escrowAmount =
            (msg.value * 90) / 100;

        uint256 noteAmount =
            msg.value - escrowAmount;

        noteTeamBudget += noteAmount;

        escrowController
            .syncEscrowBalance(
                address(this).balance
            );

        emit EscrowFunded(
            escrowAmount
        );

        emit RevenueProcessed(
            "Auction",
            msg.value
        );
    }

    // =========================
    // APP REVENUE
    // =========================


 function processAppRevenue()
        external
        payable
        onlyOwner
    {
        uint256 escrowPortion;

        if (!collateralHealthy()) {
            escrowPortion =
                (msg.value * 75) / 100;
        }

        uint256 remaining =
            msg.value - escrowPortion;

        uint256 appAmount =
            (remaining * 75) / 100;

        uint256 atmDaoAmount =
            (remaining * 20) / 100;

        uint256 publicAmount =
            remaining
            - appAmount
            - atmDaoAmount;

       appTeamBudget += appAmount;

        atmTeamBudget += atmDaoAmount;

        allocatePublicFunds(
            publicAmount
        );

        escrowController
            .syncEscrowBalance(
                address(this).balance
            );

        emit RevenueProcessed(
            "App",
            msg.value
        );
    }

    // =========================
    // NOTE AD REVENUE
    // =========================

    function processNoteAdRevenue()
        external
        payable
        onlyOwner
    {
        uint256 escrowPortion;

        if (!collateralHealthy()) {
            escrowPortion =
                (msg.value * 50) / 100;
        }

        uint256 remaining =
            msg.value - escrowPortion;

        uint256 operatorAmount =
            (remaining * 70) / 100;

        uint256 daoAmount =
            (remaining * 20) / 100;

        uint256 publicAmount =
            remaining
            - operatorAmount
            - daoAmount;

            atmOperatorPool +=
            operatorAmount;

        atmTeamBudget += daoAmount;

        allocatePublicFunds(
            publicAmount
        );

        escrowController
            .syncEscrowBalance(
                address(this).balance
            );

        emit RevenueProcessed(
            "NoteAds",
            msg.value
        );
    }

    // =========================
    // ATM AD REVENUE
    // =========================
 function processAtmAdRevenue()
        external
        payable
        onlyOwner
    {
        uint256 escrowPortion;

        if (!collateralHealthy()) {
            escrowPortion =
                (msg.value * 25) / 100;
        }

        uint256 remaining =
            msg.value - escrowPortion;

        uint256 operatorAmount =
            (remaining * 75) / 100;

        uint256 appDaoAmount =
            (remaining * 20) / 100;

        uint256 publicAmount =
            remaining
            - operatorAmount
            - appDaoAmount;

        atmOperatorPool +=
            operatorAmount;

      appTeamBudget += appDaoAmount;

        allocatePublicFunds(
            publicAmount
        );

        escrowController
            .syncEscrowBalance(
                address(this).balance
            );

        emit RevenueProcessed(
            "ATMAds",
            msg.value
        );
    }

    // =========================
    // PUBLIC FUND SPLITS
    // =========================

    function allocatePublicFunds(
        uint256 amount
    ) internal {
        finderFeePool +=
            (amount * 33) / 100;

        subsidyPool +=
            (amount * 33) / 100;

        bugBountyPool +=
            amount
            - ((amount * 33) / 100)
            - ((amount * 33) / 100);
    }
}