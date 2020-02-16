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

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
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
    uint public reserveRatio;
    
    uint public precision = 1000000000000000000;

    string internal constant INSUFFICIENT_ETH = 'Insufficient Ether';
    string internal constant INSUFFICIENT_TOKENS = 'Request exceeds token balance';
    string internal constant INVALID_ADDRESS = 'Wallet does not exist';

    constructor()
    public {
        beneficiary = 0x4aB6A3307AEfcC05b9de8Dbf3B0a6DEcEBa320E6;
        exponent = 2;
        coefficient = 10000000000;
        reserveRatio = wdiv(4, 5);
        currentSupply = 1;
    }
    
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
    }

    function sell(uint amount)
    external {
        require(amount <= ledger[msg.sender], INSUFFICIENT_TOKENS);
        uint exitValue = calcBurnReward(amount);
        msg.sender.transfer(exitValue);
        ledger[msg.sender] = sub(ledger[msg.sender], amount);
        currentSupply = sub(currentSupply, amount);
    }

    function lovequit()
    external {
        require(ledger[msg.sender] > 0, INVALID_ADDRESS);
        uint holdings = ledger[msg.sender];
        uint exitValue = calcBurnReward(holdings);
        currentSupply = sub(currentSupply, holdings);
        contribute(exitValue, msg.sender);
        ledger[msg.sender] = 0;
    }
    
    function contribute(uint amount, address sender)
    internal {
        beneficiary.transfer(amount);
        contributions[sender] = add(contributions[sender], amount);
        totalContributed = add(totalContributed, amount);
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
    public returns (uint) {
        return integrate(currentSupply, add(currentSupply, amount), precision);
    }

    function calcBurnReward(uint amount)
    public returns (uint) {
        return integrate(sub(currentSupply, amount), currentSupply, reserveRatio);
    }
}