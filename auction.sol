// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title AdvancedAuction
 * @dev Auction contract with advanced rules, deposits, refunds, and events.
 */
contract AdvancedAuction {
    address public owner;
    uint256 public endTime;
    bool public finalized;
    uint256 public commission = 2; // 2%
    uint256 public highestBid;
    address public highestBidder;

    struct Bid {
        address bidder;
        uint256 amount;
    }

    Bid[] public bids;
    mapping(address => uint256[]) public userBidHistory; // Amounts bid by user
    mapping(address => uint256) public deposits; // Total deposited by user
    mapping(address => uint256) public pendingRefunds; // Available partial refunds

    event NewBid(address indexed bidder, uint256 amount, uint256 timeLeft);
    event AuctionFinalized(address winner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can execute this");
        _;
    }

    modifier auctionActive() {
        require(block.timestamp < endTime && !finalized, "The auction is not active");
        _;
    }

    modifier auctionFinalized() {
        require(finalized, "The auction has not been finalized");
        _;
    }

    constructor(uint256 _durationMinutes) {
        require(_durationMinutes > 0, "Duration must be greater than 0");
        owner = msg.sender;
        endTime = block.timestamp + (_durationMinutes * 1 minutes);
        finalized = false;
    }

    /**
     * @dev Allows to place a bid. The bid must be at least 5% higher than the current highest bid.
     * If the bid is placed within the last 10 minutes, the auction is extended by 10 minutes.
     */
    function placeBid() external payable auctionActive {
        require(msg.value > 0, "You must send ETH to place a bid");
        uint256 minBid = highestBid == 0 ? 0 : highestBid + (highestBid * 5 / 100);
        require(msg.value >= minBid, "The bid must be at least 5% higher than the current highest bid");

        // Register bid and deposit
        bids.push(Bid(msg.sender, msg.value));
        userBidHistory[msg.sender].push(msg.value);
        deposits[msg.sender] += msg.value;

        // Partial refund: if the user already had previous bids, they can withdraw the excess
        if (userBidHistory[msg.sender].length > 1) {
            uint256 refund = 0;
            // Sum all previous bids except the last one
            for (uint256 i = 0; i < userBidHistory[msg.sender].length - 1; i++) {
                refund += userBidHistory[msg.sender][i];
            }
            pendingRefunds[msg.sender] = refund;
        }

        // Update highest bid and highest bidder
        highestBid = msg.value;
        highestBidder = msg.sender;

        // Extend auction if less than 10 minutes remain
        if (endTime - block.timestamp <= 10 minutes) {
            endTime += 10 minutes;
        }

        emit NewBid(msg.sender, msg.value, endTime - block.timestamp);
    }

    /**
     * @dev Allows to withdraw the partial refund from previous bids.
     */
    function withdrawPartialRefund() external {
        uint256 amount = pendingRefunds[msg.sender];
        require(amount > 0, "You have no pending refunds");
        pendingRefunds[msg.sender] = 0;
        deposits[msg.sender] -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Refund transfer failed");
    }

    /**
     * @dev Finalizes the auction. Only the owner can call this function.
     */
    function finalizeAuction() public onlyOwner auctionActive {
        require(block.timestamp >= endTime, "The auction has not ended yet");
        finalized = true;
        emit AuctionFinalized(highestBidder, highestBid);
    }

    /**
     * @dev Allows users to withdraw their deposit if they are not the winner.
     * The winner can withdraw the remaining balance minus the commission.
     */
    function withdrawDeposit() external auctionFinalized {
        require(msg.sender != highestBidder || deposits[msg.sender] > highestBid, "The winner can only withdraw the remaining balance");
        uint256 amount = deposits[msg.sender];

        // If winner, can only withdraw the remaining balance
        if (msg.sender == highestBidder) {
            uint256 remaining = amount > highestBid ? amount - highestBid : 0;
            require(remaining > 0, "No remaining balance to withdraw");
            deposits[msg.sender] = highestBid; // Only the winning bid remains
            (bool success, ) = payable(msg.sender).call{value: remaining}("");
            require(success, "Remaining balance transfer failed");
        } else {
            require(amount > 0, "You have no deposit to withdraw");
            deposits[msg.sender] = 0;
            (bool success, ) = payable(msg.sender).call{value: amount}("");
            require(success, "Deposit transfer failed");
        }
    }

    /**
     * @dev The owner withdraws the commission and the winning amount.
     */
    function withdrawFunds() external onlyOwner auctionFinalized {
        uint256 commissionAmount = highestBid * commission / 100;
        uint256 winnerAmount = highestBid - commissionAmount;
        require(address(this).balance >= winnerAmount + commissionAmount, "Insufficient funds");
        (bool success1, ) = payable(owner).call{value: winnerAmount}("");
        require(success1, "Winner amount transfer failed");
        (bool success2, ) = payable(owner).call{value: commissionAmount}("");
        require(success2, "Commission transfer failed");
    }

    /**
     * @dev Returns the winner and the highest bid.
     */
    function getWinner() public view returns (address, uint256) {
        return (highestBidder, highestBid);
    }

    /**
     * @dev Returns the list of all bids.
     */
    function getBids() public view returns (Bid[] memory) {
        return bids;
    }

    /**
     * @dev Returns the bid history of a user.
     */
    function getUserBidHistory(address user) public view returns (uint256[] memory) {
        return userBidHistory[user];
    }

    /**
     * @dev Returns the remaining time of the auction.
     */
    function getTimeLeft() public view returns (uint256) {
        if (block.timestamp >= endTime) {
            return 0;
        }
        return endTime - block.timestamp;
    }

    // Fallback to receive ETH
    receive() external payable {}
}