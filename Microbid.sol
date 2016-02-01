contract Microbid {
  
    mapping(address => uint256) timestamps;
    
    uint256 channelid = 0;
    
    Channel[] public channels;
    
    struct Channel {
        address sender;
        address receiver;
        uint256 value;
        uint256 expiry;
        bool valid;
    }
    
    event ChannelCreate(uint256 id, address indexed sender, address indexed receiver, uint256 value, uint256 expiry);
    
    function channelCreate(address receiver, uint256 expiry) {
        channels.push(Channel(msg.sender, receiver, msg.value, expiry, true));
        ChannelCreate(channelid++, msg.sender, receiver, msg.value, expiry);
    }
    
    event ChannelIncrement(uint256 indexed id, address indexed receiver, uint256 value);
    
    function channelIncrement(uint256 id) {
        Channel c = channels[id];
        if (!c.valid) throw;
        c.value += msg.value;
        ChannelIncrement(id, c.receiver, c.value);
    }
    
    event ChannelRedeem(uint256 id, address indexed receiver, uint256 value);
    
    function channelRedeem(uint256 realstart, uint256 realend, uint256 bidchannelid, uint256 bidstart, uint256 bidend, uint256 bidrandomblock, uint256 bidprobability, uint256 bidvalue, byte v, bytes32 r, bytes32 s) {
      
        //include vrs in hash?
        bytes32 h = sha3(bidchannelid, bidstart, bidend, bidrandomblock, bidprobability, bidvalue);
        address a = ecrecover(h, (uint8)(v), r, s);
        if (c.sender != a) throw;
        
        Channel c = channels[bidchannelid];
        if (!c.valid) throw;
        if (msg.sender != c.receiver) throw;
        
        if (realstart>realend || bidstart>bidend || realstart<bidstart || realend>bidend) throw;
        if (realstart < timestamps[c.receiver] || bidend < timestamps[c.receiver]) throw;    
        
        if (bidprobability<(uint256)(block.blockhash(bidrandomblock))) throw;
        
        timestamps[c.receiver] = bidend;
        
        uint256 total = bidvalue*(bidend-bidstart);
        if (total>c.value) throw;
        
        c.receiver.send(total);
        
        
        ChannelRedeem(bidchannelid, c.receiver, bidvalue);
    }
    
    event ChannelClose(uint256 indexed id, address indexed receiver);
    
    function channelClose(uint256 id) {
        Channel c = channels[id];
        if (msg.sender!=c.sender || c.expiry<now) throw;
        c.sender.send(c.value);
        ChannelClose(id, c.receiver);
        c.valid = false;
    }

}    
