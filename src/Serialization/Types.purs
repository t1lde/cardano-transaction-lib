module Serialization.Types
  ( BigInt
  , Bip32PublicKey
  , BigNum
  , Value
  , AuxiliaryData
  , Transaction
  , TransactionBody
  , Mint
  , MintAssets
  , TransactionWitnessSet
  , TransactionHash
  , TransactionInput
  , TransactionInputs
  , TransactionOutput
  , TransactionOutputs
  , TransactionUnspentOutput
  , MultiAsset
  , Assets
  , AssetName
  , DataHash
  , Vkeywitnesses
  , Vkeywitness
  , Vkey
  , Ed25519Signature
  , PublicKey
  , PlutusScript
  , PlutusScripts
  , NativeScript
  , NativeScripts
  , NetworkId
  , ScriptPubkey
  , ScriptAll
  , ScriptAny
  , ScriptNOfK
  , TimelockStart
  , TimelockExpiry
  , BootstrapWitnesses
  , BootstrapWitness
  , ConstrPlutusData
  , PlutusList
  , PlutusMap
  , PlutusData
  , Redeemers
  , Redeemer
  , RedeemerTag
  , ExUnits
  , Costmdls
  , CostModel
  , Language
  , Int32
  , ScriptDataHash
  , Certificates
  , Certificate
  , VRFKeyHash
  , UnitInterval
  , Ed25519KeyHashes
  , Relay
  , Relays
  , Ipv4
  , Ipv6
  , PoolMetadata
  , GenesisHash
  , GenesisDelegateHash
  , MoveInstantaneousReward
  , MIRToStakeCredentials
  , Withdrawals
  ) where

import Prelude
import Data.Function (on)

foreign import data BigInt :: Type
foreign import data Bip32PublicKey :: Type
foreign import data BigNum :: Type
foreign import data Value :: Type
foreign import data AuxiliaryData :: Type
foreign import data Transaction :: Type
foreign import data TransactionBody :: Type
foreign import data Mint :: Type
foreign import data MintAssets :: Type
foreign import data TransactionWitnessSet :: Type
foreign import data TransactionHash :: Type
foreign import data TransactionInput :: Type
foreign import data TransactionInputs :: Type
foreign import data TransactionOutput :: Type
foreign import data TransactionOutputs :: Type
foreign import data TransactionUnspentOutput :: Type
foreign import data MultiAsset :: Type
foreign import data Assets :: Type
foreign import data AssetName :: Type
foreign import data DataHash :: Type
foreign import data Vkeywitnesses :: Type
foreign import data Vkeywitness :: Type
foreign import data Vkey :: Type
foreign import data Ed25519Signature :: Type
foreign import data PublicKey :: Type
foreign import data PlutusScript :: Type
foreign import data PlutusScripts :: Type
foreign import data NativeScript :: Type
foreign import data NativeScripts :: Type
foreign import data NetworkId :: Type
foreign import data ScriptPubkey :: Type
foreign import data ScriptAll :: Type
foreign import data ScriptAny :: Type
foreign import data ScriptNOfK :: Type
foreign import data TimelockStart :: Type
foreign import data TimelockExpiry :: Type
foreign import data BootstrapWitnesses :: Type
foreign import data BootstrapWitness :: Type
foreign import data ConstrPlutusData :: Type
foreign import data PlutusList :: Type
foreign import data PlutusMap :: Type
foreign import data PlutusData :: Type
foreign import data Redeemers :: Type
foreign import data Redeemer :: Type
foreign import data RedeemerTag :: Type
foreign import data ExUnits :: Type
foreign import data Costmdls :: Type
foreign import data CostModel :: Type
foreign import data Language :: Type
foreign import data Int32 :: Type
foreign import data ScriptDataHash :: Type
foreign import data Certificates :: Type
foreign import data Certificate :: Type
foreign import data VRFKeyHash :: Type
foreign import data UnitInterval :: Type
foreign import data Ed25519KeyHashes :: Type
foreign import data Relay :: Type
foreign import data Relays :: Type
foreign import data Ipv4 :: Type
foreign import data Ipv6 :: Type
foreign import data PoolMetadata :: Type
foreign import data GenesisHash :: Type
foreign import data GenesisDelegateHash :: Type
foreign import data MoveInstantaneousReward :: Type
foreign import data MIRToStakeCredentials :: Type
foreign import data Withdrawals :: Type

instance Show BigNum where
  show = _to_str

instance Eq BigNum where
  eq = eq `on` show

instance Show VRFKeyHash where
  show = _to_bech32

instance Eq VRFKeyHash where
  eq = eq `on` show

foreign import _to_str :: forall a. a -> String
foreign import _to_bech32 :: forall a. a -> String
