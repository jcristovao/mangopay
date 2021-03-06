{-# LANGUAGE DeriveDataTypeable, ScopedTypeVariables, OverloadedStrings, FlexibleContexts, FlexibleInstances, ConstraintKinds #-}
-- | handle payins
module Web.MangoPay.Payins where

import Web.MangoPay.Accounts
import Web.MangoPay.Monad
import Web.MangoPay.Types
import Web.MangoPay.Users
import Web.MangoPay.Wallets

import Data.Text
import Data.Typeable (Typeable)
import Data.Aeson
import Data.Time.Clock.POSIX (POSIXTime)
import Control.Applicative

-- | create a bankwire pay-in
createBankWirePayIn ::  (MPUsableMonad m) => BankWire -> AccessToken -> MangoPayT m BankWire
createBankWirePayIn = createGeneric "/payins/bankwire/direct"

-- | fetch a bank wire pay-in from its ID
fetchBankWirePayIn :: (MPUsableMonad m) => BankWireID -> AccessToken -> MangoPayT m BankWire
fetchBankWirePayIn = fetchGeneric "/payins/"

-- | create a direct card pay in
createCardPayin ::  (MPUsableMonad m) => CardPayin -> AccessToken -> MangoPayT m CardPayin
createCardPayin = createGeneric "/payins/card/direct"

-- | fetch a direct card pay in from its ID
fetchCardPayin :: (MPUsableMonad m) => CardPayinID -> AccessToken -> MangoPayT m CardPayin
fetchCardPayin = fetchGeneric "/payins/"

data PaymentExecution = WEB  -- ^ through a web interface
 | DIRECT -- ^ with a tokenized card
  deriving (Show,Read,Eq,Ord,Bounded,Enum,Typeable)

-- | to json as per MangoPay format
instance ToJSON PaymentExecution where
        toJSON =toJSON . show

-- | from json as per MangoPay format
instance FromJSON PaymentExecution where
        parseJSON (String s)=pure $ read $ unpack s
        parseJSON _ =fail "PaymentExecution"

-- | helper function to create a new bank wire with the needed information
mkBankWire :: AnyUserID -> AnyUserID -> WalletID -> Amount -> Amount -> BankWire
mkBankWire aid uid wid amount fees= BankWire Nothing Nothing Nothing aid uid Nothing
  wid Nothing Nothing Nothing amount fees Nothing Nothing Nothing Nothing Nothing Nothing Nothing Nothing Nothing Nothing

-- | bankwire or card pay in
type AnyPayinID=Text

-- | id of a bankwire
type BankWireID=Text

-- | a bank wire
-- there are a lot of common fields between all kinds of payments
-- so this could probably become a "Payment" type
data BankWire=BankWire {
  bwId :: Maybe BankWireID
  ,bwCreationDate :: Maybe POSIXTime
  ,bwTag :: Maybe Text -- ^  custom data
  ,bwAuthorId  :: AnyUserID -- ^   The user ID of the author
  ,bwCreditedUserId  :: AnyUserID -- ^  It represents the amount credited on the targeted e-wallet.
  ,bwFees :: Maybe Amount -- ^  It represents your fees taken on the DebitedFundsDebitedFunds – Fees = CreditedFunds (amount received on wallet)
  ,bwCreditedWalletId :: WalletID -- ^ The ID of the credited wallet
  ,bwDebitedWalletId :: Maybe WalletID -- ^  The ID of the debited wallet
  ,bwDebitedFunds  :: Maybe Amount -- ^  It represents the amount debited from the bank account.
  ,bwCreditedFunds :: Maybe Amount -- ^   It represents the amount credited on the targeted e-wallet.
  ,bwDeclaredDebitedFunds  :: Amount -- ^   It represents the expected amount by the platform before that the user makes the payment.
  ,bwDeclaredFees  :: Amount -- ^   It represents the expected fees amount by the platform before that the user makes the payment.
  ,bwWireReference :: Maybe Text -- ^ It is a reference generated by MANGOPAY and displayed to the user by the platform. The user have to indicate it into the bank wire.
  ,bwBankAccount :: Maybe BankAccount -- ^ The bank account is generated by MANGOPAY and displayed to the user.
  ,bwStatus  :: Maybe TransferStatus -- ^  The status of the payment
  ,bwResultCode  :: Maybe Text -- ^  The transaction result code
  ,bwResultMessage :: Maybe Text -- ^  The transaction result Message
  ,bwExecutionDate :: Maybe POSIXTime -- ^ The date when the payment is processed
  ,bwType  :: Maybe TransactionType -- ^  The type of the transaction
  ,bwNature  :: Maybe TransactionNature -- ^  The nature of the transaction:
  ,bwPaymentType :: Maybe PaymentType -- ^  The type of the payment (which type of mean of payment is used).
  ,bwExecutionType :: Maybe PaymentExecution -- ^  How the payment has been executed:
  } deriving (Show,Eq,Ord,Typeable)

-- | to json as per MangoPay format
instance ToJSON BankWire where
        toJSON bw=object ["Tag" .= bwTag bw,"AuthorId" .= bwAuthorId  bw
          ,"CreditedUserId" .= bwCreditedUserId bw,"CreditedWalletId" .= bwCreditedWalletId bw
          ,"DeclaredDebitedFunds" .= bwDeclaredDebitedFunds bw,"DeclaredFees" .= bwDeclaredFees bw]

-- | from json as per MangoPay format
instance FromJSON BankWire where
        parseJSON (Object v) =BankWire <$>
                         v .: "Id" <*>
                         v .: "CreationDate" <*>
                         v .:? "Tag" <*>
                         v .: "AuthorId" <*>
                         v .: "CreditedUserId" <*>
                         v .:? "Fees"  <*>
                         v .: "CreditedWalletId"  <*>
                         v .:? "DebitedWalletId"  <*>
                         v .:? "DebitedFunds"  <*>
                         v .:? "CreditedFunds"  <*>
                         v .: "DeclaredDebitedFunds"  <*>
                         v .: "DeclaredFees"  <*>
                         v .:? "WireReference"  <*>
                         v .:? "BankAccount"  <*>
                         v .:? "Status" <*>
                         v .:? "ResultCode" <*>
                         v .:? "ResultMessage" <*>
                         v .:? "ExecutionDate" <*>
                         v .:? "Type" <*>
                         v .:? "Nature" <*>
                         v .:? "PaymentType" <*>
                         v .:? "ExecutionType"
        parseJSON _=fail "BankWire"

-- | ID of a direct pay in
type CardPayinID=Text

-- | helper function to create a new direct payin with the needed information
-- | the url is only used in secure mode but is REQUIRED by MangoPay
mkCardPayin :: AnyUserID -> AnyUserID -> WalletID -> Amount -> Amount -> Text -> CardID -> CardPayin
mkCardPayin aid uid wid amount fees url cid= CardPayin Nothing Nothing Nothing aid uid fees
  wid Nothing amount Nothing (Just url) Nothing Nothing cid Nothing Nothing Nothing Nothing Nothing Nothing Nothing Nothing


-- | direct pay in via registered card
data CardPayin=CardPayin {
  cpId :: Maybe CardPayinID
  ,cpCreationDate :: Maybe POSIXTime
  ,cpTag :: Maybe Text -- ^  custom data
  ,cpAuthorId  :: AnyUserID -- ^   The user ID of the author
  ,cpCreditedUserId  :: AnyUserID -- ^  The user ID of the owner of the credited wallet
  ,cpFees :: Amount -- ^  It represents your fees taken on the DebitedFundsDebitedFunds – Fees = CreditedFunds (amount received on wallet)
  ,cpCreditedWalletId :: WalletID -- ^ The ID of the credited wallet
  ,cpDebitedWalletId :: Maybe WalletID -- ^  The ID of the debited wallet
  ,cpDebitedFunds  :: Amount -- ^  It represents the amount debited from the bank account.
  ,cpCreditedFunds :: Maybe Amount -- ^   It represents the amount credited on the targeted e-wallet.
  ,cpSecureModeReturnURL :: Maybe Text -- ^ This URL will be used in case the SecureMode is activated.
  ,cpSecureMode :: Maybe Text -- ^ The SecureMode correspond to « 3D secure » for CB Visa and MasterCard or « Amex Safe Key » for American Express. This field lets you activate it manually.
  ,cpSecureModeRedirectURL :: Maybe Text -- ^ This URL will be used in case the SecureMode is activated.
  ,cpCardId :: CardID -- ^ The ID of the registered card (Got through CardRegistration object)
  ,cpStatus  :: Maybe TransferStatus -- ^  The status of the payment
  ,cpResultCode  :: Maybe Text -- ^  The transaction result code
  ,cpResultMessage :: Maybe Text -- ^  The transaction result Message
  ,cpExecutionDate :: Maybe POSIXTime --   The date when the payment is processed
  ,cpType  :: Maybe TransactionType -- ^  The type of the transaction
  ,cpNature  :: Maybe TransactionNature -- ^  The nature of the transaction:
  ,cpPaymentType :: Maybe Text -- ^  The type of the payment (which type of mean of payment is used).
  ,cpExecutionType :: Maybe PaymentExecution -- ^  How the payment has been executed:
  } deriving (Show,Eq,Ord,Typeable)

-- | to json as per MangoPay format
instance ToJSON CardPayin where
        toJSON cp=object ["Tag" .= cpTag cp,"AuthorId" .= cpAuthorId  cp
          ,"CreditedUserId" .= cpCreditedUserId cp,"CreditedWalletId" .= cpCreditedWalletId cp
          ,"DebitedFunds" .= cpDebitedFunds cp,"Fees" .= cpFees cp,"CardID" .= cpCardId cp
          ,"SecureModeReturnURL" .= cpSecureModeReturnURL cp
          ,"SecureMode" .= cpSecureMode cp]

-- | from json as per MangoPay format
instance FromJSON CardPayin where
        parseJSON (Object v) =CardPayin <$>
                         v .: "Id" <*>
                         v .: "CreationDate" <*>
                         v .:? "Tag" <*>
                         v .: "AuthorId" <*>
                         v .: "CreditedUserId" <*>
                         v .: "Fees"  <*>
                         v .: "CreditedWalletId"  <*>
                         v .:? "DebitedWalletId"  <*>
                         v .: "DebitedFunds"  <*>
                         v .:? "CreditedFunds"  <*>
                         v .:? "SecureModeReturnURL" <*>
                         v .:? "SecureModeRedirectURL" <*>
                         v .:? "SecureMode" <*>
                         v .: "CardId" <*>
                         v .:? "Status" <*>
                         v .:? "ResultCode" <*>
                         v .:? "ResultMessage" <*>
                         v .:? "ExecutionDate" <*>
                         v .:? "Type" <*>
                         v .:? "Nature" <*>
                         v .:? "PaymentType" <*>
                         v .:? "ExecutionType"
        parseJSON _=fail "CardPayin"

