// SPDX-License-Identifier: GPL-3.
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LP is ERC20 {
    constructor(uint256 _supply) ERC20("PAIR_VVA_BUSD", "PVB") {
        _mint(msg.sender, _supply * (10 ** decimals()));
    }
}
