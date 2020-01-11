pragma solidity ^0.5.7;

contract Execute {
    
    function execute(address _target, bytes memory _data)
        public
        payable
        returns (bytes32 response)
    {
        require(_target != address(0));

        // call contract in current context
        assembly {
            let succeeded := delegatecall(sub(gas, 5000), _target, add(_data, 0x20), mload(_data), 0, 32)
            response := mload(0)      // load delegatecall output
            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                revert(0, 0)
            }
        }
    }

function() external payable {}
    
}