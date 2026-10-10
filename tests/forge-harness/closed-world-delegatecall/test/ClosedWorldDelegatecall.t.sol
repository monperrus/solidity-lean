// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Proxy, CallProxy, Impl, User} from "../src/ClosedWorldDelegatecall.sol";

/// Ground truth (solc 0.8.35 / Foundry EVM): a DELEGATECALL runs the implementation's
/// code on the proxy's storage, address and balance, with the proxy frame's
/// msg.sender and msg.value; a CALL runs it on the implementation's own.
contract ClosedWorldDelegatecallForgeTest {
    function testDelegatecallUsesProxyFrame() public {
        Impl impl = new Impl();
        Proxy proxy = new Proxy(address(impl));
        User user = new User();
        user.go{value: 3}(address(proxy), 5);
        Impl viaProxy = Impl(address(proxy));
        require(viaProxy.x() == 5, "x in proxy storage");
        require(viaProxy.lastSender() == address(user), "msg.sender inherited");
        require(viaProxy.lastValue() == 3, "msg.value inherited");
        require(viaProxy.self() == address(proxy), "address(this) is the proxy");
        require(viaProxy.bal() == 3, "balance is the proxy's");
        require(impl.x() == 0 && impl.lastSender() == address(0), "impl storage untouched");
        require(user.got() == 50, "return data propagates");
        require(address(proxy).balance == 3 && address(impl).balance == 0, "value stays in proxy");
    }

    function testCallWritesCalleeStorage() public {
        Impl impl = new Impl();
        CallProxy proxy = new CallProxy(address(impl));
        User user = new User();
        user.go{value: 3}(address(proxy), 5);
        require(impl.x() == 5, "x in impl storage");
        require(impl.lastSender() == address(proxy), "msg.sender is the proxy");
        require(impl.lastValue() == 0, "no value forwarded");
        require(impl.self() == address(impl), "address(this) is the impl");
        require(user.got() == 50, "return data propagates");
    }
}
