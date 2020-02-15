pragma solidity ^0.6.1;

import "./SafeMath.sol";

contract ScenarioBondingCurve {
    using SafeMath for uint256;

    address public beneficiary;
    uint256 public currentSupply;
    uint256 public totalContributed;
    mapping (address => uint256) public ledger;
    mapping (address => uint256) public contributions;

    uint8 public exponent;
    uint8 public coefficient;
    uint256 public reserveRatio;

    uint256 private constant precision = 1000000000000;

    string internal constant INSUFFICIENT_ETH = 'Insufficient Ether';
    string internal constant INSUFFICIENT_TOKENS = 'Request exceeds token balance';

    constructor()
    public {
        beneficiary = 0x225991BbF363a9ffE3aD0ebb9d6cFe7e79Cdb3FF;
        exponent = 2;
        coefficient = 1;
        reserveRatio = 800000000000;
        currentSupply = 1;
    }

    function buy(uint256 amount)
    external payable {
        uint256 price = calcMintPrice(amount);
        require(msg.value >= price, INSUFFICIENT_ETH);
        uint256 reserveValue = msg.value.mul(reserveRatio).div(precision);
        uint256 contributionValue = msg.value.sub(reserveValue);
        uint256 refund = msg.value.sub(reserveValue).sub(contributionValue);
        if (refund > 0) {
            msg.sender.transfer(refund);
        }
        ledger[msg.sender] = ledger[msg.sender].add(amount);
        currentSupply = currentSupply.add(amount);
        contribute(contributionValue, msg.sender);
    }

    function sell(uint256 amount)
    external {
        require(amount <= ledger[msg.sender], INSUFFICIENT_TOKENS);
        uint256 exitValue = calcBurnReward(amount);
        msg.sender.transfer(exitValue);
        ledger[msg.sender] = ledger[msg.sender].sub(amount);
        currentSupply = currentSupply.sub(amount);
    }

    function lovequit()
    external {
        uint256 holdings = ledger[msg.sender];
        uint256 exitValue = calcBurnReward(holdings);
        currentSupply = currentSupply.sub(holdings);
        contribute(exitValue, msg.sender);
        ledger[msg.sender] = 0;
    }

    function contribute(uint256 amount, address sender)
    internal {
        beneficiary.transfer(amount);
        contributions[sender] = contributions[sender].add(amount);
        totalContributed = totalContributed.add(amount);
    }

    function integral(uint256 limitA, uint256 limitB, uint256 multiplier)
    internal returns (uint256) {
        uint256 raiseExp = exponent + 1;
        uint256 _coefficient = coefficient.mul(multiplier);
        if (multiplier != 1) {
            _coefficient = _coefficient.div(precision);
        }
        uint256 upper = precision.mul(limitB ** raiseExp).div(raiseExp).div(precision);
        uint256 lower = precision.mul(limitA ** raiseExp).div(raiseExp).div(precision);
        return _coefficient.mul(upper.sub(lower));
    }

    function calcMintPrice(uint256 amount)
    public returns (uint256) {
        return integral(currentSupply, currentSupply.add(amount), 1);
    }

    function calcBurnReward(uint256 amount)
    public returns (uint256) {
        return integral(currentSupply.sub(amount), currentSupply, reserveRatio);
    }
}