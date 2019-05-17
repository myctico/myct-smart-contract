pragma solidity >=0.5.0 <0.6.0;

import './SafeMath.sol';
import './ERC20I.sol';

/**
 * @title Standard ERC20 token
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20 
 */
contract ERC20 is ERC20I {

  using SafeMath for uint;
	
  uint _totalSupply;
  mapping (address => uint) _balances;
  mapping (address => mapping (address => uint)) internal _allowed;

  /** 
   * @dev Total Supply
   * @return _totalSupply 
   */  
  function totalSupply() public view returns (uint) {
    return _totalSupply;
  }
  
  /** 
   * @dev Tokens balance
   * @param _owner holder address
   * @return balance amount 
   */
  function balanceOf(address _owner) public view returns (uint) {
    return _balances[_owner];
  }
  
  /** 
   * @dev Tranfer tokens to address
   * @param _to dest address
   * @param _value tokens amount
   * @return transfer result
   */
  function transfer(address _to, uint _value) public returns (bool success) {
    require(_to != address(0));
    require(_balances[msg.sender] >= _value);
    
    _balances[msg.sender] = _balances[msg.sender].sub(_value);
    _balances[_to] = _balances[_to].add(_value);
    
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /** 
   * @dev Token allowance
   * @param _owner holder address
   * @param _spender spender address
   * @return remain amount
   */
  function allowance(address _owner, address _spender) public view returns (uint) {
    return _allowed[_owner][_spender];
  }

  /**    
   * @dev Transfer tokens from one address to another
   * @param _from source address
   * @param _to dest address
   * @param _value tokens amount
   * @return transfer result
   */
  function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
    require(_to != address(0));
    require(_balances[_from] >= _value);
    require(_allowed[_from][msg.sender] >= _value);
    
    _balances[_from] = _balances[_from].sub(_value);
    _balances[_to] = _balances[_to].add(_value);
    _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);
    
    emit Transfer(_from, _to, _value);
    return true;
  }
  
  /** 
   * @dev Approve transfer
   * @param _spender holder address
   * @param _value tokens amount
   * @return result  
   */
  function approve(address _spender, uint _value) public returns (bool success) {
    require((_value == 0) || (_allowed[msg.sender][_spender] == 0));
    _allowed[msg.sender][_spender] = _value;
    
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
}