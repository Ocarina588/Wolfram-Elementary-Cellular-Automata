module Main where
import System.Environment
import qualified Control.Exception as Exc
import System.Exit
import Text.Read

data Conf = Conf {
    r :: Maybe Int,
    s :: Maybe Int,
    l :: Maybe Int,
    w :: Maybe Int,
    m :: Maybe Int
} deriving (Show)

initConf :: Conf
initConf = Conf {r = Nothing, s = Just 0, l = Just (-1),
                 w = Just 80, m = Just 0}

safeCmp :: Maybe Int -> Maybe Int -> (Int -> Int -> Bool) -> Bool
safeCmp Nothing _ _ = False
safeCmp _ Nothing _ = False
safeCmp (Just x) (Just y) f = f x y

readPos :: String -> Maybe Int
readPos x = if safeCmp a (Just 0) (<) then error "" else a
            where
                a = readMaybe x

getOpts :: Conf -> [String] -> Maybe Conf
getOpts conf (x:y:xs) = case x of
    "--help"   -> error ""
    "-h"       -> error "" 
    "--rule"   -> readPos   y >>= \nb -> getOpts conf {r = Just nb} xs
    "--start"  -> readPos   y >>= \nb -> getOpts conf {s = Just nb} xs
    "--lines"  -> readPos   y >>= \nb -> getOpts conf {l = Just nb} xs
    "--window" -> readPos   y >>= \nb -> getOpts conf {w = Just nb} xs
    "--move"   -> readMaybe y >>= \nb -> getOpts conf {m = Just nb} xs
    _ -> Nothing
getOpts conf [] = Just conf
getOpts _ _ = Nothing

checkOpts :: Maybe Conf -> Maybe Conf
checkOpts Nothing = Nothing
checkOpts (Just x)  | (r x) == Nothing = Nothing
                    | (m x) == Nothing = Nothing
                    | safeCmp (w x) (Just 1) (<) = Nothing
                    | safeCmp (r x) (Just 255) (>) = Nothing
                    | otherwise = Just x

getBinary :: Int -> Maybe Int -> String -> String
getBinary (-1) _ s = s
getBinary i (Just nb) s = case nb `mod` 2 of
                            0 -> getBinary (i - 1) (Just (nb `div` 2)) (' ':s)
                            1 -> getBinary (i - 1) (Just (nb `div` 2)) ('*':s)

getCell :: String -> Char -> Char -> Char -> Char
getCell base '*' '*' '*' = base !! 0
getCell base '*' '*' ' ' = base !! 1
getCell base '*' ' ' '*' = base !! 2
getCell base '*' ' ' ' ' = base !! 3
getCell base ' ' '*' '*' = base !! 4
getCell base ' ' '*' ' ' = base !! 5
getCell base ' ' ' ' '*' = base !! 6
getCell base ' ' ' ' ' ' = base !! 7

newgen :: String -> String -> String
newgen rule (x:y:z:xs) = getCell rule x y z : newgen rule (y:z:xs)
newgen rule _ = ""

createVoid :: Int -> String
createVoid 0 = ""
createVoid i = ' ':createVoid (i - 1)

makeVoid :: Int -> Int ->String -> String
makeVoid w m gen =
    createVoid ((w - length gen) `div` 2 + (w - length gen) `rem` 2) ++ gen ++
    createVoid ((w - length gen) `div` 2)

makeMiddle :: Int -> Int -> String -> String
makeMiddle w m gen = take w (drop ((length gen `div` 2) - (w `div` 2)) gen)

printGen :: Maybe Int -> Maybe Int -> Maybe Int -> String -> IO()
printGen (Just l) (Just w) (Just m) gen = 
    if length str > w
    then putStrLn (makeMiddle w m str)
    else putStrLn (makeVoid w m str)
    where
        str = (\x -> if m >= 0 then createVoid (m * 2 ) ++ gen
            else gen ++ createVoid (-2 * m )) 0

algo :: Int -> Int -> Conf -> String -> String -> IO()
algo j i conf rule prevgen =
    case safeCmp (Just i) (l conf) (==) of
        True -> putStr ""
        False -> case safeCmp (Just j) (s conf) (\x y -> x >= y) of
                     True -> printGen (l conf) (w conf) (m conf) new >>
                         algo (j + 1) (i + 1) conf rule ("  " ++ new ++ "  ")
                     False -> algo (j + 1) i conf rule ("  " ++ new ++ "  ")
                 where
                     new = (\x -> if x == "" then "*"
                         else newgen rule prevgen) prevgen

wolfram :: IO ()
wolfram = do
    args <- getArgs
    case checkOpts (getOpts initConf args) of
        Nothing ->  error ""
        Just x  ->  algo 0 0 x (getBinary 7 (r x) "") ""

main :: IO ()
main = Exc.catch wolfram handler
    where
        handler :: Exc.ErrorCall -> IO ()
        handler _ =
                putStrLn "usage ./wolfram --rule RULE [optional]" >>
                putStrLn "--rule:   the ruleset to use (no default value, mandatory)." >>
                putStrLn "--start:  the generation number at which to start the display. The default value is 0." >>
                putStrLn "--lines:  the number of lines to display. When omitted, the program never stops." >>
                putStrLn "--window: the number of cells to display on each line (line width). If even," >>
                putStrLn " the central cell is displayed in the next cell on the right. The default value is 80." >>
                putStrLn "--move:   a translation to apply on the window. If negative, the window is translated to the left." >>
                putStrLn " If positive, it's translated to the right." >>
                exitWith (ExitFailure 84)