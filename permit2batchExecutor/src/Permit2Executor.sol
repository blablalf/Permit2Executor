// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {
    IPermit2, ISignatureTransfer
} from "permit2/src/interfaces/IPermit2.sol";
import {
    Ownable,
    Ownable2Step
} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {
    ERC20
} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from
    "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Pausable } from
    "@openzeppelin/contracts/utils/Pausable.sol";

struct Permit2Params {
    uint256 amount;
    uint256 nonce;
    uint256 deadline;
    address token;
    bytes signature;
}

contract Permit2Executor is Pausable, Ownable2Step {

    constructor() Ownable(_msgSender()) {}

}
