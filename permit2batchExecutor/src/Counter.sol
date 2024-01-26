// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

contract Permit2Executor {
    function execute(address target, bytes memory data) external payable {
        (bool success, bytes memory returndata) = target.call{value: msg.value}(data);
        require(success, string(returndata));
    }
}
