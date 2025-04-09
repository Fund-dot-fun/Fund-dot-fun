// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./BondingCurve.sol";

contract ERC20Token is ERC20 {
    address public owner;
    address public immutable deployer;
    uint256 public immutable vestingStartTime;

    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 10 ** 18;
    uint256 public constant DEPLOYER_ALLOCATION_PERCENT = 2;
    uint256 public constant DEPLOYER_ALLOCATION = (TOTAL_SUPPLY * DEPLOYER_ALLOCATION_PERCENT) / 100;
    uint256 public constant VESTING_DURATION = 180 days;

    uint256 public vestedAmount;
    bool public milestonesReached;

    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);
    event MilestonesReached();
    event DeployerTokensVested(uint256 amount);
    event UnvestedTokensBurned(uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor(string memory tokenName, string memory tokenSymbol, address _owner, address _deployer)
        ERC20(tokenName, tokenSymbol)
    {
        require(_owner != address(0), "Owner zero address");
        require(_deployer != address(0), "Deployer zero address");

        owner = _owner;
        deployer = _deployer;
        vestingStartTime = block.timestamp;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == owner, "Only owner");

        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        owner = newOwner;
    }

    function claimVestedTokens() external {
        require(msg.sender == deployer, "Only deployer");

        uint256 newlyVested = calculateVestedAmount();
        if (newlyVested > vestedAmount) {
            uint256 amountToVest = newlyVested - vestedAmount;
            vestedAmount = newlyVested;

            _mint(deployer, amountToVest);
            emit DeployerTokensVested(amountToVest);
        }
    }

    function calculateVestedAmount() public view returns (uint256) {
        if (block.timestamp >= vestingStartTime + VESTING_DURATION) {
            return milestonesReached ? DEPLOYER_ALLOCATION : 0;
        }
        uint256 timeElapsed = block.timestamp - vestingStartTime;
        return (DEPLOYER_ALLOCATION * timeElapsed) / VESTING_DURATION;
    }

    function setMilestonesReached() external {
        require(msg.sender == owner, "Only owner");
        milestonesReached = true;
        emit MilestonesReached();
    }

    function burnUnvestedTokens() external {
        require(msg.sender == owner || msg.sender == deployer, "Unauthorized");
        require(block.timestamp > vestingStartTime + VESTING_DURATION, "Vesting ongoing");
        require(!milestonesReached, "Milestones reached");

        uint256 unvestedAmount = DEPLOYER_ALLOCATION - vestedAmount;
        emit UnvestedTokensBurned(unvestedAmount);
    }
}

contract TokenFactory {
    address public immutable platform;
    uint256 public constant TOKEN_CREATION_FEE = 0.003 ether;

    event TokenCreated(address indexed tokenAddress, string name, string symbol, address indexed deployer);
    event BondingCurveCreated(address indexed bondingCurveAddress, address indexed tokenAddress);

    constructor(address _platform) {
        require(_platform != address(0), "Platform zero address");
        platform = _platform;
    }

    function createToken(string memory name, string memory symbol)
        external
        payable
        returns (address tokenAddress, address curveAddress)
    {
        require(msg.value >= TOKEN_CREATION_FEE, "Insufficient fee");

        ERC20Token newToken = new ERC20Token(
            name,
            symbol,
            address(this), // Owner
            msg.sender // Deployer
        );

        BondingCurve bondingCurve = new BondingCurve(address(newToken), msg.sender, platform);

        tokenAddress = address(newToken);
        curveAddress = address(bondingCurve);

        emit TokenCreated(tokenAddress, name, symbol, msg.sender);
        emit BondingCurveCreated(curveAddress, tokenAddress);

        (bool success,) = platform.call{value: msg.value}("");
        require(success, "Fee transfer failed");

        return (tokenAddress, curveAddress);
    }

    function transferTokenOwnership(address token, address newOwner) external {
        require(msg.sender == ERC20Token(token).deployer(), "Only deployer");
        ERC20Token(token).transferOwnership(newOwner);
    }
}
