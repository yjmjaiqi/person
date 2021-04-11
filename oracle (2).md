pragma solidity ^0.6.0;

/**
 * @title CheckpointOracle
 * @author Gary Rong<garyrong@ethereum.org>, Martin Swende <martin.swende@ethereum.org>
 * @dev Implementation of the blockchain checkpoint registrar.
 */
contract CheckpointOracle {
    /*
        Events
    */

    // NewCheckpointVote is emitted when a new checkpoint proposal receives a vote.
    event NewCheckpointVote(uint64 indexed index, bytes32 checkpointHash, uint8 v, bytes32 r, bytes32 s);
    //发送一个事件
    /*
        Public Functions
    */
    constructor(address[] memory _adminlist, uint _sectionSize, uint _processConfirms, uint _threshold) public {//构造一个函数
        for (uint i = 0; i < _adminlist.length; i++) {//循环遍历
            admins[_adminlist[i]] = true;//管理员验证
            adminList.push(_adminlist[i]);
        }
        sectionSize = _sectionSize;
        processConfirms = _processConfirms;
        threshold = _threshold;//赋值
    }
    //

    /**
     * @dev Get latest stable checkpoint information.
     * @return section index
     * @return checkpoint hash
     * @return block height associated with checkpoint
     */
    function GetLatestCheckpoint()
    view
    public
    returns(uint64, bytes32, uint) {
        return (sectionIndex, hash, height);//创建一个公开函数返回值类型分别为returns的类型
    }

    // SetCheckpoint sets  a new checkpoint. It accepts a list of signatures
    // @_recentNumber: a recent blocknumber, for replay protection
    // @_recentHash : the hash of `_recentNumber`
    // @_hash : the hash to set at _sectionIndex
    // @_sectionIndex : the section index to set
    // @v : the list of v-values
    // @r : the list or r-values
    // @s : the list of s-values
    function SetCheckpoint(
        uint _recentNumber,
        bytes32 _recentHash,
        bytes32 _hash,
        uint64 _sectionIndex,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s)
        public
        returns (bool)//创建一个函数返回bool类型
    {
        // Ensure the sender is authorized.
        require(admins[msg.sender]);//管理员授权

        // These checks replay protection, so it cannot be replayed on forks,
        // accidentally or intentionally
        require(blockhash(_recentNumber) == _recentHash);//这些检查重放保护，所以不能在fork上重放，

        // Ensure the batch of signatures are valid.
        require(v.length == r.length);//确保身份有效
        require(v.length == s.length);

        // Filter out "future" checkpoint.
        if (block.number < (_sectionIndex+1)*sectionSize+processConfirms) {//过滤掉“未来”检查点。
            return false;
        }
        // Filter out "old" announcement
        if (_sectionIndex < sectionIndex) {//过滤旧公告
            return false;
        }
        // Filter out "stale" announcement
        if (_sectionIndex == sectionIndex && (_sectionIndex != 0 || height != 0)) {//过滤掉“过时”公告


            return false;
        }
        // Filter out "invalid" announcement//过滤无效公告
        if (_hash == ""){
            return false;
        }

        // EIP 191 style signatures
        //
        // Arguments when calculating hash to validate
        // 1: byte(0x19) - the initial 0x19 byte
        // 2: byte(0) - the version byte (data with intended validator)
        // 3: this - the validator address
        // --  Application specific data
        // 4 : checkpoint section_index(uint64)
        // 5 : checkpoint hash (bytes32)
        //     hash = keccak256(checkpoint_index, section_head, cht_root, bloom_root)
        bytes32 signedHash = keccak256(abi.encodePacked(byte(0x19), byte(0), this, _sectionIndex, _hash));//类型转换

        address lastVoter = address(0);

        // In order for us not to have to maintain a mapping of who has already
        // voted, and we don't want to count a vote twice, the signatures must
        // be submitted in strict ordering.
        for (uint idx = 0; idx < v.length; idx++){
            address signer = ecrecover(signedHash, v[idx], r[idx], s[idx]);//为了让我们不必保持一个谁已经投票，我们不想数到两次，签名必须严格按顺序提交。
            require(admins[signer]);
            require(uint256(signer) > uint256(lastVoter));
            lastVoter = signer;
            emit NewCheckpointVote(_sectionIndex, _hash, v[idx], r[idx], s[idx]);

            // Sufficient signatures present, update latest checkpoint.
            if (idx+1 >= threshold){//存在足够的签名，更新最新的检查点。
                hash = _hash;
                height = block.number;
                sectionIndex = _sectionIndex;
                return true;
            }
        }
        // We shouldn't wind up here, reverting un-emits the events
        revert();//我们不应该在这里结束，恢复un-emits的事件
    }

    /**
     * @dev Get all admin addresses
     * @return address list
     */
    function GetAllAdmin()
    public
    view
    returns(address[] memory)//返回地址数组的函数
    {
        address[] memory ret = new address[](adminList.length);
        for (uint i = 0; i < adminList.length; i++) {
            ret[i] = adminList[i];//遍历
        }
        return ret;
    }

    /*
        Fields
    */
    // A map of admin users who have the permission to update CHT and bloom Trie root
    mapping(address => bool) admins;//地址映射

    // A list of admin users so that we can obtain all admin users.
    address[] adminList;//管理员用户列表，以便我们可以获得所有管理员用户。

    // Latest stored section id
    uint64 sectionIndex;//最新存储部分id

    // The block height associated with latest registered checkpoint.
    uint height;//与最新注册的检查点关联的块高度。

    // The hash of latest registered checkpoint.
    bytes32 hash;//最新注册的检查点的哈希。

    // The frequency for creating a checkpoint
    //
    // The default value should be the same as the checkpoint size(32768) in the ethereum.
    uint sectionSize;//创建检查点的频率默认值应与以太坊中的检查点sise(32768)相同。

    // The number of confirmations needed before a checkpoint can be registered.
    // We have to make sure the checkpoint registered will not be invalid due to
    // chain reorg.
    //
    // The default value should be the same as the checkpoint process confirmations(256)
    // in the ethereum.
    uint processConfirms;//注册检查点之前所需的确认数。我们必须确保注册的检查点不会因为链重组。默认值应与检查点进程确认（256）相同在以太坊。

    // The required signatures to finalize a stable checkpoint.
    uint threshold;//完成稳定检查点所需的签名。
}
