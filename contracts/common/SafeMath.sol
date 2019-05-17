pragma solidity >=0.5.0 <0.6.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x + y;
        require(z >= x);
        return z;
    }    

    /**
    * @dev Subtracts two numbers, reverts on overflow.
    */
    function sub(uint256 x, uint256 y) internal pure returns (uint256) {
        require(y <= x);
        uint256 z = x - y;
        return z;
    }

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */  
    function mul(uint256 x, uint256 y) internal pure returns (uint256) {    
        if (x == 0) {
            return 0;
        }
    
        uint256 z = x * y;
        require(z / x == y);
        return z;
    }


	/**
    * @dev Integer division of two numbers, reverts on division by zero.
    */
    function div(uint256 x, uint256 y) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(y > 0);
        uint256 z = x / y;
        return z;
    }
    
    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo), reverts when dividing by zero.
     */
    function mod(uint256 x, uint256 y) internal pure returns (uint256) {
        require(y != 0);
        return x % y;
    }

    /**
    * @dev Returns the integer percentage of the number.
    */
    function perc(uint256 x, uint256 y) internal pure returns (uint256) {
        if (x == 0) {
            return 0;
        }
        
        uint256 z = x * y;
        require(z / x == y);    
        z = z / 10000; // percent to hundredths
        return z;
    }

    /**
    * @dev Returns the minimum value of two numbers.
    */	
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x <= y ? x : y;
        return z;
    }

    /**
    * @dev Returns the maximum value of two numbers.
    */
    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x >= y ? x : y;
        return z;
    }
}