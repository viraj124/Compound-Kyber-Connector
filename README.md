# Compound-Kyber-Connector
Leverage Functionality Implemented with Kyber & Compound including a Safe Borrow Protocol, leverage provides users to go long on eth, so if eth value increases in the future, it's a good situation to be in.

Save Functionality also implemented to save your position on Compound.

Dapp Flow for Leverage:
Mint CETH on Compound by locking some ETH as collateral
Enter the CDAI & CETH Markets
Borrow Some DAI, based on the safe borrow logic
Make a Trade with ETH on Kyber
Lock the traded ETH again to increase the collateral

Dapp Flow for Save:
Redeem ETH on Compound
Swap with DAI on Kyber
Repay DAI on Compound
