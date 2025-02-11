module Metadata.Seabug
  ( SeabugMetadata(SeabugMetadata)
  , SeabugMetadataDelta(SeabugMetadataDelta)
  ) where

import Prelude

import Data.Argonaut (class DecodeJson)
import Data.Argonaut as Json
import Data.Either (Either(Left), note)
import Data.Generic.Rep (class Generic)
import Data.Map as Map
import Data.Maybe (Maybe(Nothing), fromJust)
import Data.Newtype (class Newtype, wrap)
import Data.Show.Generic (genericShow)
import Data.Tuple (Tuple(Tuple))
import Data.Tuple.Nested (type (/\), (/\))
import FromData (class FromData, fromData)
import Metadata.Seabug.Share (Share, mkShare)
import Partial.Unsafe (unsafePartial)
import ToData (class ToData, toData)
import Serialization.Hash (ScriptHash, scriptHashFromBytes)
import Types.ByteArray
  ( ByteArray
  , hexToByteArray
  , hexToByteArrayUnsafe
  )
import Types.Natural (Natural)
import Types.PlutusData (PlutusData(Map))
import Types.Scripts (MintingPolicyHash, ValidatorHash)
import Types.UnbalancedTransaction (PubKeyHash)
import Types.Value (CurrencySymbol, TokenName, mkTokenName, mkCurrencySymbol)
import Metadata.Helpers (unsafeMkKey, lookupKey)

newtype SeabugMetadata = SeabugMetadata
  { policyId :: MintingPolicyHash
  , mintPolicy :: ByteArray
  , collectionNftCS :: CurrencySymbol
  , collectionNftTN :: TokenName
  , lockingScript :: ValidatorHash
  , authorPkh :: PubKeyHash
  , authorShare :: Share
  , marketplaceScript :: ValidatorHash
  , marketplaceShare :: Share
  , ownerPkh :: PubKeyHash
  , ownerPrice :: Natural
  }

derive instance Generic SeabugMetadata _
derive instance Newtype SeabugMetadata _
derive instance Eq SeabugMetadata

instance Show SeabugMetadata where
  show = genericShow

instance ToData SeabugMetadata where
  toData (SeabugMetadata meta) = unsafePartial $ toData $ Map.fromFoldable
    [ unsafeMkKey "727" /\ Map.fromFoldable
        [ meta.policyId /\ Map.fromFoldable
            [ unsafeMkKey "mintPolicy" /\ toData meta.mintPolicy
            , unsafeMkKey "collectionNftCS" /\ toData meta.collectionNftCS
            , unsafeMkKey "collectionNftTN" /\ toData meta.collectionNftTN
            , unsafeMkKey "lockingScript" /\ toData meta.lockingScript
            , unsafeMkKey "authorPkh" /\ toData meta.authorPkh
            , unsafeMkKey "authorShare" /\ toData meta.authorShare
            , unsafeMkKey "marketplaceScript" /\ toData meta.marketplaceScript
            , unsafeMkKey "marketplaceShare" /\ toData meta.marketplaceShare
            , unsafeMkKey "ownerPkh" /\ toData meta.ownerPkh
            , unsafeMkKey "ownerPrice" /\ toData meta.ownerPrice
            ]
        ]
    ]

instance FromData SeabugMetadata where
  fromData sm = unsafePartial do
    policyId /\ contents <- lookupKey "727" sm >>= case _ of
      Map [ policyId /\ contents ] ->
        Tuple <$> fromData policyId <*> fromData contents
      _ -> Nothing
    mintPolicy <- lookupKey "mintPolicy" contents >>= fromData
    collectionNftCS <- lookupKey "collectionNftCS" contents >>= fromData
    collectionNftTN <- lookupKey "collectionNftTN" contents >>= fromData
    lockingScript <- lookupKey "lockingScript" contents >>= fromData
    authorPkh <- lookupKey "authorPkh" contents >>= fromData
    authorShare <- lookupKey "authorShare" contents >>= fromData
    marketplaceScript <- lookupKey "marketplaceScript" contents >>= fromData
    marketplaceShare <- lookupKey "marketplaceShare" contents >>= fromData
    ownerPkh <- lookupKey "ownerPkh" contents >>= fromData
    ownerPrice <- lookupKey "ownerPrice" contents >>= fromData
    pure $ SeabugMetadata
      { policyId
      , mintPolicy
      , collectionNftCS
      , collectionNftTN
      , lockingScript
      , authorPkh
      , authorShare
      , marketplaceScript
      , marketplaceShare
      , ownerPkh
      , ownerPrice
      }
  fromData _ = Nothing

