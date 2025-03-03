module QueryM.DatumCacheWsp
  ( DatumCacheResponse(..)
  , DatumCacheRequest(..)
  , DatumCacheMethod(..)
  , JsonWspRequest
  , JsonWspResponse
  , WspFault(WspFault)
  , faultToString
  , jsonWspRequest
  , parseJsonWspResponse
  , responseMethod
  , requestMethodName
  ) where

import Aeson
  ( Aeson
  , decodeAeson
  , getNestedAeson
  , toStringifiedNumbersJson
  )
import Control.Alt (map, (<$), (<$>), (<|>))
import Control.Bind ((=<<), bind)
import Control.Category ((<<<))
import Data.Argonaut
  ( Json
  , JsonDecodeError
      ( UnexpectedValue
      , AtIndex
      , Named
      )
  , decodeJson
  , encodeJson
  , jsonNull
  , stringify
  )
import Data.Bifunctor (lmap)
import Data.Either (Either(Left, Right), note)
import Data.Eq (class Eq)
import Data.Function ((>>>), const, ($))
import Data.Maybe (Maybe(Just, Nothing), maybe)
import Data.Monoid ((<>))
import Data.Newtype (unwrap)
import Data.Show (class Show)
import Data.TraversableWithIndex (forWithIndex)
import Data.Unit (Unit, unit)
import Serialization.Address (BlockId, Slot)
import Types.ByteArray (byteArrayToHex, hexToByteArray)
import Types.Datum (DatumHash)
import Types.PlutusData (PlutusData)
import Types.Transaction (DataHash(DataHash))

newtype WspFault = WspFault Json

faultToString :: WspFault -> String
faultToString (WspFault j) = stringify j

type JsonWspRequest =
  { type :: String
  , version :: String
  , servicename :: String
  , methodname :: String
  , args :: Json
  }

type JsonWspResponse =
  { type :: String
  , version :: String
  , servicename :: String
  , methodname :: String
  , result :: Maybe Aeson
  , fault :: Maybe Aeson
  }

data DatumCacheMethod
  = GetDatumByHash
  | GetDatumsByHashes
  | StartFetchBlocks
  | CancelFetchBlocks
  | DatumFilterAddHashes
  | DatumFilterRemoveHashes
  | DatumFilterSetHashes
  | DatumFilterGetHashes

derive instance Eq DatumCacheMethod

instance Show DatumCacheMethod where
  show = datumCacheMethodToString

datumCacheMethodToString :: DatumCacheMethod -> String
datumCacheMethodToString = case _ of
  GetDatumByHash -> "GetDatumByHash"
  GetDatumsByHashes -> "GetDatumsByHashes"
  StartFetchBlocks -> "StartFetchBlocks"
  CancelFetchBlocks -> "CancelFetchBlocks"
  DatumFilterAddHashes -> "DatumFilterAddHashes"
  DatumFilterRemoveHashes -> "DatumFilterRemoveHashes"
  DatumFilterSetHashes -> "DatumFilterSetHashes"
  DatumFilterGetHashes -> "DatumFilterGetHashes"

datumCacheMethodFromString :: String -> Maybe DatumCacheMethod
datumCacheMethodFromString = case _ of
  "GetDatumByHash" -> Just GetDatumByHash
  "GetDatumsByHashes" -> Just GetDatumsByHashes
  "StartFetchBlocks" -> Just StartFetchBlocks
  "CancelFetchBlocks" -> Just CancelFetchBlocks
  "DatumFilterAddHashes" -> Just DatumFilterAddHashes
  "DatumFilterRemoveHashes" -> Just DatumFilterRemoveHashes
  "DatumFilterSetHashes" -> Just DatumFilterSetHashes
  "DatumFilterGetHashes" -> Just DatumFilterGetHashes
  _ -> Nothing

data DatumCacheRequest
  = GetDatumByHashRequest DatumHash
  | GetDatumsByHashesRequest (Array DatumHash)
  | StartFetchBlocksRequest { slot :: Slot, id :: BlockId }
  | CancelFetchBlocksRequest
  | DatumFilterAddHashesRequest (Array DatumHash)
  | DatumFilterRemoveHashesRequest (Array DatumHash)
  | DatumFilterSetHashesRequest (Array DatumHash)
  | DatumFilterGetHashesRequest

data DatumCacheResponse
  = GetDatumByHashResponse (Maybe PlutusData)
  | GetDatumsByHashesResponse (Array PlutusData)
  | StartFetchBlocksResponse
  | CancelFetchBlocksResponse
  | DatumFilterAddHashesResponse
  | DatumFilterRemoveHashesResponse
  | DatumFilterSetHashesResponse
  | DatumFilterGetHashesResponse (Array DatumHash)

requestMethod :: DatumCacheRequest -> DatumCacheMethod
requestMethod = case _ of
  GetDatumByHashRequest _ -> GetDatumByHash
  GetDatumsByHashesRequest _ -> GetDatumsByHashes
  StartFetchBlocksRequest _ -> StartFetchBlocks
  CancelFetchBlocksRequest -> CancelFetchBlocks
  DatumFilterAddHashesRequest _ -> DatumFilterAddHashes
  DatumFilterRemoveHashesRequest _ -> DatumFilterRemoveHashes
  DatumFilterSetHashesRequest _ -> DatumFilterSetHashes
  DatumFilterGetHashesRequest -> DatumFilterGetHashes

