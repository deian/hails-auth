{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE TypeSynonymInstances #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
module Models where

import qualified Data.ByteString.Char8 as S8
import Data.IterIO.Http.Support.Action
import Data.Maybe
import System.IO

import Data.Bson
import Data.Typeable
import Database.MongoDB.Structured
import Database.MongoDB.Structured.Deriving.TH
import Database.MongoDB.Structured.Query

import Control.Monad
import Control.Exception

-- | Perform action on DB. This is slow because it always tears down
-- the connection.
withDB act = do
   pipe <- runIOE $ connect (host "localhost")
   qr <- access pipe master "hails" act
   close pipe
   case qr of
    Right r -> return r
    Left e  -> throwIO . userError $ "Failed with: " ++ show e

data User = User { userId       :: SObjId
                 , userName     :: String
                 , userEmail    :: String
                 , userPassword :: String
                 } deriving (Eq, Show, Typeable)
$(deriveStructured ''User)

-- | Insert a user into database
insertUser :: User -> IO ObjectId
insertUser user = withDB $ liftM (unSObjId . fromJust . cast') $ insert user

-- | Save user into database
updateUser :: User -> IO ()
updateUser user = withDB $ save user

-- | Find existing user
findUser :: String -> IO (Maybe User)
findUser uName = withDB $ do
  let query = select (UserName .== uName)
  findOne query