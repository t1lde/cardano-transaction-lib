module Test.Parser where

import Prelude

import Aeson (Aeson, caseAesonArray, parseJsonStringToAeson, stringifyAeson)
import Control.Monad.Except.Trans (ExceptT, runExceptT)
import Control.Monad.Trans.Class (lift)
import Control.Monad.Error.Class (throwError)
import Data.Argonaut as Json
import Data.Array as Array
import Data.Either (Either, either, isRight)
import Data.Medea (validate)
import Data.Medea.Loader (LoaderError, loadSchemaFromFile)
import Data.Medea.Schema (Schema)
import Data.Traversable (traverse, traverse_)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Effect.Exception (error, throw)
import Node.FS.Aff (readTextFile)
import Node.Encoding (Encoding(UTF8))
import Test.Spec.Assertions (shouldSatisfy, shouldNotSatisfy)
import TestM (TestPlanM, ValidationM, runValidationM)
import Mote (group, test)
import QueryM.JsonWsp (JsonWspResponse, parseJsonWspResponse)
import QueryM.Ogmios (UtxoQR)

suite :: TestPlanM Unit
suite = do
  str <- lift $ readTextFile UTF8
    "./fixtures/test/parsing/JsonWsp/UtxoQueryResponse.json"
  let
    eJson = parseJsonStringToAeson str
  json <- either
    (\e -> liftEffect $ throw ("json parsed incorrectly " <> show e))
    pure
    eJson
  let
    stringArray = caseAesonArray [] convertJsonArray json :: Array String
    jsonStrArray = caseAesonArray [] identity json :: Array Aeson
  schema <- lift $ getSchema
    "./fixtures/schemata/JsonWsp/UtxoQueryResponse.medea"
  group "Parser tests" $ do
    group "Schemata parse tests" $ do
      test "fixture array should not be empty" $
        stringArray `shouldNotSatisfy` Array.null
      test "fixtures match schema - utxoQueryResponse" $
        -- TODO: add a helper function or something so that the error displays the index it occured on, logs out the offending JSON string from the array.
        runValidationM (validateJsonArray schema stringArray) `shouldSatisfy`
          isRight
    group "Type parsing" $ do
      test "fixtures parse correctly - UtxoQueryResponse" $
        traverseJsonWsps jsonStrArray `shouldSatisfy` isRight

traverseJsonWsps
  :: Array Aeson -> Either Json.JsonDecodeError (Array (JsonWspResponse UtxoQR))
traverseJsonWsps arr = traverse parseJsonWspResponse arr

convertJsonArray :: Array Aeson -> Array String
convertJsonArray arr = map stringifyAeson arr

getSchema :: String -> Aff Schema
getSchema file = do
  (eSchema :: Either LoaderError Schema) <- runExceptT $
    (loadSchemaFromFile file :: ExceptT LoaderError Aff Schema)
  either (throwError <<< error <<< show) pure eSchema

validateJsonArray :: Schema -> Array String -> ValidationM Unit
validateJsonArray scm arr = traverse_ (validate scm) arr
