pragma solidity >=0.5.0 <0.6.0;

import './common/SafeMath.sol';
import './common/Agent.sol';
import './common/ERC20.sol';
import './common/RateI.sol';

/**
 * @title MyCity CrowdSale management contract
 */
contract MYCTCrowdSale is Agent {

  using SafeMath for uint;

  uint public decimals = 8;
  uint public multiplier = 10 ** decimals;
  
  RateI public Rate;
  ERC20I public ERC20;

  uint public totalSupply;
  
  /* The UNIX timestamp start/end date of the crowdsale */
  uint public startsAt;
  uint public endsIn;
  
  /* How many unique addresses that have invested */
  uint public investorCount = 0;
  
  /* How many wei of funding we have raised */
  uint public weiRaised = 0;
  
  /* How many usd of funding we have raised */
  uint public usdRaised = 0;
  
  /* The number of tokens already sold through this contract*/
  uint public tokensSold = 0;
  
  /* Has this crowdsale been finalized */
  bool public finalized;

  /** State
   *
   * - Preparing: All contract initialization calls and variables have not been set yet
   * - PrivateSale: Private sale
   * - PreSale: Pre Sale
   * - Sale: Active crowdsale
   * - Success: HardCap reached
   * - Failure: HardCap not reached before ending time
   * - Finalized: The finalized has been called and succesfully executed
   */
  enum State{Unknown, Preparing, PrivateSale, PreSale, Sale, Success, Failure, Finalized}

  /* How much ETH each address has invested to this crowdsale */
  mapping (address => uint) public investedAmountOf;
  
  /* How much tokens this crowdsale has credited for each investor address */
  mapping (address => uint) public tokenAmountOf;
  
  /* Wei will be transfered on this address */
  address payable public Wallet;
  
  /* How much wei we have given back to investors. */
  uint public weiRefunded = 0;

  /* token price in USD */
  uint public price;

  struct _Stage {
    uint startsAt;
    uint endsIn;
    uint bonus;    
    uint min;
    uint tokenAmount;
    mapping (address => uint) tokenAmountOfStage; // how much tokens this crowdsale has credited for each investor address in a particular stage
  }

  _Stage[3] public Stages;

  mapping (bytes32 => uint) public cap;

  /* A new investment was made */
  event Invested(address investor, uint weiAmount, uint tokenAmount, uint bonusAmount);
  /* Receive ether on the contract */
  event ReceiveEtherOnContract(address sender, uint amount);
  
  /**
   * @dev Constructor sets default parameters
   * @param _start01 - start private period
   * @param _end01 - end of private period
   * @param _start02 - start pre-sale period
   * @param _end02 - end of pre-sale period
   * @param _start03 - start main token sale period
   * @param _end03 - end of main token sale period
   */
  constructor(address payable _Wallet, uint _priceTokenInUSDCents, uint _start01, uint _end01, uint _start02, uint _end02, uint _start03, uint _end03) public {
    
    initialization(_Wallet, _priceTokenInUSDCents, _start01, _end01, _start02, _end02, _start03, _end03);
  }

  function hash(State _data) private pure returns (bytes32 _hash) {
    return keccak256(abi.encodePacked(_data));
  }

  function initialization(address payable _Wallet, uint _priceTokenInUSDCents, uint _start01, uint _end01, uint _start02, uint _end02, uint _start03, uint _end03) public onlyOwner {

    require(_Wallet != address(0) && _priceTokenInUSDCents > 0);

    require(_start01 < _end01 && _end01 < _start02 && _start02 < _end02 && _end02 < _start03 && _start03 < _end03);

    Wallet =_Wallet;
    startsAt = _start01;
    endsIn = _end03;
    price = _priceTokenInUSDCents;

    cap[hash(State.PrivateSale)] = 150 * (10**6) * multiplier +  60 * (10**6) * multiplier;
    cap[hash(State.PreSale)]     = 500 * (10**6) * multiplier + 125 * (10**6) * multiplier;
    cap[hash(State.Sale)]        = 250 * (10**6) * multiplier;

    Stages[0] = _Stage({startsAt: _start01, endsIn: _end01, bonus: 0, min: 1250 * multiplier, tokenAmount: 0});
    Stages[1] = _Stage({startsAt: _start02, endsIn: _end02, bonus: 0, min: 2500 * multiplier, tokenAmount: 0});
    Stages[2] = _Stage({startsAt: _start03, endsIn: _end03, bonus: 0, min: 2500 * multiplier, tokenAmount: 0});
  }
  
  /** 
   * @dev Crowdfund state
   * @return State current state
   */
  function getState() public view returns (State) {
    if (finalized) return State.Finalized;
    else if (address(ERC20) == address(0) || address(Rate) == address(0) || now < startsAt) return State.Preparing;
    else if (now >= Stages[0].startsAt && now <= Stages[0].endsIn) return State.PrivateSale;
    else if (now >= Stages[1].startsAt && now <= Stages[1].endsIn) return State.PreSale;
    else if (now >= Stages[2].startsAt && now <= Stages[2].endsIn) return State.Sale;    
    else if (isCrowdsaleFull()) return State.Success;
    else return State.Failure;
  }

  /** 
   * @dev Gets the current stage.
   * @return uint current stage
   */
  function getStage() public view returns (uint) {
    uint i;
    for (i = 0; i < Stages.length; i++) {
      if (now >= Stages[i].startsAt && now < Stages[i].endsIn) {
        return i;
      }
    }
    return Stages.length-1;
  }

  /**
   * Buy tokens from the contract
   */
  function() external payable {
    investInternal(msg.sender, msg.value);
  }

  /**
   * Buy tokens from personal area (ETH or BTC)
   */
  function investByAgent(address _receiver, uint _weiAmount) external onlyAgent returns (uint _tokens) {
    return investInternal(_receiver, _weiAmount);
  }
  
  /**
   * Make an investment.
   *
   * @param _receiver The Ethereum address who receives the tokens
   * @param _weiAmount The invested amount
   *
   */
  function investInternal(address _receiver, uint _weiAmount) private returns (uint _tokens) {

    require(_weiAmount > 0);

    State currentState = getState();
    require(currentState == State.PrivateSale || currentState == State.PreSale || currentState == State.Sale);

    uint currentStage = getStage();
    
    // Calculating the number of tokens
    uint tokenAmount = 0;
    uint bonusAmount = 0;
    (tokenAmount, bonusAmount) = calculateTokens(_weiAmount, currentStage);

    tokenAmount = tokenAmount.add(bonusAmount);
    
    // Check cap for every State
    require(Stages[currentStage].tokenAmount.add(tokenAmount) <= cap[hash(currentState)]);
 
    // Update stage counts  
    Stages[currentStage].tokenAmount  = Stages[currentStage].tokenAmount.add(tokenAmount);
    Stages[currentStage].tokenAmountOfStage[_receiver] = Stages[currentStage].tokenAmountOfStage[_receiver].add(tokenAmount);
	
    // Update investor
    if(investedAmountOf[_receiver] == 0) {
       investorCount++; // A new investor
    }  
    investedAmountOf[_receiver] = investedAmountOf[_receiver].add(_weiAmount);
    tokenAmountOf[_receiver] = tokenAmountOf[_receiver].add(tokenAmount);

    // Update totals
    weiRaised  = weiRaised.add(_weiAmount);
    usdRaised  = usdRaised.add(weiToUsdCents(_weiAmount));
    tokensSold = tokensSold.add(tokenAmount);    

    // Send ETH to Wallet
    Wallet.transfer(msg.value);

    // Send tokens to _receiver
    ERC20.transfer(_receiver, tokenAmount);

    // Tell us invest was success
    emit Invested(_receiver, _weiAmount, tokenAmount, bonusAmount);

    return tokenAmount;
  }  
  
  /**
   * @dev Calculating tokens count
   * @param _weiAmount invested
   * @param _stage stage of crowdsale
   * @return tokens amount
   */
  function calculateTokens(uint _weiAmount, uint _stage) internal view returns (uint tokens, uint bonus) {
    uint usdAmount = weiToUsdCents(_weiAmount);    
    tokens = multiplier.mul(usdAmount).div(price);

    // Check minimal amount to buy
    require(_weiAmount >= Stages[_stage].min);    

    bonus = tokens.perc(Stages[_stage].bonus);
    return (tokens, bonus);
  }
  
  /**
   * @dev Converts wei value into USD cents according to current exchange rate
   * @param weiValue wei value to convert
   * @return USD cents equivalent of the wei value
   */
  function weiToUsdCents(uint weiValue) internal view returns (uint) {
    return weiValue.mul(Rate.getRate("ETH")).div(1 ether);
  }
  
  /**
   * @dev Check if SoftCap was reached.
   * @return true if the crowdsale has raised enough money to be a success
   */
  function isCrowdsaleFull() public view returns (bool) {
    //if(tokensSold >= SoftCap){
  //    return true;  
    //}
    return false;
  }

  /**
   * @dev burn unsold tokens and allow transfer of tokens.
   */
  function finalize() public onlyOwner {    
    require(!finalized);
    require(now > endsIn);

    //if(HardCap > tokensSold){
      // burn unsold tokens 
      //ERC20.transfer(address(0), math.sub(HardCap, tokensSold));
    //}

    // allow transfer of tokens
    //ERC20.releaseTokenTransfer();

    finalized = true;
  }

  /**
   * Receives ether on the contract
   */
  function receive() public payable {
    emit ReceiveEtherOnContract(msg.sender, msg.value);
  }

  function setTokenContract(address _contract) external onlyOwner {
    ERC20 = ERC20I(_contract);
    totalSupply = ERC20.totalSupply();
    //HardCap = ERC20.balanceOf(address(this));
  }

  function setRate(address _contract) external onlyOwner {
    Rate = RateI(_contract);
  }
}