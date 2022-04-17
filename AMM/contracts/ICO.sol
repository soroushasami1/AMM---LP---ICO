// SPDX-License-Identifier: GPL-3.
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ICO is ReentrancyGuard {

    struct User {
        uint16 boughtTokens;
        uint256 boughtTime;
    }

    address private owner;
    address private VVAAddress;
    address private BUSD;
    uint256 private rate;
    uint256 private ICO_endTime;
    mapping(address => User) private Users;

    constructor(address _VVAToken, address _BUSD) {
        owner = msg.sender;
        rate = 15 * 10**16; //0.15BUSD
        ICO_endTime = block.timestamp + (75 * 86400);
        VVAAddress = _VVAToken;
        BUSD = _BUSD;
        // BUSD = 0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47; //busd bsc-testnet address
    }

    // check user busd balance
    modifier enoughBalance(uint256 _tokens) {
        uint256 finalPrice = _tokens * rate;
        uint256 balance = IERC20(BUSD).balanceOf(msg.sender);
        require(balance >= finalPrice, "You dont have enough balance");
        _;
    }

    modifier expiredICO() {
        require(block.timestamp < ICO_endTime, "ICO has been expired");
        _;
    }

    modifier enoughVVaTokens(uint256 _tokens) {
        uint256 balance = IERC20(VVAAddress).balanceOf(msg.sender);
        uint256 tokens = _tokens * 10**18;
        require(balance >= tokens, "You dont have enough balance");
        _;
    }

    modifier limitTokens(uint16 _tokens) {
        require(_tokens <= 33333, "you can buy only 5k busd for vva tokens everu day");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not owner");
        _;
    }

    function buyToken(uint16 _tokens)
        external
        expiredICO
        enoughBalance(_tokens)
        limitTokens(_tokens)
        nonReentrant
    {
        User storage user = Users[msg.sender];
        uint256 finalPrice = _tokens * rate;
        uint256 currentTime = uint256(block.timestamp) / uint256(86400);//1401 days
        if (currentTime == user.boughtTime) {
            uint16 total = user.boughtTokens + _tokens;
            require(total <= 33333, "limit for buying token is 5000 every day");
            sendTokens(finalPrice, _tokens);
            user.boughtTokens += _tokens;
        } else {
            sendTokens(finalPrice, _tokens);
            user.boughtTime = currentTime;
            user.boughtTokens = _tokens;
        }
    }

    function sendTokens(uint256 _finalPrice, uint16 _tokens) private {
        IERC20(BUSD).transferFrom(msg.sender, owner, _finalPrice);
        IERC20(VVAAddress).transferFrom(owner, msg.sender, _tokens * 10**18);
    }

    function reward(address _winer, uint256 _tokens)
        external
        onlyOwner
        enoughVVaTokens(_tokens)
    {
        IERC20 IVVAToken = IERC20(VVAAddress);
        IVVAToken.transfer(_winer, _tokens * 10**18);
    }

    function getUser() external view returns (User memory) {
        return Users[msg.sender];
    }

    function currentDay() public view returns(uint256) {
        uint256 currentTime = uint256(block.timestamp) / uint256(86400);//1400 days
        return currentTime;
    }
}
