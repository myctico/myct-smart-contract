pragma solidity >=0.5.0 <0.6.0;

import './common/Ownable.sol';
import './common/ERC20.sol';

/**
 * @title MYCT Token based on ERC20 token
 */
contract MYCTToken is ERC20, Ownable {

  string public name;
  string public symbol;
	
  uint public decimals = 8;
  uint public initialSupply = 100 * 10**6; // 100 million

  /** Name and symbol were updated. */
  event UpdatedTokenInformation(string _name, string _symbol);

  constructor(string memory _name, string memory _symbol, address _crowdsale, address _project, address _bonus, address _bounty, address _adviser) public {
    name = _name;
    symbol = _symbol;    

    _totalSupply = initialSupply*uint(10)**decimals;
    // creating initial tokens
    _balances[_crowdsale] = _totalSupply; 
    emit Transfer(address(0), _crowdsale, _balances[_crowdsale]);
    
    // send 30% - to project account
    uint value = _totalSupply.perc(3000);
    _balances[_crowdsale] = _balances[_crowdsale].sub(value);
    _balances[_project] = value;
    emit Transfer(_crowdsale, _project, _balances[_project]);

    // send 10% - to bonus account
    value = _totalSupply.perc(1000);
    _balances[_crowdsale] = _balances[_crowdsale].sub(value);
    _balances[_bonus] = value;
    emit Transfer(_crowdsale, _bonus, _balances[_bonus]);

    // send 2.5% - to bounty account
    value = _totalSupply.perc(250);
    _balances[_crowdsale] = _balances[_crowdsale].sub(value);
    _balances[_bounty] = value;
    emit Transfer(_crowdsale, _bounty, _balances[_bounty]);

    // send 2.5% - to adviser account
    value = _totalSupply.perc(250);
    _balances[_crowdsale] = _balances[_crowdsale].sub(value);
    _balances[_adviser] = value;
    emit Transfer(_crowdsale, _adviser, _balances[_adviser]);
  } 

  /**
  * Owner may issue new tokens
  */
  function mint(address _receiver, uint _amount) public onlyOwner {
    require(_receiver != address(0));
    _balances[_receiver] = _balances[_receiver].add(_amount);
    _totalSupply = _totalSupply.add(_amount);    
    emit Transfer(address(0), _receiver, _amount);
  }

  /**
  * Owner may burn tokens
  */
  function burn(address _receiver, uint256 _amount) public onlyOwner {
    require(_receiver != address(0));
    _totalSupply = _totalSupply.sub(_amount);
    _balances[_receiver] = _balances[_receiver].sub(_amount);
    emit Transfer(_receiver, address(0), _amount);
  }

  /**
  * Owner can update token information here.
  */
  function updateTokenInformation(string memory _name, string memory _symbol) public onlyOwner {
    name = _name;
    symbol = _symbol;
    emit UpdatedTokenInformation(_name, _symbol);
  }
}