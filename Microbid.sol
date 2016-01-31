contract Microbid {
  
    mapping(address => uint256) timestamps;
    
    uint256 channelid = 0;
    
    Channel[] public channels;
    
    struct Channel {
        address owner;
        address target;
        uint256 value;
        uint256 expiry;
        bool valid;
    }
    
    event ChannelCreate(uint256 id, address indexed owner, address indexed target, uint256 value, uint256 expiry);
    
    function channelCreate(address target, uint256 expiry) {
        channels.push(Channel(msg.sender, target, msg.value, expiry, true));
        ChannelCreate(channelid++, msg.sender, target, msg.value, expiry);
    }
    
    event ChannelIncrement(uint256 indexed id, address indexed target, uint256 value);
    
    function channelIncrement(uint256 id) {
        Channel c = channels[id];
        if (!c.valid) throw;
        c.value += msg.value;
        ChannelIncrement(id, c.target, c.value);
    }
    
    event ChannelRedeem(uint256 id, address indexed target, uint256 value);
    
    function channelRedeem(uint256 realstart, uint256 realend, uint256 bidchannelid, uint256 bidstart, uint256 bidend, uint256 bidrandomblock, uint256 bidprobability, uint256 bidvalue, byte v, bytes32 r, bytes32 s) {
      
        //include vrs in hash?
        bytes32 h = sha3(bidchannelid, bidstart, bidend, bidrandomblock, bidprobability, bidvalue);
        address a = ecrecover(h, (uint8)(v), r, s);
        if (c.owner != a) throw;
        
        Channel c = channels[bidchannelid];
        if (!c.valid) throw;
        if (msg.sender != c.target) throw;
        
        if (realstart>realend || bidstart>bidend || realstart<bidstart || realend>bidend) throw;
        if (realstart < timestamps[c.target] || bidend < timestamps[c.target]) throw;    
        
        if (bidprobability<(uint256)(block.blockhash(bidrandomblock))) throw;
        
        timestamps[c.target] = bidend;
        
        uint256 total = bidvalue*(bidend-bidstart);
        if (total>c.value) throw;
        
        c.target.send(total);
        
        
        ChannelRedeem(bidchannelid, c.target, bidvalue);
    }
    
    event ChannelClose(uint256 indexed id, address indexed target);
    
    function channelClose(uint256 id) {
        Channel c = channels[id];
        if (msg.sender!=c.owner || c.expiry<now) throw;
        c.owner.send(c.value);
        ChannelClose(id, c.target);
        c.valid = false;
    }

}
