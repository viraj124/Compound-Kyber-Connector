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


contract Helper {

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
    function approve(address spender, uint256 amount) external returns (bool);

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
        function mint() external payable;
        
           /**
     * @notice Send Ether to CEther to mint
     */
        function () external payable;
        
        function borrow(uint borrowAmount) external returns (uint);
        
        function repayBorrow(uint repayAmount) external returns (uint);
        
        function redeemUnderlying(uint redeemAmount) external returns (uint);


}


interface ComptrollerInterface {
    /**
     * @notice Marker function used for light validation when updating the comptroller of a market
     * @dev Implementations should simply return true.
     * @return true
     */
    function isComptroller() external view returns (bool);

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function exitMarket(address cToken) external returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address cToken, address minter, uint mintAmount) external returns (uint);
    function mintVerify(address cToken, address minter, uint mintAmount, uint mintTokens) external;

    function redeemAllowed(address cToken, address redeemer, uint redeemTokens) external returns (uint);
    function redeemVerify(address cToken, address redeemer, uint redeemAmount, uint redeemTokens) external;

    function borrowAllowed(address cToken, address borrower, uint borrowAmount) external returns (uint);
    function borrowVerify(address cToken, address borrower, uint borrowAmount) external;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (uint);
    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex) external;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external returns (uint);
    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens) external;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (uint);
    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external;

    function transferAllowed(address cToken, address src, address dst, uint transferTokens) external returns (uint);
    function transferVerify(address cToken, address src, address dst, uint transferTokens) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint repayAmount) external view returns (uint, uint);
}
contract Connector is Helper {
    
    
    function approve(address spender, uint256 amount) external returns (bool) {
        return IERC20(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa).approve(spender, amount);
    }
    

    function mint() external payable {
        CTokenInterface(0xf92FbE0D3C0dcDAE407923b2Ac17eC223b1084E4).mint.value(msg.value)();
    }
    
        function borrow(uint borrowAmount) external returns (uint) {
            uint amt = CTokenInterface(0xe7bc397DBd069fC7d0109C0636d06888bb50668c).borrow(borrowAmount);
            return amt;
        }
        
    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory) {
        uint[] memory amt = ComptrollerInterface(0x1f5D7F3CaAC149fE41b8bd62A3673FE6eC0AB73b).enterMarkets(cTokens);
        return amt;
    }
    
    /**
     * @dev buying token where destAmt is fixed
     * @param src - token to sell
     * @param dest - token to buy
     * @param srcAmt - token amount to sell
     * @param maxDestAmt is the max amount of token to be bought
     */
    function buy(
        address src,
        address dest,
        uint srcAmt,
        uint maxDestAmt,
        uint slippageRate
    ) public payable returns (uint destAmt)
    {

        destAmt = KyberInterface(getAddressKyber()).trade.value(msg.value)(
            src,
            srcAmt,
            dest,
            msg.sender,
            maxDestAmt,
            slippageRate,
            getAddressAdmin()
        );
    }
}