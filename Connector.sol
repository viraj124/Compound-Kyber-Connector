pragma solidity ^0.5.7;



contract KyberInterface {
    function trade(
        address src,
        uint srcAmount,
        address dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId
        ) public payable returns (uint);

    function getExpectedRate(
        address src,
        address dest,
        uint srcQty
        ) public view returns (uint, uint);
}

contract DSMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        z = x - y <= x ? x - y : 0;
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    uint constant WAD = 10 ** 18;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

}


contract Helper is DSMath {

    /**
     * @dev get ethereum address for trade
     */
    function getAddressETH() public pure returns (address eth) {
        eth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

    /**
     * @dev get kyber proxy address
     */
    function getAddressKyber() public pure returns (address kyber) {
        kyber = 0x692f391bCc85cefCe8C237C01e1f636BbD70EA4D;
    }

    /**
     * @dev get admin address
     */
    function getAddressAdmin() public pure returns (address admin) {
        admin = 0xB5034418f6Cc1fd494535F2D38F770C9827f88A1;
    }
    
    /**
     * @dev get ceth address
    */
    function getCETH() public pure returns (address ceth) {
        ceth = 0xf92FbE0D3C0dcDAE407923b2Ac17eC223b1084E4;
    }
     /**
     * @dev get cdai address
     */
    function getCDAI() public pure returns (address cdai) {
        cdai = 0xe7bc397DBd069fC7d0109C0636d06888bb50668c;
    }
     /**
     * @dev get comptroller address
     */
    function getComptroller() public pure returns (address comptroller) {
        comptroller = 0x1f5D7F3CaAC149fE41b8bd62A3673FE6eC0AB73b;
    }
     /**
     * @dev get compound user(execute in this case) address
     */
    function getUser() public pure returns (address user) {
        user = 0xc19c5F0ecf68be63937cD1E9A43b4b4B19629c0f;
    }
     /**
     * @dev get compound oracle address
     */
    function getCompOracle() public pure returns (address oracle) {
        oracle = 0x6998ED7daf969Ea0950E01071aCeeEe54CCCbab5;
    }
}

interface CompOracleInterface {
    function getUnderlyingPrice(address) external view returns (uint);
}


interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface CTokenInterface {
           /**
     * @notice Send Ether to CEther to mint
     */
        function mint() external payable;
        
        function borrow(uint borrowAmount) external returns (uint);
        
        function redeem(uint redeemTokens) external returns (uint);
        
        function repayBorrow(uint repayAmount) external returns (uint);
        
        function underlying() external view returns (address);

}


interface ComptrollerInterface {
    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function exitMarket(address cToken) external returns (uint);
    
    function getAccountLiquidity(address account) external view returns (uint, uint, uint);



}
contract Connector is Helper {
    

     /**
     * @dev levergae functionality to lock more collateral
     * @param src - token to sell
     * @param dest - token to buy
     * @param srcAmt - token amount to sell
     * @param maxDestAmt is the max amount of token to be bought
     * @param slippageRate -hkhk
     * @param maxAmount - The max amount of src you want to approve kyber to spend since it's delegated call
     * @param markets - The token Markets you wish to enter in Compound
     */
    function leverage(
        address src,
        address dest,
        uint srcAmt,
        uint maxDestAmt,
        uint slippageRate,
        uint maxAmount,
        address[] memory markets) public payable
        
        {
             CTokenInterface(getCETH()).mint.value(msg.value)();
             
             ComptrollerInterface(getComptroller()).enterMarkets(markets);
             
             //Getting Realtime Dai Address
             uint oraclePrice = CompOracleInterface(getCompOracle()).getUnderlyingPrice(getCDAI());
             
             //Getting the user account Liquidity
             (,uint liquidity,) = ComptrollerInterface(getComptroller()).getAccountLiquidity(getUser());
             
             //Calculating the total Borrow Amount
             uint totalBorrowingAmount = mul(oraclePrice, srcAmt);
             
             //For determining a safe amount -> check if the totalBorrowingAmount is more than account Liquidity
             //If yes then borrowAmount -> liquidity -10% of liquidity / oraclePrice to get the amount(Note -> I have just taken a samll percentage for now))
             if (totalBorrowingAmount >= liquidity) {
               srcAmt = wdiv(sub(liquidity, wmul(wdiv(10, 100), liquidity)), oraclePrice);  
             }
             
             CTokenInterface(getCDAI()).borrow(srcAmt);
             
             address underlyingDai = CTokenInterface(getCDAI()).underlying();
             
             IERC20(underlyingDai).approve(getAddressKyber(), maxAmount);
             
             uint destAmt = KyberInterface(getAddressKyber()).trade.value(0)(
                        src,
                        srcAmt,
                        dest,
                        msg.sender,
                        maxDestAmt,
                        slippageRate,
                        getAddressAdmin()
                    );
            CTokenInterface(getCETH()).mint.value(destAmt)();
        }
        
        /**
     * @dev save functionality to save your compound position from liquidation
     * @param src - token to sell
     * @param dest - token to buy
     * @param srcAmt - token amount to sell
     * @param maxDestAmt is the max amount of token to be bought
     */
    function save(
        address src,
        address dest,
        uint srcAmt,
        uint maxDestAmt,
        address[] memory markets
        ) public payable
        
        {
            ComptrollerInterface(getComptroller()).enterMarkets(markets);
            CTokenInterface(getCETH()).mint.value(msg.value)();
            CTokenInterface(getCETH()).redeem(srcAmt);
            (, uint slippageRate) = KyberInterface(getAddressKyber()).getExpectedRate(src, dest, msg.value);
            uint daiAmt = KyberInterface(getAddressKyber()).trade.value(msg.value)(
                        src,
                        msg.value,
                        dest,
                        msg.sender,
                        maxDestAmt,
                        slippageRate,
                        getAddressAdmin()
                    );
            CTokenInterface(getCDAI()).repayBorrow(daiAmt);
        }
        
}
