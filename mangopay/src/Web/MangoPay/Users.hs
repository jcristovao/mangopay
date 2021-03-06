{-# LANGUAGE ConstraintKinds, DeriveDataTypeable, FlexibleContexts,
             FlexibleInstances, OverloadedStrings, PatternGuards,
             ScopedTypeVariables #-}
-- | handle users
module Web.MangoPay.Users where

import Web.MangoPay.Monad
import Web.MangoPay.Types

import Data.CountryCodes (CountryCode)
import Data.Text
import Data.Typeable (Typeable)
import Data.Aeson
import Data.Time.Clock.POSIX (POSIXTime)
import Control.Applicative


-- | create a natural user
createNaturalUser ::  (MPUsableMonad m) => NaturalUser -> AccessToken -> MangoPayT m NaturalUser
createNaturalUser = createGeneric "/users/natural"


-- | modify a natural user
modifyNaturalUser ::  (MPUsableMonad m) => NaturalUser -> AccessToken -> MangoPayT m NaturalUser
modifyNaturalUser u = modifyGeneric "/users/natural/" u' uId
        where u' = u{uProofOfIdentity = Nothing, uProofOfAddress = Nothing}


-- | fetch a natural user from her ID
fetchNaturalUser :: (MPUsableMonad m) => NaturalUserID -> AccessToken -> MangoPayT m NaturalUser
fetchNaturalUser = fetchGeneric "/users/natural/"


-- | create a legal user
createLegalUser ::  (MPUsableMonad m) => LegalUser -> AccessToken -> MangoPayT m LegalUser
createLegalUser = createGeneric "/users/legal"


-- | modify a legal user
modifyLegalUser ::  (MPUsableMonad m) => LegalUser -> AccessToken -> MangoPayT m LegalUser
modifyLegalUser u = modifyGeneric "/users/legal/" u lId


-- | fetch a natural user from her ID
fetchLegalUser :: (MPUsableMonad m) => LegalUserID -> AccessToken -> MangoPayT m LegalUser
fetchLegalUser = fetchGeneric "/users/legal/"


-- | get a user, natural or legal
getUser :: (MPUsableMonad m) => AnyUserID -> AccessToken -> MangoPayT m (Either NaturalUser LegalUser)
getUser = fetchGeneric "/users/"


-- | list all user references
listUsers :: (MPUsableMonad m) => Maybe Pagination -> AccessToken -> MangoPayT m (PagedList UserRef)
listUsers = genericList ["/users/"]


-- | Convenience function to extract the user ID of an EXISTING user (one with an id).
getExistingUserID
  :: Either NaturalUser LegalUser
  -> AnyUserID
getExistingUserID u | Just uid <- either uId lId u = uid
getExistingUserID   _   = error "Web.MangoPay.Users.getExistingUserID: Nothing"


instance FromJSON (Either NaturalUser LegalUser) where
        parseJSON o@(Object v)=do
                pt::PersonType<-v .: "PersonType"
                case pt of
                        Natural->Left <$> parseJSON o
                        Legal->Right <$> parseJSON o
        parseJSON _=fail "EitherUsers"

-- not supported
--deleteNaturalUser :: (MonadBaseControl IO m, MonadResource m) => UserID -> AccessToken -> MangoPayT m ()
--deleteNaturalUser uid at=do
--        url<-getClientURL (TE.encodeUtf8 $ Data.Text.concat ["/users/natural/",uid])
--        req<-getDeleteRequest url (Just at) ([]::HT.Query)
--        _::Object<- getJSONResponse req
--        return ()

-- | ID for any kind of user
type AnyUserID = Text

-- | User ID
type NaturalUserID = Text


-- | a natural user
-- <http://docs.mangopay.com/api-references/users/natural-users/>
data NaturalUser=NaturalUser {
        uId                  :: Maybe NaturalUserID -- ^  The Id of the object
        ,uCreationDate       :: Maybe POSIXTime -- ^  The creation date of the user object
        ,uEmail              :: Text -- ^ User’s e-mail
        ,uFirstName          :: Text -- ^ User’s firstname
        ,uLastName           :: Text -- ^  User’s lastname
        ,uAddress            :: Maybe Text -- ^  User’s address
        ,uBirthday           :: POSIXTime -- ^   User’s birthdate
        ,uNationality        :: CountryCode -- ^ User’s Nationality
        ,uCountryOfResidence:: CountryCode -- ^User’s country of residence
        ,uOccupation         :: Maybe Text -- ^User’s occupation (ie. Work)
        ,uIncomeRange        :: Maybe IncomeRange -- ^ User’s income range
        ,uTag                :: Maybe Text -- ^  Custom data
        ,uProofOfIdentity    :: Maybe Text -- ^
        ,uProofOfAddress     :: Maybe Text -- ^
        }
     deriving (Show,Eq,Ord,Typeable)

-- | to json as per MangoPay format
instance ToJSON NaturalUser  where
    toJSON u=object ["Tag" .= uTag u,"Email" .= uEmail u,"FirstName".= uFirstName u,"LastName" .= uLastName u,"Address" .= uAddress u, "Birthday" .=  uBirthday u
      ,"Nationality" .= uNationality u,"CountryOfResidence" .= uCountryOfResidence u,"Occupation" .= uOccupation u, "IncomeRange" .= uIncomeRange u,"ProofOfIdentity" .= uProofOfIdentity u
      ,"ProofOfAddress" .= uProofOfAddress u,"PersonType" .= Natural]

-- | from json as per MangoPay format
instance FromJSON NaturalUser where
    parseJSON (Object v) =NaturalUser <$>
                         v .: "Id"  <*>
                         v .: "CreationDate" <*>
                         v .: "Email" <*>
                         v .: "FirstName" <*>
                         v .: "LastName" <*>
                         v .:? "Address" <*>
                         v .: "Birthday" <*>
                         v .: "Nationality" <*>
                         v .: "CountryOfResidence" <*>
                         v .:? "Occupation" <*>
                         v .:? "IncomeRange" <*>
                         v .:? "Tag" <*>
                         v .:? "ProofOfIdentity" <*>
                         v .:? "ProofOfAddress"
    parseJSON _= fail "NaturalUser"

-- | User ID
type LegalUserID = Text

-- | the type of legal user
data LegalUserType = Business | Organization
      deriving (Show,Read,Eq,Ord,Enum,Bounded,Typeable)

-- | to json as per MangoPay format
instance ToJSON LegalUserType  where
    toJSON Business="BUSINESS"
    toJSON Organization="ORGANIZATION"

-- | from json as per MangoPay format
instance FromJSON LegalUserType where
    parseJSON (String "BUSINESS") =pure Business
    parseJSON (String "ORGANIZATION") =pure Organization
    parseJSON _= fail "LegalUserType"

-- | a legal user
-- <http://docs.mangopay.com/api-references/users/legal-users/>
data LegalUser=LegalUser {
        lId                                     :: Maybe Text -- ^   The Id of the object
        ,lCreationDate                          :: Maybe POSIXTime -- ^ The creation date of the user object
        ,lEmail                                 :: Text -- ^ The email of the company or the organization
        ,lName                                  :: Text -- ^ The name of the company or the organization
        ,lLegalPersonType                       :: LegalUserType -- ^ The type of the legal user (‘BUSINESS’ or ’ORGANIZATION’)
        ,lHeadquartersAddress                   :: Maybe Text -- ^ The address of the company’s headquarters
        ,lLegalRepresentativeFirstName          :: Text -- ^ The firstname of the company’s Legal representative person
        ,lLegalRepresentativeLastName           :: Text -- ^ The lastname of the company’s Legal representative person
        ,lLegalRepresentativeAddress            :: Maybe Text -- ^ The address of the company’s Legal representative person
        ,lLegalRepresentativeEmail              :: Maybe Text -- ^  The email of the company’s Legal representative person
        ,lLegalRepresentativeBirthday           :: POSIXTime -- ^ The birthdate of the company’s Legal representative person
        ,lLegalRepresentativeNationality        :: CountryCode -- ^ the nationality of the company’s Legal representative person
        ,lLegalRepresentativeCountryOfResidence :: CountryCode -- ^  The country of residence of the company’s Legal representative person
        ,lStatute                               :: Maybe Text -- ^  The business statute of the company
        ,lTag                                   :: Maybe Text -- ^  Custom data
        ,lProofOfRegistration                   :: Maybe Text -- ^   The proof of registration of the company
        ,lShareholderDeclaration                :: Maybe Text -- ^   The shareholder declaration of the company
        }
        deriving (Show,Eq,Ord,Typeable)

-- | to json as per MangoPay format
instance ToJSON LegalUser  where
    toJSON u=object ["Tag" .= lTag u,"Email" .= lEmail u,"Name".= lName u,"LegalPersonType" .= lLegalPersonType u,"HeadquartersAddress" .= lHeadquartersAddress u, "LegalRepresentativeFirstName" .=  lLegalRepresentativeFirstName u
      ,"LegalRepresentativeLastName" .= lLegalRepresentativeLastName u,"LegalRepresentativeAddress" .= lLegalRepresentativeAddress u,"LegalRepresentativeEmail" .= lLegalRepresentativeEmail u, "LegalRepresentativeBirthday" .= lLegalRepresentativeBirthday u,"LegalRepresentativeNationality" .= lLegalRepresentativeNationality u
      ,"LegalRepresentativeCountryOfResidence" .= lLegalRepresentativeCountryOfResidence u,"Statute" .= lStatute u,"ProofOfRegistration" .=lProofOfRegistration u,"ShareholderDeclaration" .=lShareholderDeclaration u,"PersonType" .= Legal]

-- | from json as per MangoPay format
instance FromJSON LegalUser where
    parseJSON (Object v) =LegalUser <$>
                         v .: "Id"  <*>
                         v .: "CreationDate" <*>
                         v .: "Email" <*>
                         v .: "Name" <*>
                         v .: "LegalPersonType" <*>
                         v .:? "HeadquartersAddress" <*>
                         v .: "LegalRepresentativeFirstName" <*>
                         v .: "LegalRepresentativeLastName" <*>
                         v .:? "LegalRepresentativeAddress" <*>
                         v .:? "LegalRepresentativeEmail" <*>
                         v .: "LegalRepresentativeBirthday" <*>
                         v .: "LegalRepresentativeNationality" <*>
                         v .: "LegalRepresentativeCountryOfResidence" <*>
                         v .:? "Statute" <*>
                         v .:? "Tag" <*>
                         v .:? "ProofOfRegistration" <*>
                         v .:? "ShareholderDeclaration"
    parseJSON _= fail "NaturalUser"

-- | Type of user.
data PersonType =  Natural | Legal
        deriving (Show,Read,Eq,Ord,Bounded,Enum,Typeable)

-- | to json as per MangoPay format
instance ToJSON PersonType  where
    toJSON Natural="NATURAL"
    toJSON Legal="LEGAL"

-- | from json as per MangoPay format
instance FromJSON PersonType where
    parseJSON (String "NATURAL") =pure Natural
    parseJSON (String "LEGAL") =pure Legal
    parseJSON _= fail "PersonType"

-- | a short user reference
data UserRef=UserRef {
        urId             :: AnyUserID
        , urCreationDate :: POSIXTime
        , urPersonType   :: PersonType
        , urEmail        :: Text
        , urTag          :: Maybe Text
        }
        deriving (Show,Eq,Ord,Typeable)

-- | to json as per MangoPay format
instance ToJSON UserRef  where
    toJSON ur=object [ "PersonType" .= urPersonType ur, "Email" .= urEmail ur,"Id" .= urId ur,
        "Tag" .= urTag ur,"CreationDate" .= urCreationDate ur]


-- | from json as per MangoPay format
instance FromJSON UserRef where
    parseJSON (Object v) =UserRef <$>
          v .: "Id" <*>
          v .: "CreationDate"<*>
          v .: "PersonType" <*>
          v .: "Email" <*>
          v .:? "Tag"
    parseJSON _=fail "UserRef"

