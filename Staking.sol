//Be name khoda

pragma solidity 0.6.12;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

interface StakedToken {
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface RewardToken {
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);

}

contract Staking is Ownable {

	struct User {
		uint256 depositAmount;
		uint256 paidReward;
	}

	using SafeMath for uint256;
	
	mapping (address => User) public users;

	uint256 public rewardTillNowPerToken = 0;
	uint256 public lastUpdatedBlock;
	uint256 public rewardPerBlock;
	uint256 public scale = 1e18;
	address public daoAddress;

	StakedToken public stakedToken;
	RewardToken public rewardToken;

    event Deposit(address user, uint256 amount);
    event Withdraw(address user, uint256 amount);
    event EmergencyWithdraw(address user, uint256 amount);
	event RewardClaimed(address user, uint256 amount);
	
	constructor (address _stakedToken, address _rewardToken, uint256 _rewardPerBlock) public {
		stakedToken = StakedToken(_stakedToken);
		rewardToken = RewardToken(_rewardToken);
		rewardPerBlock = _rewardPerBlock;
		lastUpdatedBlock = block.number;
		daoAddress = msg.sender;
	}

	function setDaoAddress(address _daoAddress) public onlyOwner{
		daoAddress = _daoAddress;
	}

	// Update reward variables of the pool to be up-to-date.
	function update() public {
		if (block.number <= lastUpdatedBlock) {
			return;
		}
		uint256 totalStakedToken = stakedToken.balanceOf(address(this));
		uint256 rewardAmount = (block.number - lastUpdatedBlock).mul(rewardPerBlock);
		
		rewardTillNowPerToken = rewardTillNowPerToken.add(rewardAmount.mul(scale).div(totalStakedToken));
		lastUpdatedBlock = block.number;
    }

	// View function to see pending reward on frontend.
	function pendingReward(address _user) external view returns (uint256) {
		User storage user = users[_user];
		uint256 accRewardPerToken = rewardTillNowPerToken;
		
		if (block.number > lastUpdatedBlock) {
			uint256 totalStakedToken = stakedToken.balanceOf(address(this));
			uint256 rewardAmount = (block.number - lastUpdatedBlock).mul(rewardPerBlock);
            accRewardPerToken = accRewardPerToken.add(rewardAmount.mul(scale).div(totalStakedToken));
        }
        return user.depositAmount.mul(accRewardPerToken).div(scale).sub(user.paidReward);
	}

	function deposit(uint256 amount) public {
		User storage user = users[msg.sender];
        update();

        if (user.depositAmount > 0) {
            uint256 _pendingReward = user.depositAmount.mul(rewardTillNowPerToken).div(scale).sub(user.paidReward);
			rewardToken.transfer(msg.sender, _pendingReward);
			emit RewardClaimed(msg.sender, _pendingReward);
        }

		user.depositAmount = user.depositAmount.add(amount);
        user.paidReward = user.depositAmount.mul(rewardTillNowPerToken).div(scale);

		stakedToken.transferFrom(address(msg.sender), address(this), amount);
        emit Deposit(msg.sender, amount);
    }

	function withdraw(uint256 amount) public {
		User storage user = users[msg.sender];
        require(user.depositAmount >= amount, "withdraw amount exceeds deposited amount");
        update();

		uint256 _pendingReward = user.depositAmount.mul(rewardTillNowPerToken).div(scale).sub(user.paidReward);
		rewardToken.transfer(msg.sender, _pendingReward);
		rewardToken.transfer(daoAddress, _pendingReward.div(4));
		
		emit RewardClaimed(msg.sender, _pendingReward);


		user.depositAmount = user.depositAmount.sub(amount);
		stakedToken.transfer(address(msg.sender), amount);
        emit Withdraw(msg.sender, amount);
        
        user.paidReward = user.depositAmount.mul(rewardTillNowPerToken).div(scale);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
		User storage user = users[msg.sender];

		stakedToken.transfer(address(msg.sender), user.depositAmount);

        emit EmergencyWithdraw(msg.sender, user.depositAmount);

        user.depositAmount = 0;
        user.paidReward = 0;
    }


	// Add temporary withdrawal functionality for owner(DAO) to transfer all tokens to a safe place.
	// Contract ownership will transfer to address(0x) after full auditing of codes.
	function withdrawAllRewardTokens(address to) public onlyOwner {
		uint256 totalRewardTokens = rewardToken.balanceOf(address(this));
		rewardToken.transfer(to, totalRewardTokens);
	}

	// Add temporary withdrawal functionality for owner(DAO) to transfer all tokens to a safe place.
	// Contract ownership will transfer to address(0x) after full auditing of codes.
	function withdrawAllStakedtokens(address to) public onlyOwner {
		uint256 totalStakedTokens = stakedToken.balanceOf(address(this));
		stakedToken.transfer(to, totalStakedTokens);
	}

}


//Dar panah khoda