# AdvancedAuction

A smart contract for an advanced auction system on Ethereum.

## 📦 Variables

- **owner**: `address`  
  The address of the contract owner (auction creator).

- **endTime**: `uint256`  
  The timestamp when the auction ends.

- **finalized**: `bool`  
  Indicates whether the auction has been finalized.

- **commission**: `uint256`  
  The commission percentage (default: 2%).

- **highestBid**: `uint256`  
  The current highest bid in the auction.

- **highestBidder**: `address`  
  The address of the current highest bidder.

- **bids**: `Bid[]`  
  An array containing all bids (each with bidder address and amount).

- **userBidHistory**: `mapping(address => uint256[])`  
  Stores the bid history (amounts) for each user.

- **deposits**: `mapping(address => uint256)`  
  The total amount deposited by each user.

- **pendingRefunds**: `mapping(address => uint256)`  
  The amount available for partial refund for each user.

## 🛠️ Functions

- **constructor(uint256 _durationMinutes)**  
  Initializes the auction with a specified duration in minutes.

- **placeBid() external payable**  
  Allows users to place a bid. The bid must be at least 5% higher than the current highest bid. If the bid is placed within the last 10 minutes, the auction is extended by 10 minutes.

- **withdrawPartialRefund() external**  
  Allows users to withdraw the partial refund from their previous bids.

- **finalizeAuction() public onlyOwner auctionActive**  
  Finalizes the auction. Only the owner can call this function, and only after the auction has ended.

- **withdrawDeposit() external auctionFinalized**  
  Allows users to withdraw their deposit if they are not the winner. The winner can withdraw the remaining balance minus the commission.

- **withdrawFunds() external onlyOwner auctionFinalized**  
  Allows the owner to withdraw the commission and the winning amount after the auction is finalized.

- **getWinner() public view returns (address, uint256)**  
  Returns the address of the highest bidder and the highest bid.

- **getBids() public view returns (Bid[] memory)**  
  Returns the list of all bids.

- **getUserBidHistory(address user) public view returns (uint256[] memory)**  
  Returns the bid history of a specific user.

- **getTimeLeft() public view returns (uint256)**  
  Returns the remaining time for the auction.

## 📢 Events

- **NewBid(address indexed bidder, uint256 amount, uint256 timeLeft)**  
  Emitted when a new bid is placed.

- **AuctionFinalized(address winner, uint256 amount)**  
  Emitted when the auction is finalized.

---

## Example

```solidity
// Deploy the contract with a duration (in minutes)
AdvancedAuction auction = new AdvancedAuction(60);

// Place a bid (send ETH)
auction.placeBid{value: 1 ether}();

// Withdraw partial refund
auction.withdrawPartialRefund();

// Finalize the auction (only owner)
auction.finalizeAuction();

// Withdraw deposit (after auction finalized)
auction.withdrawDeposit();

// Owner withdraws funds
auction.withdrawFunds();
```

---


