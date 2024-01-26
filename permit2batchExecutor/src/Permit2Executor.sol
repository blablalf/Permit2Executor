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
    IERC20
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

    using SafeERC20 for IERC20;

    // Storage

    // The canonical permit2 contract.
    IPermit2 public immutable permit2;
    address public router;
    IERC20[] public supportedTokens;
    mapping(address => bool) public isTokenSupported;

    constructor(IPermit2 _permit2) Ownable(_msgSender()) {
        permit2 = _permit2;
    }

    // Deposit some amount of an ERC20 token into this contract
    // using Permit2.
    function execPermit2(Permit2Params calldata permit2Params) internal {
        // Transfer tokens from the caller to ourselves.
        permit2.permitTransferFrom(
            // The permit message.
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({
                    token: permit2Params.token,
                    amount: permit2Params.amount
                }),
                nonce: permit2Params.nonce,
                deadline: permit2Params.deadline
            }),
            // The transfer recipient and amount.
            ISignatureTransfer.SignatureTransferDetails({
                to: address(this),
                requestedAmount: permit2Params.amount
            }),
            // The owner of the tokens, which must also be
            // the signer of the message, otherwise this call
            // will fail.
            _msgSender(),
            // The packed signature that was the result of signing
            // the EIP712 hash of `permit`.
            permit2Params.signature
        );
    }

    function approveNewTokens(IERC20[] memory tokens) external {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = tokens[i];
            //token.safeApprove(address(permit2), type(uint256).max);
        }
    }

}
