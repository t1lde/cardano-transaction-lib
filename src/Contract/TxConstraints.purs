-- | A module for building `TxConstraints` te pair with the `ScriptLookups`
-- | as part of an off-chain transaction.
module Contract.TxConstraints (module TxConstraints) where

import Types.TxConstraints
  ( InputConstraint(InputConstraint)
  , OutputConstraint(OutputConstraint)
  , TxConstraint
      ( MustIncludeDatum
      , MustValidateIn
      , MustBeSignedBy
      , MustSpendAtLeast
      , MustProduceAtLeast
      , MustSpendPubKeyOutput
      , MustSpendScriptOutput
      , MustMintValue
      , MustPayToPubKeyAddress
      , MustPayToOtherScript
      , MustHashDatum
      , MustSatisfyAnyOf
      )
  , TxConstraints(TxConstraints)
  , addTxIn
  , isSatisfiable
  , modifiesUtxoSet
  , mustBeSignedBy
  , mustHashDatum
  , mustIncludeDatum
  , mustMintCurrency
  , mustMintCurrencyWithRedeemer
  , mustMintValue
  , mustMintValueWithRedeemer
  , mustPayToOtherScript
  , mustPayToPubKey
  , mustPayToPubKeyAddress
  , mustPayToTheScript
  , mustPayWithDatumToPubKey
  , mustPayWithDatumToPubKeyAddress
  , mustProduceAtLeast
  , mustProduceAtLeastTotal
  , mustSatisfyAnyOf
  , mustSpendAtLeast
  , mustSpendAtLeastTotal
  , mustSpendPubKeyOutput
  , mustSpendScriptOutput
  , mustValidateIn
  , pubKeyPayments
  , requiredDatums
  , requiredMonetaryPolicies
  , requiredSignatories
  , singleton
  ) as TxConstraints