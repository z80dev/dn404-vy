# pragma version ^0.3.10
"""
@title DN404 Implementation
@custom:contract-name DN404
@license GNU Affero General Public License v3.0 only
@author z80
"""

event Transfer:
    _from: indexed(address)
    to: indexed(address)
    amount: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    amount: uint256

event SkipNFTSet:
    owner: indexed(address)
    status: bool
