# pragma version 0.3.10
# pragma evm-version paris

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

_baseERC20: BaseERC20
deployer: address
owner: public(address)

interface BaseERC20:
    def name() -> String[1000]: view
    def symbol() -> String[100]: view
    def tokenURI(id: uint256) -> String[1000]: view
    def owner() -> address: view
    def totalSupply() -> uint256: view
    def totalNFTSupply() -> uint256: view
    def balanceOf(nftOwner: address) -> uint256: view
    def balanceOfNFT(nftOwner: address) -> uint256: view
    def ownerOf(id: uint256) -> address: view
    def ownerAt(id: uint256) -> address: view
    def approveNFT(spender: address, id: uint256, owner: address) -> address: payable
    def getApproved(id: uint256) -> address: view
    def setApprovalForAll(operator: address, approved: bool, owner: address): payable
    def isApprovedForAll(owner: address, operator: address) -> bool: view
    def transferFromNFT(_from: address, to: address, id: uint256, msgSender: address) -> bool: payable

interface IERC721Receiver:
    def onERC721Received(operator: address, _from: address, id: uint256, data: Bytes[1024]) -> bytes4: payable

@external
def __init__(deployer: address):
    self.deployer = deployer


@external
def name() -> String[1000]:
    return self._getBaseERC20().name()

@external
def symbol() -> String[100]:
    return self._getBaseERC20().symbol()

@external
def tokenURI(id: uint256) -> String[1000]:
    return self._getBaseERC20().tokenURI(id)

@external
def totalSupply() -> uint256:
    return self._getBaseERC20().totalNFTSupply()

@external
def balanceOf(nftOwner: address) -> uint256:
    return self._getBaseERC20().balanceOfNFT(nftOwner)

@external
def ownerOf(id: uint256) -> address:
    return self._getBaseERC20().ownerOf(id)

@external
def ownerAt(id: uint256) -> address:
    return self._getBaseERC20().ownerAt(id)

@internal
def _getBaseERC20() -> BaseERC20:
    if self._baseERC20.address == empty(address):
        raw_revert(method_id("NotLinked()"))
    return self._baseERC20

@external
def baseERC20() -> address:
    return self._getBaseERC20().address


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
    self._getBaseERC20().approveNFT(spender, id, msg.sender)
    log Approval(msg.sender, spender, id)

@external
def getApproved(id: uint256) -> address:
    return self._getBaseERC20().getApproved(id)

@external
def setApprovalForAll(operator: address, approved: bool):
    self._getBaseERC20().setApprovalForAll(operator, approved, msg.sender)
    log ApprovalForAll(msg.sender, operator, approved)

@external
def isApprovedForAll(owner: address, operator: address) -> bool:
    return self._getBaseERC20().isApprovedForAll(owner, operator)

@external
def transferFrom(_from: address, to: address, id: uint256):
    assert self._getBaseERC20().transferFromNFT(_from, to, id, msg.sender)
    log Transfer(_from, to, id)

@external
def safeTransferFrom(_from: address, to: address, id: uint256):
    assert self._getBaseERC20().transferFromNFT(_from, to, id, msg.sender)
    log Transfer(_from, to, id)
    if to.codehash != empty(bytes32):
        # IERC721Receiver(to).onERC721Received(msg.sender, _from, id, b"")
        succ: bool = False
        resp: Bytes[32] = b""
        # succ, resp = raw_call(to, method_id("onERC721Received(address,address,uint256,bytes)"), concat(convert(msg.sender, bytes), convert(_from, bytes), convert(id, bytes), b""), max_outsize=32, value=0, gas=50000)
        succ, resp = raw_call(to, _abi_encode(msg.sender, _from, id, b"", method_id=method_id("onERC721Received(address,address,uint256,bytes)")), gas=50000, value=0, max_outsize=32, revert_on_failure=False)
        if not succ or resp != b"0x150b7a02":
            raw_revert(method_id("TransferToNonERC721ReceiverImplementer()"))


@payable
@external
def pullOwner() -> bool:
    succ: bool = False
    resp: Bytes[32] = b""
    succ, resp = raw_call(self._getBaseERC20().address, method_id("owner()"), max_outsize=32, revert_on_failure=False)
    if succ:
        base_owner: address = _abi_decode(resp, address)
        if base_owner != self.owner:
            old_owner: address = self.owner
            self.owner = base_owner
            log OwnershipTransferred(old_owner, base_owner)
    return True

@external
def supportsInterface(interfaceID: bytes4) -> bool:
    return interfaceID in [0x01ffc9a7, 0x80ac58cd, 0x5b5e139f]

@external
def linkMirrorContract(link: address) -> bool:
    if self.deployer != empty(address):
        if link != self.deployer:
            raw_revert(method_id("SenderNotDeployer()"))
    if self._baseERC20.address != empty(address):
        raw_revert(method_id("AlreadyLinked()"))
    self._baseERC20 = BaseERC20(msg.sender)
    return True

@external
def logTransfer(logs: DynArray[uint256, 100]) -> bool:
    for plog in logs:
        addr: address = convert(plog >> 96, address)
        id: uint256 = (plog << 160) >> 168
        is_burn: bool = convert(plog & 1, bool)
        if is_burn:
            log Transfer(addr, empty(address), id)
        else:
            log Transfer(empty(address), addr, id)
    return True

@external
def logDirectTransfer(_from: address, to: address, ids: DynArray[uint256, 100]) -> bool:
    for id in ids:
        log Transfer(_from, to, id)
    return True

@external
def __default__():
    raw_revert(method_id("FnSelectorNotRecognized()"))
