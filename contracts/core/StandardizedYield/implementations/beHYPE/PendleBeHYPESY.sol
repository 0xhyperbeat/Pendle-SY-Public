// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../v2/SYBaseUpgV2.sol";
import "../../../../interfaces/BeHYPE/IStakingCore.sol";
import "../../../../interfaces/IWETH.sol";

contract PendleBeHYPESY is SYBaseUpgV2 {
    using PMath for uint256;

    address public constant BEHYPE = 0xd8FC8F0b03eBA61F64D08B0bef69d80916E5DdA9;
    address public constant STAKING_CORE = 0xCeaD893b162D38e714D82d06a7fe0b0dc3c38E0b;
    address public constant WHYPE = 0x5555555555555555555555555555555555555555;

    constructor() SYBaseUpgV2(BEHYPE) {}

    function initialize(address _owner) external virtual initializer {
        __SYBaseUpgV2_init("SY BeHYPE", "SY-beHYPE", _owner);
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == yieldToken) {
            return amountDeposited;
        }
        if (tokenIn == WHYPE) {
            IWETH(WHYPE).withdraw(amountDeposited);
        }

        uint256 preBalance = _selfBalance(yieldToken);
        IStakingCore(STAKING_CORE).stake{value: amountDeposited}("");
        return _selfBalance(yieldToken) - preBalance;
    }

    function _redeem(
        address receiver,
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256) {
        _transferOut(yieldToken, receiver, amountSharesToRedeem);
        return amountSharesToRedeem;
    }

    function exchangeRate() public view virtual override returns (uint256) {
        return IStakingCore(STAKING_CORE).BeHYPEToHYPE(1 ether);
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == NATIVE) {
            return IStakingCore(STAKING_CORE).HYPEToBeHYPE(amountTokenToDeposit);
        }
        return amountTokenToDeposit;
    }

    function _previewRedeem(
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal view virtual override returns (uint256 /*amountTokenOut*/) {
        return amountSharesToRedeem;
    }

    function getTokensIn() public view virtual override returns (address[] memory res) {
        return ArrayLib.create(NATIVE, yieldToken, WHYPE);
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        return ArrayLib.create(yieldToken);
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == NATIVE || token == yieldToken || token == WHYPE;
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == yieldToken;
    }

    function assetInfo()
        external
        view
        virtual
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, NATIVE, 18);
    }
}
