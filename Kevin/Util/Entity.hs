module Kevin.Util.Entity (
    entityEncode,
    entityDecode
) where

import Prelude hiding (take)
import Text.HTML.TagSoup.Entity
import qualified Data.Text as T
import Data.Attoparsec.Text
import Data.Char
import Control.Applicative ((<|>), (<$>), (<*>))

decodeCharacter :: Parser T.Text
decodeCharacter = entityNumeric <|> entityNamed <|> take 1

entityNumeric :: Parser T.Text
entityNumeric = do
    string "&#"
    entity <- T.append <$> option "" (string "x") <*> takeWhile1 (inClass "a-fA-F0-9")
    char ';'
    return $ maybe "?" T.singleton $ lookupNumericEntity $ T.unpack entity

entityNamed :: Parser T.Text
entityNamed = do
    char '&'
    entity <- takeWhile1 isAlpha
    char ';'
    return $ maybe "?" T.singleton $ lookupNamedEntity $ T.unpack entity

decodeParser :: Parser T.Text
decodeParser = T.concat <$> many1 decodeCharacter

entityDecode :: T.Text -> T.Text
entityDecode "" = ""
entityDecode str = case parseOnly decodeParser str of
    Left err -> error $ "entityDecode: " ++ err
    Right s -> s

entityEncode :: T.Text -> T.Text
entityEncode = T.pack . concat . entityEncodeS . T.unpack

entityEncodeS :: String -> [String]
entityEncodeS [] = []
entityEncodeS (x:xs) | x < '\127' = [x]:entityEncodeS xs
                     | otherwise  = ("&#" ++ show (ord x) ++ ";"):entityEncodeS xs