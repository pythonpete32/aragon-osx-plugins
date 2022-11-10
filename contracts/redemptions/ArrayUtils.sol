// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library ArrayUtils {
    function deleteItem(address[] storage self, address item) internal returns (bool) {
        uint256 length = self.length;
        for (uint256 i = 0; i < length; i++) {
            if (self[i] == item) {
                self[i] = self[self.length - 1];
                self.pop();
                return true;
            }
        }
        return false;
    }
}
