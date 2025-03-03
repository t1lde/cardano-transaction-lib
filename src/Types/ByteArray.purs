-- | Our domain type for byte arrays, a wrapper over `Uint8Array`.
module Types.ByteArray
  ( ByteArray(..)
  , byteArrayFromIntArray
  , byteArrayFromIntArrayUnsafe
  , byteArrayFromAscii
  , byteArrayToHex
  , byteArrayToIntArray
  , byteLength
  , hexToByteArray
  , hexToByteArrayUnsafe
  ) where

import Data.Argonaut (class DecodeJson)
import Data.Argonaut as Json
import Data.ArrayBuffer.Types (Uint8Array)
import Data.Either (Either(Left), note)
import Data.Maybe (Maybe(Just, Nothing))
import Data.Newtype (class Newtype, unwrap)
import Prelude
import Test.QuickCheck.Arbitrary (class Arbitrary, arbitrary)
import Data.Char (toCharCode)
import Data.String.CodeUnits (toCharArray)
import Data.Traversable (for)

newtype ByteArray = ByteArray Uint8Array

derive instance Newtype ByteArray _

instance Show ByteArray where
  show arr = "(byteArrayFromIntArrayUnsafe " <> show (byteArrayToIntArray arr)
    <> ")"

instance Eq ByteArray where
  eq a b = compare a b == EQ

instance Ord ByteArray where
  compare = \xs ys -> compare 0 (ord_ toDelta xs ys)
    where
    toDelta x y =
      case compare x y of
        EQ -> 0
        LT -> 1
        GT -> -1

instance Semigroup ByteArray where
  append = concat_

instance Monoid ByteArray where
  mempty = byteArrayFromIntArrayUnsafe []

instance DecodeJson ByteArray where
  decodeJson j = Json.caseJsonString
    (Left (Json.TypeMismatch "expected a hex-encoded CBOR string"))
    (note (Json.UnexpectedValue j) <<< hexToByteArray)
    j

foreign import ord_ :: (Int -> Int -> Int) -> ByteArray -> ByteArray -> Int

foreign import concat_ :: ByteArray -> ByteArray -> ByteArray

foreign import byteArrayToHex :: ByteArray -> String

foreign import hexToByteArray_
  :: (forall (a :: Type). Maybe a)
  -> (forall (a :: Type). a -> Maybe a)
  -> String
  -> Maybe ByteArray

-- | Input string must consist of hexademical numbers.
-- | Length of the input string must be even (2 characters per byte).
hexToByteArray :: String -> Maybe ByteArray
hexToByteArray = hexToByteArray_ Nothing Just

-- | Characters not in range will be converted to zero.
foreign import hexToByteArrayUnsafe :: String -> ByteArray

-- | Overflowing integers will be silently accepted modulo 256.
foreign import byteArrayFromIntArrayUnsafe :: Array Int -> ByteArray

foreign import byteArrayFromIntArray_
  :: (forall (a :: Type). Maybe a)
  -> (forall (a :: Type). a -> Maybe a)
  -> Array Int
  -> Maybe ByteArray

-- | A safer version of `byteArrayFromIntArrayUnsafe` that checks that elements are in range 0-255.
byteArrayFromIntArray :: Array Int -> Maybe ByteArray
byteArrayFromIntArray = byteArrayFromIntArray_ Nothing Just

foreign import byteArrayToIntArray :: ByteArray -> Array Int

foreign import _byteLength :: Uint8Array -> Int

byteLength :: ByteArray -> Int
byteLength = _byteLength <<< unwrap

instance Arbitrary ByteArray where
  arbitrary = byteArrayFromIntArrayUnsafe <$> arbitrary

-- | Convert characters in range `0-255` into a `ByteArray`.
-- | Fails with `Nothing` if there are characters out of this range in a string.
byteArrayFromAscii :: String -> Maybe ByteArray
byteArrayFromAscii str = do
  byteArrayFromIntArrayUnsafe <$> for (toCharArray str) \cp -> do
    let charCode = toCharCode cp
    if charCode <= 255 && charCode >= 0 then pure charCode
    else Nothing
