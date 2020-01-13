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
     * @dev gets ETH & token balance
     * @param src is the token being sold
     * @return ethBal - if not erc20, eth balance
     * @return tknBal - if not eth, erc20 balance
     */
    function getBal(address src, address _owner) public view returns (uint, uint) {
        uint tknBal;
        if (src != getAddressETH()) {
            tknBal = IERC20(src).balanceOf(address(_owner));
        }
        return (address(_owner).balance, tknBal);
    }

    /**
     * @dev getting rates from Kyber
     * @param src is the token being sold
     * @param dest is the token being bought
     * @param srcAmt is the amount of token being sold
     * @return expectedRate - the current rate
     * @return slippageRate - rate with 3% slippage
     */
    function getExpectedRate(
        address src,
        address dest,
        uint srcAmt
    ) public view returns (
        uint expectedRate,
        uint slippageRate
    )
    {
        (expectedRate,) = KyberInterface(getAddressKyber()).getExpectedRate(src, dest, srcAmt);
        slippageRate = (expectedRate / 100) * 99; // changing slippage rate upto 99%
    }

    /**
     * @dev fetching token from the trader if ERC20
     * @param trader is the trader
     * @param src is the token which is being sold
     * @param srcAmt is the amount of token being sold
     */
    function getToken(address trader, address src, uint srcAmt) internal returns (uint ethQty) {
        if (src == getAddressETH()) {
            require(msg.value == srcAmt, "not-enough-src");
            ethQty = srcAmt;
        } else {
            IERC20 tknContract = IERC20(src);
            setApproval(tknContract, srcAmt);
            tknContract.transferFrom(trader, address(this), srcAmt);
        }
    }

    /**
     * @dev setting allowance to kyber for the "user proxy" if required
     * @param tknContract is the token
     * @param srcAmt is the amount of token to sell
     */
    function setApproval(IERC20 tknContract, uint srcAmt) internal returns (uint) {
        uint tokenAllowance = tknContract.allowance(address(this), getAddressKyber());
        if (srcAmt > tokenAllowance) {
            tknContract.approve(getAddressKyber(), 2**255);
        }
    }

}

interface CompoundOracle {
 /**
   * @notice Get the underlying price of a cToken asset
   * @param cToken The cToken to get the underlying price of
   * @return The underlying asset price mantissa (scaled by 1e18).
   *  Zero means the price is unavailable.
 */
    function getUnderlyingPrice(CToken cToken) external view returns (uint);
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
        
        function underlying() external view returns (address);

}


interface ComptrollerInterface {
    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function exitMarket(address cToken) external returns (uint);


}
contract Connector is Helper {
    
     /**
     * @dev levergae functionality to lock more collateral
     * @param src - token to sell
     * @param dest - token to buy
     * @param srcAmt - token amount to sell
     * @param maxDestAmt is the max amount of token to be bought
     * @param slippageRate
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
        address[] memory markets) public payable returns (uint destAmt)
        {
             CTokenInterface(getCETH()).mint.value(msg.value)();
             
             uint[] memory tokenMarkets = ComptrollerInterface(getComptroller()).enterMarkets(markets);
             
             uint oraclePrice = CompoundOracle(getCompOracle()).getUnderlyingPrice(CTokenInterface(getCDAI()));
             
             (,liquidity,) = ComptrollerInterface(getComptroller()).getLiquidity(address);
             
             uint amt = CTokenInterface(getCDAI()).borrow(srcAmt);
             
             address underlyingDai = CTokenInterface(getCDAI()).underlying();
             
             bool isApproved = IERC20(underlyingDai).approve(getAddressKyber(), maxAmount);
             
             destAmt = KyberInterface(getAddressKyber()).trade.value(0)(
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
}
