//Be name khoda

pragma solidity 0.6.12;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";

interface IUniswapV2Pair {
	function totalSupply() external view returns (uint);
}

contract staking{
	using SafeMath for uint256;
	
	uint256 public accSushiPerShare = 0;
	uint256 public lastRewardBlock;
	uint256 public sushiPerBlock = 100 * 10**18;
	
	IUniswapV2Pair uniswapPair = IUniswapV2Pair(0x50e37bB824Eba26669a4A5382A53fd2e034a6D4B);
	
	constructor () public {
		lastRewardBlock = block.number;
	}


	function update() public {
		if (block.number <= lastRewardBlock) {
			return;
		}
		uint256 lpSupply = uniswapPair.totalSupply();
		
		uint256 multiplier = block.number - lastRewardBlock;
		uint256 sushiReward = multiplier.mul(sushiPerBlock);
		
		accSushiPerShare = accSushiPerShare.add(sushiReward.mul(1e12).div(lpSupply));
		lastRewardBlock = block.number;
    }

}


//Dar panah khoda