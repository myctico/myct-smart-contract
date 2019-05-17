pragma solidity >=0.5.0 <0.6.0;

import './SafeMath.sol';
import './Ownable.sol';
import './Agent.sol';

/**
 * @title Rate contract 
 * @dev Letter values of currencies according to the standard ISO4217.
 * @dev ETH alfa-3 code as it's and contains the rate to USD. Example: rate["ETH"] = 227$.
 */
contract Rate is Agent {

    using SafeMath for uint;

    struct ISO4217 {
        string name;        
        uint number3;
        uint decimal;
        uint timeadd;
        uint timeupdate;
    }
    
    mapping(bytes32 => ISO4217) public currency;
    mapping(bytes32 => uint) public rate;
    
    event addCurrencyEvent(bytes32 _code, string _name, uint _number3, uint _decimal, uint _timeadd);
    event updateCurrencyEvent(bytes32 _code, string _name, uint _number3, uint _decimal, uint _timeupdate);
    event updateRateEvent(bytes32 _code, uint _value);
    event donationEvent(address _from, uint _value);

    constructor() public {
        addCurrency("ETH", "Ethereum", 0, 2); // 0x455448
        addCurrency("BTC", "Bitcoin", 0, 8); // 0x425443
    }

    // returns the Currency
    function getCurrency(bytes32 _code) public view returns (string memory, uint, uint, uint, uint) {
        return (currency[_code].name, currency[_code].number3, currency[_code].decimal, currency[_code].timeadd, currency[_code].timeupdate);
    }

    // returns Rate of coin to PMC (with the exception of rate["ETH"])
    function getRate(bytes32 _code) public view returns (uint) {
        return rate[_code];
    }

    // returns Price of Object in the specified currency (local user currency (the result must be divided by the currency decimal))
    // _code - specified currency
    // _amount - price of object in PMC
    function getLocalPrice(bytes32 _code, uint _amount) public view returns (uint) {
        return rate[_code].mul(_amount);
    }

    // returns Price of Object in the crypto currency (WEI)    
    // _amount - price of object in PMC
    function getCryptoPrice(uint _amount) public view returns (uint) {
        return _amount.mul(1 ether).mul(10**currency["ETH"].decimal).div(rate["ETH"]);
    }

    // update rates for a specific coin
    function updateRate(bytes32 _code, uint _rate) public onlyAgent {
        rate[_code] = _rate;
        emit updateRateEvent(_code, _rate);
    }

    // Add new Currency
    function addCurrency(bytes32 _code, string memory _name, uint _number3, uint _decimal) public onlyAgent {        
        currency[_code] = ISO4217(_name, _number3, _decimal, block.timestamp, 0);
        emit addCurrencyEvent(_code, _name, _number3, _decimal, block.timestamp);
    }

    // update Currency
    function updateCurrency(bytes32 _code, string memory _name, uint _number3, uint _decimal) public onlyAgent {        
        currency[_code] = ISO4217(_name, _number3, _decimal, currency[_code].timeadd, block.timestamp);
        emit updateCurrencyEvent(_code, _name, _number3, _decimal, block.timestamp);
    }

    // execute function by owner if ERC20 token get stuck in this contract
    function execute(address _to, uint _value, bytes calldata _data) external onlyOwner {
        (bool success, bytes memory data) = _to.call.value(_value)(_data);
        require(success);
    }

    // donation function that get forwarded to the contract updater
    function donate() external payable {
        require(msg.value >= 0);        
        emit donationEvent(msg.sender, msg.value);
    }
}