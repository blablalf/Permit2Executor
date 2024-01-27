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

// Libs
using SafeERC20 for IERC20;

struct Permit2Params {
    uint256 amount;
    uint256 nonce;
    uint256 deadline;
    address token;
    bytes signature;
}

contract Permit2Executor is Pausable, Ownable2Step {
    // Storage
    IPermit2 public immutable PERMIT2; // The canonical permit2 contract.
    address public router;
    IERC20[] public supportedTokens;
    mapping(address token => bool isSupported) public isTokenSupported;

    // Errors
    error NotSupportedToken(address token);
    error AlreadySupportedToken(address token);

    modifier onlyOwnerIfPaused() {
        if (paused() && owner() != _msgSender())
            revert OwnableUnauthorizedAccount(_msgSender());
        _;
    }

    constructor(IPermit2 _permit2, address _router) Ownable(_msgSender()) {
        PERMIT2 = _permit2;
        router = _router;
    }

    function setRouter(address _router) external onlyOwner {
        router = _router;
    }

    function changeRouterAndAllowance(address _router) external onlyOwner {
        router = _router;
        IERC20[] memory _supportedTokens = supportedTokens;
        revokeApprovals();
        approveNewTokens(_supportedTokens);
    }

    function execSwapWithPermit2(Permit2Params calldata permit2Params) external whenNotPaused {
        if (!isTokenSupported[permit2Params.token])
            revert NotSupportedToken(permit2Params.token);
        _execPermit2(permit2Params);

        // todo odos single swap by taking care to take the permit owner and not the msg.sender
    }

    function execSwapBatchWithPermit2(
        ISignatureTransfer.PermitBatchTransferFrom memory permit,
        ISignatureTransfer.SignatureTransferDetails[] calldata transferDetails,
        bytes calldata signature
    ) external whenNotPaused {
        for (uint256 i = 0; i < permit.permitted.length; i++) {
            address tokenAddress = permit.permitted[i].token;
            if (!isTokenSupported[tokenAddress])
                revert NotSupportedToken(tokenAddress);
        }
        _execPermit2Batch(permit, transferDetails, signature);

        // todo odos batched swap by taking care to take the permit owner and not the msg.sender
    }

    function approveNewTokens(IERC20[] memory tokens) public onlyOwnerIfPaused {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = tokens[i];
            if (!isTokenSupported[address(token)]) {
                token.forceApprove(router, type(uint256).max);
                supportedTokens.push(token);
                isTokenSupported[address(token)] = true;
            }
        }
    }

    function revokeApproval(IERC20 token) public onlyOwner {
        if (isTokenSupported[address(token)]) {
            token.forceApprove(router, 0);
            isTokenSupported[address(token)] = false;
        }
    }
    
    function revokeApprovals(IERC20[] memory tokens) public {
        for (uint256 i = 0; i < tokens.length; i++) {
            revokeApproval(tokens[i]);
        }
    }

    function revokeApprovals() public {
        revokeApprovals(supportedTokens);
    }

    // Deposit some amount of an ERC20 token into this contract
    // using Permit2.
    function _execPermit2(Permit2Params calldata permit2Params) internal {
        // Transfer tokens from the caller to ourselves.
        PERMIT2.permitTransferFrom(
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

    /*
     * @dev Withdraws tokens from this contract to the caller.
     * @notice ISignatureTransfer.SignatureTransferDetails({
     *           to: address(this),
     *           requestedAmount: theAmountYouNeedForThisTokenIndex
     *       }),
     * @param token The token to withdraw.
     * @param amount The amount to withdraw.
     */
    function _execPermit2Batch(
        ISignatureTransfer.PermitBatchTransferFrom memory permit,
        ISignatureTransfer.SignatureTransferDetails[] calldata transferDetails,
        bytes calldata signature
    ) internal {
        PERMIT2.permitTransferFrom(
            permit,
            transferDetails,
            _msgSender(),
            signature
        );
    }

}
