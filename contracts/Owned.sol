//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//pragma solidity >= 0.6.6;

contract Owned {
    address public owner;
    mapping(address=>bool) minter;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Owned: only owner can do it");
        _;
    }

    modifier mintable {
        require(minter[msg.sender]==true, "Mint: only Minter can do it");
        _;
    }

    function transferOwnership(address _owner) public virtual onlyOwner {
        require(_owner != address(0), "Owned: set zero address to owner");
        owner = _owner;

        emit OwnershipTransferred(owner, _owner);
    }

    function addMinter(address _addr) external onlyOwner returns(bool) {
        require(_addr !=address(0), "Mint: add addr is zero");
        minter[_addr] = true;
        return true;
    }

    function removeMinter(address _addr) external onlyOwner returns(bool) {
        require(_addr != address(0), "Mint: remove addr zero");
        minter[_addr] = false;
        return true;
    }
}