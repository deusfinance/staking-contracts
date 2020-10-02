//Be name khoda

pragma solidity 0.6.12;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";

interface StakedToken {
	function totalSupply() external view returns (uint);
}

interface RewardToken {

}

contract staking{

	struct UserData {
		uint256 depositAmount;
		uint256 paidReward;
	}

	using SafeMath for uint256;
	

	mapping (address => UserData) public users;

	uint256 public rewardTillNowPerShare = 0;
	uint256 public lastRewardedBlock;
	uint256 public rewardPerBlock = 100 * 10**18;

	StakedToken public stakedToken;
	RewardToken public rewardToken;

    event Deposit(address user, uint256 amount);
    event Withdraw(address user, uint256 amount);
    event EmergencyWithdraw(address user, uint256 amount);

	constructor (address _stakedToken, address _rewardToken) public {
		stakedToken = StakedToken(_stakedToken);
		rewardToken = RewardToken(_rewardToken)
		lastRewardedBlock = block.number;
	}

	function update() public {
		if (block.number <= lastRewardedBlock) {
			return;
		}
		// uint256 lpSupply = stakedToken.totalSupply();
		uint256 rewardAmount = (block.number - lastRewardedBlock).mul(rewardPerBlock);
		
		rewardTillNowPerShare = rewardTillNowPerShare.add(rewardAmount.mul(1e18).div(stakedToken.totalSupply()));
		lastRewardedBlock = block.number;
    }

	function pendingReward(address _user) external view returns (uint256) {
		UserData storage user = users[_user];
		uint256 accRewardPerShare = rewardTillNowPerShare;

		if (block.number > lastRewardedBlock) {
			uint256 rewardAmount = (block.number - lastRewardedBlock).mul(rewardPerBlock);
            accRewardPerShare = accRewardPerShare.add(rewardAmount.mul(1e18).div(stakedToken.totalSupply()));
        }
        return user.depositAmount.mul(accRewardPerShare).div(1e18).sub(user.paidReward);
	}

	function deposit(uint256 _amount) public {
		UserData storage user = users[msg.sender];
        update();

        if (user.amount > 0) {
            uint256 pending = user.depositAmount.mul(rewardTillNowPerShare).div(1e18).sub(user.paidReward);
        	safeSushiTransfer(msg.sender, pending);
        }
		// stakedToken.safeTransferFrom(address(msg.sender), address(this), _amount);
		safeTransferFrom(address(msg.sender), address(this), _amount);

		user.depositAmount = user.depositAmount.add(_amount);
        user.paidReward = user.depositAmount.mul(rewardTillNowPerShare).div(1e18);
        emit Deposit(msg.sender, _amount);
    }

	function withdraw(uint256 _amount) public {
		UserData storage user = users[msg.sender];
        require(user.depositAmount >= _amount, "withdraw amount exceeds deposited amount");
        update();
		
		uint256 pending = user.depositAmount.mul(rewardTillNowPerShare).div(1e18).sub(user.paidReward);
		safeSushiTransfer(msg.sender, pending);

		user.depositAmount = user.depositAmount.sub(_amount);

		// stakedToken.safeTransfer(address(msg.sender), _amount);
		safeTransfer(address(msg.sender), _amount);

        user.paidReward = user.depositAmount.mul(rewardTillNowPerShare).div(1e18);
        emit Withdraw(msg.sender, _amount);
    }

}


//Dar panah khoda