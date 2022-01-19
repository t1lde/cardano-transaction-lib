const CardanoWasm = require("@emurgo/cardano-serialization-lib-nodejs");


// newBaseAddress :: NetworkId -> PubKeyHash -> StakeKeyHash -> BaseAddress
exports.newBaseAddress = netId => pkhBech32 => skhBech32 => {
    pkh = CardanoWasm.Ed25519KeyHash.from_bech32(pkhBech32);
    if (pkh == null){
        console.error(`error: Ed25519KeyHash.from_bech32(${pkhBech32}) returned null.`);
    }
    skh = CardanoWasm.Ed25519KeyHash.from_bech32(skhBech32);
    if (skh == null) {
        console.error(`error: Ed25519KeyHash.from_bech32(${skhBech32}) returned null.`);
    }
    const addr = CardanoWasm.BaseAddress.new(
        netId,
        CardanoWasm.StakeCredential.from_keyhash(pkh),
        CardanoWasm.StakeCredential.from_keyhash(skh));
    return addr;
};


// addressNetworkId :: BaseAddress -> NetworkIdk
exports.addressNetworkId = baseAddr => {
    return baseAddr.to_address().network_id();
};


// fromBech32 :: (forall x.x -> Maybe x) -> (forall x.Maybe x) -> Bech32String -> Maybe BaseAddress
exports.fromBech32Impl = just => nothing => bech32str => {
    try {
        addr = CardanoWasm.Address.from_bech32(bech32str);
        baseAddr = CardanoWasm.BaseAddress.from_address(addr);
        return just(baseAddr);
    } catch (error) {
        console.log('BaseAddress.fromBech32 failed with error:', error);
        return nothing;
    }
};

// addressBech32 :: BaseAddress -> Bech32String
exports.addressBech32 = baseAddr => {
    return baseAddr.to_address().to_bech32();
};

// addressPubKeyHash :: BaseAddress -> PubKeyHash
exports.addressPubKeyHash = baseAddr => {
    // i've chosen a prefix that Nami uses for payment_creds
    return baseAddr.payment_cred().to_keyhash().to_bech32('hbas_');
};

//addressStakeKeyHash :: BaseAddress -> StakeKeyHash
exports.addressStakeKeyHash = baseAddr => {
    // i've chosen an arbitrary prefix here
    return baseAddr.stake_cred().to_keyhash().to_bech32('hstk_');
};