instance DecodeJson SeabugMetadata where
  decodeJson =
    Json.caseJsonObject
      (Left (Json.TypeMismatch "Expected object"))
      $ \o -> do
          collectionNftCS <-
            note (Json.TypeMismatch "Invalid ByteArray")
              <<< (mkCurrencySymbol <=< hexToByteArray)
              =<< Json.getField o "collectionNftCS"
          collectionNftTN <-
            note (Json.TypeMismatch "expected ASCII-encoded `TokenName`")
              <<< (mkTokenName <=< hexToByteArray)
              =<< Json.getField o "collectionNftTN"
          lockingScript <-
            map wrap
              <<< decodeScriptHash =<< Json.getField o "lockingScript"
          authorPkh <-
            map wrap
              <<< Json.decodeJson =<< Json.getField o "authorPkh"
          authorShare <- decodeShare =<< Json.getField o "authorShare"
          marketplaceScript <- map wrap <<< decodeScriptHash
            =<< Json.getField o "marketplaceScript"
          marketplaceShare <- decodeShare =<< Json.getField o "marketplaceShare"
          ownerPkh <- map wrap <<< Json.decodeJson =<< Json.getField o
            "ownerPkh"
          ownerPrice <- Json.getField o "ownerPrice"
          pure $ SeabugMetadata
            { -- Not used in the endpoints where we parse the metadata, so we
              -- can set a dummy value
              policyId: wrap
                $ unsafePartial
                $ fromJust
                $ scriptHashFromBytes
                $ hexToByteArrayUnsafe
                    "00000000000000000000000000000000000000000000000000000000"
            , mintPolicy: mempty
            , collectionNftCS
            , collectionNftTN
            , lockingScript
            , authorPkh
            , authorShare
            , marketplaceScript
            , marketplaceShare
            , ownerPkh
            , ownerPrice
            }
    where
    decodeShare :: Int -> Either Json.JsonDecodeError Share
    decodeShare = note (Json.TypeMismatch "Expected int between 0 and 10000")
      <<< mkShare

    decodeScriptHash :: String -> Either Json.JsonDecodeError ScriptHash
    decodeScriptHash =
      note
        (Json.TypeMismatch "Expected hex-encoded script hash")
        <<< (scriptHashFromBytes <=< hexToByteArray)

newtype SeabugMetadataDelta = SeabugMetadataDelta
  { policyId :: MintingPolicyHash
  , ownerPkh :: PubKeyHash
  , ownerPrice :: Natural
  }

derive instance Generic SeabugMetadataDelta _
derive instance Newtype SeabugMetadataDelta _
derive instance Eq SeabugMetadataDelta

instance Show SeabugMetadataDelta where
  show = genericShow

instance ToData SeabugMetadataDelta where
  toData (SeabugMetadataDelta meta) = unsafePartial $ toData $ Map.fromFoldable
    [ unsafeMkKey "727" /\ Map.fromFoldable
        [ meta.policyId /\ Map.fromFoldable
            [ unsafeMkKey "ownerPkh" /\ toData meta.ownerPkh
            , unsafeMkKey "ownerPrice" /\ toData meta.ownerPrice
            ]
        ]
    ]

instance FromData SeabugMetadataDelta where
  fromData sm = unsafePartial do
    policyId /\ contents <- lookupKey "727" sm >>= case _ of
      Map [ policyId /\ contents ] ->
        Tuple <$> fromData policyId <*> fromData contents
      _ -> Nothing
    ownerPkh <- lookupKey "ownerPkh" contents >>= fromData
    ownerPrice <- lookupKey "ownerPrice" contents >>= fromData
    pure $ SeabugMetadataDelta
      { policyId
      , ownerPkh
      , ownerPrice
      }
  fromData _ = Nothing
