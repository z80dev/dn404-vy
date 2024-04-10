# pragma version 0.3.10

event Transfer:
    _from: indexed(address)
    to: indexed(address)
    id: indexed(uint256)

event Approval:
    owner: indexed(address)
    approved: indexed(address)
    id: indexed(uint256)

event ApprovalForAll:
    owner: indexed(address)
    operator: indexed(address)
    approved: bool

event OwnershipTransferred:
    oldOwner: indexed(address)
    newOwner: indexed(address)

baseERC20: address
deployer: address
owner: address

interface BaseERC20:
    def name() -> String[100]: view
    def symbol() -> String[10]: view
    def tokenURI(id: uint256) -> String[100]: view
    def totalSupply() -> uint256: view
    def balanceOf(nftOwner: address) -> uint256: view
    def ownerOf(id: uint256) -> address: view
    def ownerAt(id: uint256) -> address: view
    def approveNFT(spender: address, id: uint256, owner: address): payable
    def getApproved(id: uint256) -> address: view

@external
def __init__(deployer: address):
    self.deployer = deployer

# @dev Sets `spender` as the approved account to manage token `id` in
# the base DN404 contract.
#
# Requirements:
# - Token `id` must exist.
# - The caller must be the owner of the token,
#   or an approved operator for the token owner.
#
# Emits an {Approval} event.
@external
def approve(spender: address, id: uint256):
    tokenOwner = self.ownerAt(id)
    assert msg.sender == tokenOwner or self.isApprovedForAll(tokenOwner, msg.sender)
    self.Approval(tokenOwner, spender, id)

@external
def getApproved(id: uint256) -> address:
    return self.baseERC20.getApproved(id)
