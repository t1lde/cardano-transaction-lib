module ToData
  ( class ToData
  , class ToDataArgs
  , class ToDataWithIndex
  , class ToDataArgsRL
  , genericToData
  , toDataArgsRec
  , toData
  , toDataArgs
  , toDataWithIndex
  ) where

import Prelude

import ConstrIndices (class HasConstrIndices, constrIndices)
import Data.Array (cons)
import Data.Array as Array
import Data.NonEmpty (NonEmpty)
import Data.BigInt (BigInt)
import Data.BigInt as BigInt
import Data.Either (Either(Left, Right))
import Data.Foldable (class Foldable)
import Data.Generic.Rep as G
import Data.List (List)
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe(Just, Nothing))
import Data.Profunctor.Strong ((***))
import Data.Ratio (Ratio, denominator, numerator)
import Data.Symbol (class IsSymbol, SProxy(SProxy), reflectSymbol)
import Data.TextEncoder (encodeUtf8)
import Data.Tuple (Tuple(Tuple))
import Data.Tuple.Nested (type (/\))
import Data.UInt (UInt)
import Helpers (uIntToBigInt)
import Prim.Row as Row
import Prim.RowList as RL
import Prim.TypeError (class Fail, Text)
import Record as Record
import Type.Proxy (Proxy(Proxy))
import Types.ByteArray (ByteArray(ByteArray))
import Types.PlutusData (PlutusData(Constr, Integer, List, Map, Bytes))

-- | Classes

class ToData :: Type -> Constraint
class ToData a where
  toData :: a -> PlutusData

class ToDataWithIndex :: Type -> Type -> Constraint
class HasConstrIndices ci <= ToDataWithIndex a ci where
  toDataWithIndex :: Proxy ci -> a -> PlutusData

-- As explained in https://harry.garrood.me/blog/write-your-own-generics/ this
-- is just a neat pattern that flattens a skewed Product of Products
class ToDataArgs :: Type -> Constraint
class ToDataArgs a where
  toDataArgs :: a -> Array (PlutusData)

-- | A helper typeclass to implement `ToDataArgs` for records.
-- Stolen from https://github.com/purescript/purescript-quickcheck/blob/v7.1.0/src/Test/QuickCheck/Arbitrary.purs#L247
class ToDataArgsRL :: RL.RowList Type -> Row Type -> Constraint
class ToDataArgsRL list row | list -> row where
  toDataArgsRec
    :: forall rlproxy. rlproxy list -> Record row -> Array PlutusData

-- | ToDataWithIndex instances for Data.Generic.Rep

instance
  ( ToDataWithIndex l a
  , ToDataWithIndex r a
  ) =>
  ToDataWithIndex (G.Sum l r) a where
  toDataWithIndex p (G.Inl x) = toDataWithIndex p x
  toDataWithIndex p (G.Inr x) = toDataWithIndex p x

instance
  ( IsSymbol n
  , ToDataArgs arg
  , HasConstrIndices a
  ) =>
  ToDataWithIndex (G.Constructor n arg) a where
  toDataWithIndex p (G.Constructor args) = Constr
    (resolveIndex p (SProxy :: SProxy n))
    (toDataArgs args)

-- | ToDataArgs instances for Data.Generic.Rep

instance ToDataArgs G.NoArguments where
  toDataArgs _ = []

instance (ToDataArgs (Record row)) => ToDataArgs (G.Argument (Record row)) where
  toDataArgs (G.Argument r) = toDataArgs r
else instance ToData a => ToDataArgs (G.Argument a) where
  toDataArgs (G.Argument x) = [ toData x ]

instance
  ( ToDataArgsRL list row
  , RL.RowToList row list
  ) =>
  ToDataArgs (Record row) where
  toDataArgs = toDataArgsRec (Proxy :: Proxy list)

instance (ToDataArgs a, ToDataArgs b) => ToDataArgs (G.Product a b) where
  toDataArgs (G.Product x y) = toDataArgs x <> toDataArgs y

-- | ToDataArgsRL instances

instance ToDataArgsRL RL.Nil row where
  toDataArgsRec _ _ = []

instance
  ( ToData a
  , ToDataArgsRL listRest rowRest
  , Row.Lacks key rowRest
  , Row.Cons key a rowRest rowFull
  , RL.RowToList rowFull (RL.Cons key a listRest)
  , IsSymbol key
  ) =>
  ToDataArgsRL (RL.Cons key a listRest) rowFull where
  toDataArgsRec _ x =
    let
      keyProxy = (Proxy :: Proxy key)

      field :: a
      field = Record.get keyProxy x
    in
      toData field `cons` toDataArgsRec (Proxy :: Proxy listRest)
        (Record.delete keyProxy x)

genericToData
  :: forall (a :: Type) (rep :: Type)
   . G.Generic a rep
  => ToDataWithIndex rep a
  => a
  -> PlutusData
genericToData = toDataWithIndex (Proxy :: Proxy a) <<< G.from

resolveIndex
  :: forall (a :: Type) (s :: Symbol)
   . HasConstrIndices a
  => IsSymbol s
  => Proxy a
  -> SProxy s
  -> BigInt
resolveIndex pa sps =
  let
    cn = reflectSymbol sps
    Tuple c2i _ = constrIndices pa
  in
    case Map.lookup cn c2i of
      Just i -> BigInt.fromInt i
      Nothing -> negate one -- TODO: We should report here

-- | Base ToData instances

instance ToData Void where
  toData = absurd

instance ToData Unit where
  toData _ = Constr zero []

-- NOTE: For the sake of compatibility the following toDatas have to match
-- https://github.com/input-output-hk/plutus/blob/1f31e640e8a258185db01fa899da63f9018c0e85/plutus-tx/src/PlutusTx/IsData/Instances.hs
instance ToData Boolean where
  toData false = Constr zero []
  toData true = Constr one []

instance ToData a => ToData (Maybe a) where
  toData (Just x) = Constr zero [ toData x ] -- Just is zero-indexed by Plutus
  toData Nothing = Constr one []

instance (ToData a, ToData b) => ToData (Either a b) where
  toData (Left e) = Constr zero [ toData e ]
  toData (Right x) = Constr one [ toData x ]

instance Fail (Text "Int is not supported, use BigInt instead") => ToData Int where
  toData = toData <<< BigInt.fromInt

instance ToData BigInt where
  toData = Integer

instance ToData UInt where
  toData = toData <<< uIntToBigInt

instance ToData a => ToData (Array a) where
  toData = List <<< map toData

instance (Foldable f, ToData a) => ToData (NonEmpty f a) where
  toData = foldableToPlutusData

instance ToData a => ToData (List a) where
  toData = foldableToPlutusData

instance (ToData a, ToData b) => ToData (Tuple a b) where
  toData (Tuple a b) = Constr zero [ toData a, toData b ]

instance (ToData k, ToData v) => ToData (Map k v) where
  toData mp = Map $ entries # map (toData *** toData)
    where
    entries = Map.toUnfoldable mp :: Array (k /\ v)

-- Note that nothing prevents the denominator from being zero, we could provide
-- safety here:
instance ToData a => ToData (Ratio a) where
  toData ratio = List [ toData (numerator ratio), toData (denominator ratio) ]

instance ToData ByteArray where
  toData = Bytes

instance ToData String where
  toData = toData <<< ByteArray <<< encodeUtf8

instance ToData PlutusData where
  toData = identity

foldableToPlutusData
  :: forall (a :: Type) (t :: Type -> Type)
   . Foldable t
  => ToData a
  => t a
  -> PlutusData
foldableToPlutusData = Array.fromFoldable >>> map toData >>> List
