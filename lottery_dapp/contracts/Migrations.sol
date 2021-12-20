// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Migrations {
    address public owner = msg.sender;
    uint256 public last_completed_migration;

    modifier restricted() {
        require(
            msg.sender == owner,
            "This function is restricted to the contract's owner"
        );
        _;
    }

    //버전관리, 몇번째 디플로이 스크립트까지 사용했는지 uint completed
    function setCompleted(uint256 completed) public restricted {
        last_completed_migration = completed;
    }
}
