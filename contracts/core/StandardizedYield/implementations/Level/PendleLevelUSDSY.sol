// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../PendleERC20SYUpg.sol";
import "../../../../interfaces/Level/ILevelMinter.sol";
import {AggregatorV2V3Interface as IChainlinkAggregator} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

contract PendleLevelUSDSY is PendleERC20SYUpg {
    using PMath for uint256;
    using PMath for int256;

    address public constant LVLUSD = 0x7C1156E515aA1A2E851674120074968C905aAF37;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant LEVEL_MINTER = 0x8E7046e27D14d09bdacDE9260ff7c8c2be68a41f;

    constructor() PendleERC20SYUpg(LVLUSD) {}

    function initialize() external initializer {
        _safeApproveInf(USDT, LEVEL_MINTER);
        __SYBaseUpg_init("SY Level USD", "SY-lvlUSD");
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == USDT) {
            uint256 preBalance = _selfBalance(LVLUSD);
            ILevelMinter(LEVEL_MINTER).mintDefault(
                ILevelMinter.Order({
                    order_type: ILevelMinter.OrderType.MINT,
                    benefactor: address(this),
                    beneficiary: address(this),
                    collateral_asset: USDT,
                    collateral_amount: amountDeposited,
                    lvlusd_amount: 0
                })
            );
            return _selfBalance(LVLUSD) - preBalance;
        }
        return amountDeposited;
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual override returns (uint256 amountSharesOut) {
        if (tokenIn == LVLUSD) {
            return amountTokenToDeposit;
        }

        address oracle = ILevelMinter(LEVEL_MINTER).oracles(tokenIn);
        uint8 tokenInDecimals = IERC20Metadata(tokenIn).decimals();
        uint8 oracleDecimals = IChainlinkAggregator(oracle).decimals();

        uint256 price;
        {
            (, int256 _price, , , ) = IChainlinkAggregator(oracle).latestRoundData();
            price = _price.Uint().min(oracleDecimals);
        }
        return (amountTokenToDeposit * price).mulDown(10 ** (tokenInDecimals + oracleDecimals));
    }

    function isValidTokenIn(address token) public pure override returns (bool) {
        return token == LVLUSD || token == USDT;
    }

    function getTokensIn() public pure override returns (address[] memory res) {
        return ArrayLib.create(LVLUSD, USDT);
    }
}
