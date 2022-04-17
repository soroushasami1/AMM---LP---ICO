// SPDX-License-Identifier: GPL-3.
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AMM is ReentrancyGuard {
    address private VVAToken;
    address private BUSDToken;
    address private LPToken;
    uint256 private totalLPToken;
    uint256 fee;

    event successSwap(bool submited, uint256 amount, string message);

    constructor(
        address _VVAToken,
        address _BUSDToken,
        address _LPToken
    ) {
        VVAToken = _VVAToken;
        BUSDToken = _BUSDToken;
        LPToken = _LPToken;
        fee = 4 * 10**15;
    }

    modifier enoughVVA(uint256 _amount) {
        uint256 VVABalance = IERC20(VVAToken).balanceOf(msg.sender);
        uint256 amount = _amount * 10**18;
        require(
            VVABalance >= amount && amount != 0,
            "You dont have enough VVA token"
        );
        _;
    }

    modifier enoughBUSD(uint256 _amount) {
        uint256 BUSDBalance = IERC20(BUSDToken).balanceOf(msg.sender);
        uint256 amount = _amount * 10**18;
        require(
            BUSDBalance >= amount && amount != 0,
            "You dont have enough BUSD token"
        );
        _;
    }

    modifier enoughLP(uint256 _amount) {
        uint256 LPBalance = IERC20(LPToken).balanceOf(msg.sender);
        uint256 amount = _amount * 10**18;
        require(
            LPBalance >= amount && amount != 0,
            "You dont have enough BUSD token"
        );
        _;
    }

    function addLiquidity(uint256 _VVAs, uint256 _BUSDs)
        public
        enoughVVA(_VVAs)
        enoughBUSD(_BUSDs)
        nonReentrant
    {
        if (totalLPToken == 0) {
            totalLPToken = 1000;
            totalLPToken = totalLPToken + 1000;
            transfers(_VVAs, _BUSDs, 1000);
        } else {
            uint256 VVABalance = IERC20(VVAToken).balanceOf(address(this)); // contract vva balance
            uint256 BUSDBalance = IERC20(BUSDToken).balanceOf(address(this)); // contract busd balance
            uint256 amountLPToken_VVA = totalLPToken * (_VVAs / VVABalance);
            uint256 amountLPToken_BUSD = totalLPToken * (_BUSDs / BUSDBalance);
            require(
                amountLPToken_VVA == amountLPToken_BUSD,
                "values are incorrect"
            );
            uint256 LPAmount = amountLPToken_VVA;
            transfers(_VVAs, _BUSDs, LPAmount);
        }
    }

    function transfers(
        uint256 _VVAs,
        uint256 _BUSDs,
        uint256 _LPs
    ) private {
        IERC20(BUSDToken).transferFrom(
            msg.sender,
            address(this),
            _BUSDs * 10**18
        );
        IERC20(VVAToken).transferFrom(
            msg.sender,
            address(this),
            _VVAs * 10**18
        );
        IERC20 LP = IERC20(LPToken);
        LP.transfer(msg.sender, _LPs * 10**18);
    }

    function removeLiquidity(uint256 _LPs) public enoughLP(_LPs) nonReentrant {
        uint256 VVABalance = IERC20(VVAToken).balanceOf(address(this)); // contract vva balance
        uint256 BUSDBalance = IERC20(BUSDToken).balanceOf(address(this)); // contract busd balance
        uint256 rate = _LPs / totalLPToken;
        uint256 VVAAmount = rate * VVABalance;
        uint256 BUSDAmount = rate * BUSDBalance;
        totalLPToken = totalLPToken - _LPs;
        IERC20(LPToken).transferFrom(msg.sender, address(this), _LPs * 10**18);
        IERC20 BUSD = IERC20(BUSDToken);
        IERC20 VVA = IERC20(VVAToken);
        VVA.transfer(msg.sender, VVAAmount * 10**18);
        BUSD.transfer(msg.sender, BUSDAmount * 10**18);
    }

    function swapVVA(uint256 _VVAs) public enoughVVA(_VVAs) nonReentrant {
        uint256 VVABalance = IERC20(VVAToken).balanceOf(address(this));
        uint256 BUSDBalance = IERC20(BUSDToken).balanceOf(address(this));
        uint256 constantProduct = VVABalance * BUSDBalance;
        uint256 totalVVAsAfter = _VVAs + VVABalance;
        uint256 totalBUSDsAfter = constantProduct / totalVVAsAfter;
        uint256 BUSDAmount = BUSDBalance - totalBUSDsAfter;
        uint256 priceBUSD = totalVVAsAfter / totalBUSDsAfter; //event
        IERC20(VVAToken).transferFrom(
            msg.sender,
            address(this),
            _VVAs * 10**18
        );
        IERC20 BUSD = IERC20(BUSDToken);
        BUSD.transfer(msg.sender, BUSDAmount * 10**18);
        emit successSwap(true, priceBUSD, "price of your swap");
    }

    function swapBUSD(uint256 _BUSDs) public nonReentrant {
        uint256 VVABalance = IERC20(VVAToken).balanceOf(address(this));
        uint256 BUSDBalance = IERC20(BUSDToken).balanceOf(address(this));
        uint256 constantProduct = VVABalance * BUSDBalance;
        uint256 totalBUSDsAfter = _BUSDs + BUSDBalance;
        uint256 totalVVAsAfter = constantProduct / totalBUSDsAfter;
        uint256 VVAAmount = VVABalance - totalVVAsAfter;
        uint256 priceVVA = totalBUSDsAfter / totalVVAsAfter; //event
        IERC20(BUSDToken).transferFrom(
            msg.sender,
            address(this),
            _BUSDs * 10**18
        );
        IERC20 VVA = IERC20(VVAToken);
        VVA.transfer(msg.sender, VVAAmount * 10**18);
        emit successSwap(true, priceVVA, "price of your swap");
    }
}
