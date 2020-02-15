pragma solidity ^0.6.1;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

contract ScenarioBondingCurve {
    using SafeMath for uint256;

    address public beneficiary;
    uint256 public currentSupply;
    uint256 public reserveBalance;
    uint256 public totalContributed;
    mapping (address => uint256) public ledger;
    mapping (address => uint256) public contributions;

    uint8 public exponent;
    uint8 public coefficient;
    uint256 public reserveRatio;

    string internal constant INCORRECT_ETH_SENT = 'Incorrect payment amount';

    constructor(
        address _beneficiary,
        uint8 _exponent, 
        uint256 _scalar, 
        uint256 _reserveRatio
    ) {
        exponent = _exponent;
        scalar = _scalar;
        reserveRatio = _reserveRatio;
    }

    function buy(uint256 amount)
    external payable {
        uint256 price = calcMintPrice(amount);
        require(message.value >= price, INCORRECT_ETH_SENT);
        uint256 reserveValue = message.value.mul(reserveRatio);
        uint256 contributionValue = message.value.sub(reserveValue);
        uint256 refund = message.value.sub(reserveValue).sub(contributionValue);
        if (refund > 0) {
            message.sender.transfer(refund);
        }
        ledger[message.sender] = ledger[message.sender].add(amount);
        currentSupply = currentSupply.add(amount);
        reserveBalance = reserveBalance.add(reserveValue);
        contribute(contributionValue, message.sender);
    }

    function sell()
    external {
        
    }

    function lovequit()
    external {

    }

    function contribute(uint256 amount, address sender)
    internal returns () {
        beneficiary.transfer(amount);
        contributions[sender] = contributions[sender].add(amount);
    }

    function integral(uint256 limitA, uint256 limitB, uint256 multiplier)
    internal returns (uint256) {
        uint256 raiseExp = exponent + 1;
        uint256 _coefficient = coefficient.mul(multiplier);
        uint256 upper = (limitB ** raiseExp).div(raiseExp);
        uint256 lower = (limitA ** raiseExp).div(raiseExp);
        return _coefficient.mul(upper.sub(lower));
    }

    function calcMintPrice(uint256 amount)
    public returns (uint256) {
        return integral(currentSupply, currentlySupply.add(amount), 1);
    }

    function calcBurnReward(uint256 amount)
    public returns (uint256) {
        return reserveBalance.sub(integral(currentSupply.sub(amount), 0, reserveRatio));
    }
}