responseMethod :: DatumCacheResponse -> DatumCacheMethod
responseMethod = case _ of
  GetDatumByHashResponse _ -> GetDatumByHash
  GetDatumsByHashesResponse _ -> GetDatumsByHashes
  StartFetchBlocksResponse -> StartFetchBlocks
  CancelFetchBlocksResponse -> CancelFetchBlocks
  DatumFilterAddHashesResponse -> DatumFilterAddHashes
  DatumFilterRemoveHashesResponse -> DatumFilterRemoveHashes
  DatumFilterSetHashesResponse -> DatumFilterSetHashes
  DatumFilterGetHashesResponse _ -> DatumFilterGetHashes

requestMethodName :: DatumCacheRequest -> String
requestMethodName = requestMethod >>> datumCacheMethodToString

jsonWspRequest :: DatumCacheRequest -> JsonWspRequest
jsonWspRequest req =
  { type: "jsonwsp/request"
  , version: "1.0"
  , servicename: "ogmios"
  , methodname: requestMethodName req
  , args: toArgs req
  }
  where
  encodeHashes :: Array DatumHash -> Json
  encodeHashes dhs = encodeJson { hashes: (byteArrayToHex <<< unwrap) <$> dhs }

  toArgs :: DatumCacheRequest -> Json
  toArgs = case _ of
    GetDatumByHashRequest dh -> encodeJson { hash: byteArrayToHex $ unwrap dh }
    GetDatumsByHashesRequest dhs -> encodeHashes dhs
    StartFetchBlocksRequest slotnblock -> encodeJson slotnblock
    CancelFetchBlocksRequest -> jsonNull
    DatumFilterAddHashesRequest dhs -> encodeHashes dhs
    DatumFilterRemoveHashesRequest dhs -> encodeHashes dhs
    DatumFilterSetHashesRequest dhs -> encodeHashes dhs
    DatumFilterGetHashesRequest -> jsonNull

parseJsonWspResponse :: JsonWspResponse -> Either WspFault DatumCacheResponse
parseJsonWspResponse resp@{ methodname, result, fault } =
  maybe
    (toLeftWspFault fault)
    decodeResponse
    result
  where

  toLeftWspFault :: Maybe Aeson -> Either WspFault DatumCacheResponse
  toLeftWspFault = Left <<< maybe invalidResponseError WspFault <<< map
    toStringifiedNumbersJson

  decodeResponse :: Aeson -> Either WspFault DatumCacheResponse
  decodeResponse r = case datumCacheMethodFromString methodname of
    Nothing -> Left invalidResponseError
    Just method -> case method of
      GetDatumByHash -> GetDatumByHashResponse <$>
        let
          datumFound =
            Just <$> liftErr
              (decodeAeson =<< getNestedAeson r [ "DatumFound", "value" ])
          datumNotFound =
            Nothing <$ liftErr (getNestedAeson r [ "DatumNotFound" ])
        in
          datumFound <|> datumNotFound
      GetDatumsByHashes -> GetDatumsByHashesResponse <$>
        liftErr (decodeAeson =<< getNestedAeson r [ "DatumFound", "value" ])
      StartFetchBlocks -> StartFetchBlocksResponse <$ decodeDoneFlag
        [ "StartedBlockFetcher" ]
        r
      -- fault version od the response should probably be implemented as one of expected results of API call
      CancelFetchBlocks -> CancelFetchBlocksResponse <$ decodeDoneFlag
        [ "StoppedBlockFetcher" ]
        r
      DatumFilterAddHashes -> DatumFilterAddHashesResponse <$ decodeDoneFlag
        [ "AddedHashes" ]
        r
      DatumFilterRemoveHashes -> DatumFilterRemoveHashesResponse <$
        decodeDoneFlag
          [ "RemovedHashes" ]
          r
      DatumFilterSetHashes -> DatumFilterSetHashesResponse <$ decodeDoneFlag
        [ "SetHashes" ]
        r
      DatumFilterGetHashes -> DatumFilterGetHashesResponse <$>
        liftErr (decodeHashes =<< getNestedAeson r [ "hashes" ])

  decodeHashes :: Aeson -> Either JsonDecodeError (Array DatumHash)
  decodeHashes j = do
    let jStr = toStringifiedNumbersJson j
    { hashes } :: { hashes :: Array String } <- decodeJson jStr
    forWithIndex hashes
      ( \idx h ->
          note
            ( AtIndex idx $ Named ("Cannot convert to ByteArray: " <> h) $
                UnexpectedValue jStr
            )
            $ DataHash <$> hexToByteArray h
      )

  invalidResponseError :: WspFault
  invalidResponseError = WspFault $ encodeJson
    { error: "Invalid datum cache response"
    , response: resp
        { result = toStringifiedNumbersJson <$> resp.result
        , fault = toStringifiedNumbersJson <$> resp.fault
        }
    }

  liftErr :: forall (a :: Type). Either JsonDecodeError a -> Either WspFault a
  liftErr = lmap (const invalidResponseError)

  decodeDoneFlag :: Array String -> Aeson -> Either WspFault Unit
  decodeDoneFlag locator r = do
    done :: Boolean <- liftErr (decodeAeson =<< getNestedAeson r locator)
    if done then Right unit else Left invalidResponseError
