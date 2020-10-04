//Be name khoda

pragma solidity 0.6.12;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";

interface StakedToken {
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface RewardToken {
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);

}

contract Staking{

	struct UserData {
		uint256 depositAmount;
		uint256 paidReward;
	}

	using SafeMath for uint256;
	

	mapping (address => UserData) public users;

	uint256 public rewardTillNowPerShare = 0;
	uint256 public lastRewardedBlock;
	uint256 public rewardPerBlock = 79364282539682540; //0.07936428253968254*10**18

	StakedToken public stakedToken;
	RewardToken public rewardToken;

    event Deposit(address user, uint256 amount);
    event Withdraw(address user, uint256 amount);
    event EmergencyWithdraw(address user, uint256 amount);
	event RewardClaimed(address user, uint256 amount);
	
	constructor (address _stakedToken, address _rewardToken) public {
		stakedToken = StakedToken(_stakedToken);
		rewardToken = RewardToken(_rewardToken);
		lastRewardedBlock = block.number;
	}

	// Update reward variables of the pool to be up-to-date.
	function update() public {
		if (block.number <= lastRewardedBlock) {
			return;
		}
		// uint256 lpSupply = stakedToken.totalSupply();
		uint256 rewardAmount = (block.number - lastRewardedBlock).mul(rewardPerBlock);
		
		rewardTillNowPerShare = rewardTillNowPerShare.add(rewardAmount.mul(1e18).div(stakedToken.balanceOf(address(this))));
		lastRewardedBlock = block.number;
    }

	// View function to see pending reward on frontend.
	function pendingReward(address _user) external view returns (uint256) {
		UserData storage user = users[_user];
		uint256 accRewardPerShare = rewardTillNowPerShare;

		if (block.number > lastRewardedBlock) {
			uint256 rewardAmount = (block.number - lastRewardedBlock).mul(rewardPerBlock);
            accRewardPerShare = accRewardPerShare.add(rewardAmount.mul(1e18).div(stakedToken.balanceOf(address(this))));
        }
        return user.depositAmount.mul(accRewardPerShare).div(1e18).sub(user.paidReward);
	}

	function deposit(uint256 _amount) public {
		UserData storage user = users[msg.sender];
        update();

        if (user.depositAmount > 0) {
            uint256 _pendingReward = user.depositAmount.mul(rewardTillNowPerShare).div(1e18).sub(user.paidReward);
			rewardToken.transfer(msg.sender, _pendingReward);
			emit RewardClaimed(msg.sender, _pendingReward);
        }

		user.depositAmount = user.depositAmount.add(_amount);
        user.paidReward = user.depositAmount.mul(rewardTillNowPerShare).div(1e18);

		stakedToken.transferFrom(address(msg.sender), address(this), _amount);
        emit Deposit(msg.sender, _amount);
    }

	function withdraw(uint256 _amount) public {
		UserData storage user = users[msg.sender];
        require(user.depositAmount >= _amount, "withdraw amount exceeds deposited amount");
        update();
		

		uint256 totalReward = user.depositAmount.mul(rewardTillNowPerShare).div(1e18);
		uint256 _pendingReward = totalReward.sub(user.paidReward);
        user.paidReward = totalReward;
		rewardToken.transfer(msg.sender, _pendingReward);
		emit RewardClaimed(msg.sender, _pendingReward);


		user.depositAmount = user.depositAmount.sub(_amount);
		stakedToken.transfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
		UserData storage user = users[msg.sender];

		stakedToken.transfer(address(msg.sender), user.depositAmount);

        emit EmergencyWithdraw(msg.sender, user.depositAmount);

        user.depositAmount = 0;
        user.paidReward = 0;
    }

    // Safe reward transfer function, just in case pool do not have enough reward.
    // function safeRewardTransfer(address _to, uint256 _amount) internal {
    //     uint256 rewardBalance = rewardToken.balanceOf(address(this));
    //     require(rewardBalance > _amount, "insufficient rewardToken balance");
    //     rewardToken.transfer(_to, _amount);
    // }

	// function safeTransfer(address _to, uint256 _amount) internal {
	// 	stakedToken.transfer(_to, _amount);
	// }

	// function safeTransferFrom(address _from, address _to, uint256 _amount) internal {
	// 	stakedToken.transferFrom(_from, _to, _amount);
	// }

}


//Dar panah khoda