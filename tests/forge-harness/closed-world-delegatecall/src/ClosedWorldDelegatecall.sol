// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

interface ISet {
    function set(uint256 v) external payable returns (uint256);
}

/// Forwards every call to `impl` with DELEGATECALL, without inline assembly.
contract Proxy {
    address public impl;

    constructor(address impl_) {
        impl = impl_;
    }

    fallback(bytes calldata d) external payable returns (bytes memory) {
        (bool ok, bytes memory r) = impl.delegatecall(d);
        require(ok);
        return r;
    }
}

/// Contrast: the same forwarding with CALL, so the callee writes its own storage.
contract CallProxy {
    address public impl;

    constructor(address impl_) {
        impl = impl_;
    }

    fallback(bytes calldata d) external payable returns (bytes memory) {
        (bool ok, bytes memory r) = impl.call(d);
        require(ok);
        return r;
    }
}

/// Slot 0 mirrors the proxies' `impl`; the other fields record the executing frame.
contract Impl {
    address private implSlot;
    uint256 public x;
    address public lastSender;
    uint256 public lastValue;
    address public self;
    uint256 public bal;

    event Set(uint256 v, uint256 x);

    function set(uint256 v) external payable returns (uint256) {
        x += v;
        lastSender = msg.sender;
        lastValue = msg.value;
        self = address(this);
        bal = address(this).balance;
        emit Set(v, x);
        return x * 10;
    }
}

contract User {
    uint256 public got;

    function go(address p, uint256 v) external payable {
        got = ISet(p).set{value: msg.value}(v);
    }
}
