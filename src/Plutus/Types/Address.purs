module Plutus.Types.Address
  ( Address
  , AddressRecord
  , pubKeyHashAddress
  , scriptHashAddress
  , toPubKeyHash
  , toValidatorHash
  , toStakingCredential
  ) where

import Prelude
import Data.Maybe (Maybe(Just, Nothing))
import Data.Generic.Rep (class Generic)
import Data.Show.Generic (genericShow)
import Data.Newtype (class Newtype, wrap, unwrap)
import Types.UnbalancedTransaction (PubKeyHash)
import Types.Scripts (ValidatorHash)
import Types.PlutusData (PlutusData(Constr))
import ToData (class ToData, toData)
import FromData (class FromData, fromData)
import Plutus.Types.Credential
  ( Credential(PubKeyCredential, ScriptCredential)
  , StakingCredential
  )

--------------------------------------------------------------------------------
-- Address
--------------------------------------------------------------------------------

type AddressRecord =
  { addressCredential :: Credential
  , addressStakingCredential :: Maybe StakingCredential
  }

-- Taken from https://playground.plutus.iohkdev.io/doc/haddock/plutus-ledger-api/html/Plutus-V1-Ledger-Tx.html#t:Address
-- Plutus rev: dbefda30be6490c758aa88b600f5874f12712b3a
-- | Address with two kinds of credentials, normal and staking.
newtype Address = Address AddressRecord

derive instance Eq Address
derive instance Ord Address
derive instance Newtype Address _
derive instance Generic Address _

instance Show Address where
  show = genericShow

instance ToData Address where
  toData (Address a) = Constr zero $
    [ toData a.addressCredential, toData a.addressStakingCredential ]

instance FromData Address where
  fromData (Constr n [ credD, stakingCredD ]) | n == zero =
    Address <$>
      ( { addressCredential: _, addressStakingCredential: _ }
          <$> fromData credD
          <*> fromData stakingCredD
      )
  fromData _ = Nothing

--------------------------------------------------------------------------------
-- Useful functions
--------------------------------------------------------------------------------

-- | The address that should be targeted by a transaction output locked
-- | by the public key with the given hash.
pubKeyHashAddress :: PubKeyHash -> Address
pubKeyHashAddress pkh = wrap $
  { addressCredential: PubKeyCredential pkh
  , addressStakingCredential: Nothing
  }

-- | The address that should be used by a transaction output locked
-- | by the given validator script hash.
scriptHashAddress :: ValidatorHash -> Address
scriptHashAddress vh = wrap $
  { addressCredential: ScriptCredential vh
  , addressStakingCredential: Nothing
  }

-- | The PubKeyHash of the address (if any).
toPubKeyHash :: Address -> Maybe PubKeyHash
toPubKeyHash addr =
  case _.addressCredential (unwrap addr) of
    PubKeyCredential k -> Just k
    _ -> Nothing

-- | The validator hash of the address (if any).
toValidatorHash :: Address -> Maybe ValidatorHash
toValidatorHash addr =
  case _.addressCredential (unwrap addr) of
    ScriptCredential k -> Just k
    _ -> Nothing

-- | The staking credential of an address (if any).
toStakingCredential :: Address -> Maybe StakingCredential
toStakingCredential = _.addressStakingCredential <<< unwrap
