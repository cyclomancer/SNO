pragma solidity ^0.6.1;

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

contract ScenarioBondingCurve is DSMath {
    
    address payable public beneficiary;
    uint public currentSupply;
    uint public totalContributed;
    mapping (address => uint) public ledger;
    mapping (address => uint) public contributions;

    uint public exponent;
    uint public coefficient;
    // uint public base;
    uint public reserveRatio;
    
    uint internal constant precision = 1000000000000000000;

    string internal constant INSUFFICIENT_ETH = 'Insufficient Ether';
    string internal constant INSUFFICIENT_TOKENS = 'Request exceeds token balance';
    string internal constant INVALID_ADDRESS = 'Wallet does not exist';

    constructor()
    public {
        beneficiary = 0x4aB6A3307AEfcC05b9de8Dbf3B0a6DEcEBa320E6;
        exponent = 2;
        // base = 2;
        coefficient = 10000000000;
        reserveRatio = wdiv(4, 5);
        currentSupply = 0;
    }

    event CalcPrice(address indexed caller, uint amount, uint price);
    event Buy(address indexed buyer, uint amount, uint value, uint refund);
    event Sell(address indexed seller, uint amount, uint value);
    event Lovequit(address indexed seller, uint amount, uint value);
    
    function buy(uint amount)
    external payable {
        uint price = calcMintPrice(amount);
        require(msg.value >= price, INSUFFICIENT_ETH);
        uint reserveValue = wmul(msg.value, reserveRatio);
        uint contributionValue = sub(msg.value, reserveValue);
        uint refund = msg.value - reserveValue - contributionValue;
        if (refund > 0) {
            msg.sender.transfer(refund);
        }
        ledger[msg.sender] = add(ledger[msg.sender], amount);
        currentSupply = add(currentSupply, amount);
        contribute(contributionValue, msg.sender);
        emit Buy(msg.sender, amount, sub(msg.value, refund), refund);
    }

    function sell(uint amount)
    external {
        require(amount <= ledger[msg.sender], INSUFFICIENT_TOKENS);
        uint exitValue = calcBurnReward(amount);
        msg.sender.transfer(exitValue);
        ledger[msg.sender] = sub(ledger[msg.sender], amount);
        currentSupply = sub(currentSupply, amount);
        emit Sell(msg.sender, amount, exitValue);
    }

    function lovequit()
    external {
        require(ledger[msg.sender] > 0, INVALID_ADDRESS);
        uint holdings = ledger[msg.sender];
        uint exitValue = calcBurnReward(holdings);
        currentSupply = sub(currentSupply, holdings);
        contribute(exitValue, msg.sender);
        ledger[msg.sender] = 0;
        emit Lovequit(msg.sender, holdings, exitValue);
    }
    
    function contribute(uint amount, address sender)
    internal {
        beneficiary.transfer(amount);
        contributions[sender] = add(contributions[sender], amount);
        totalContributed = add(totalContributed, amount);
    }
    
    function getBuyPrice(uint amount)
    external {
        uint price = calcMintPrice(amount);
        emit CalcPrice(msg.sender, amount, price);

    }
    
    function getSellPrice(uint amount)
    external {
        uint price = calcBurnReward(amount);
        emit CalcPrice(msg.sender, amount, price);
    }

    function integrate(uint limitA, uint limitB, uint multiplier)
    internal returns (uint) {
        uint raiseExp = exponent + 1;
        uint _coefficient = wmul(coefficient, multiplier);
        uint upper = wdiv((limitB ** raiseExp), raiseExp);
        uint lower = wdiv((limitA ** raiseExp), raiseExp);
        return wmul(_coefficient, (sub(upper, lower)));
    }
    
    function calcMintPrice(uint amount)
    internal returns (uint) {
        uint newSupply = add(currentSupply, amount);
        uint result = integrate(currentSupply, newSupply, precision);
        result = result < coefficient ? coefficient : result;
        return result;
    }

    function calcBurnReward(uint amount)
    internal returns (uint) {
        uint newSupply = sub(currentSupply, amount);
        uint result = integrate(newSupply, currentSupply, reserveRatio);
        return result;
    }

//     function log_2(uint128 x)
//     internal pure returns (uint128) {
//         uint256 msb = 0;
//         uint256 xc = x;
//         if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
//         if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
//         if (xc >= 0x10000) { xc >>= 16; msb += 16; }
//         if (xc >= 0x100) { xc >>= 8; msb += 8; }
//         if (xc >= 0x10) { xc >>= 4; msb += 4; }
//         if (xc >= 0x4) { xc >>= 2; msb += 2; }
//         if (xc >= 0x2) msb += 1;
//         uint256 result = msb - 64 << 64;
//         uint256 ux = uint256 (x) << 127 - msb;
//         for (uint256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
//             ux *= ux;
//             uint256 b = ux >> 255;
//             ux >>= 127 + b;
//             result += bit * uint256 (b);
//         }
//         return uint128 (result);
//     }

//     function ln(uint128 x)
//     internal pure returns (uint128) {
//         return uint128 (
//             uint256 (log_2(x)) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128);
//   }

//     function integratePowerLaw(uint limitA, uint limitB, uint multiplier)
//     internal returns (uint) {
//         uint upper = base ** limitB;
//         uint lower = base ** limitA;
//         uint _coefficient = wdiv(wmul(coefficient, multiplier), ln(base));
//         return wmul(sub(upper, lower), _coefficient);
//     }
}