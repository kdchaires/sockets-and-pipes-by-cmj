module Book where

import Relude
import Prelude ()

import qualified System.Directory as Dir
import System.FilePath ((</>))

import qualified System.IO as IO

import Control.Monad.Trans.Resource (
    ReleaseKey,
    ResourceT,
    allocate,
    runResourceT,
 )

import qualified Control.Exception.Safe as Ex

getDataDir :: IO FilePath
getDataDir = do
    dir <- Dir.getXdgDirectory Dir.XdgData "sockets-and-pipes"
    Dir.createDirectoryIfMissing True dir
    pure dir

-- Exercise 1 - Define a file resource function
fileResource :: FilePath -> IOMode -> ResourceT IO (ReleaseKey, Handle)
fileResource dir m = allocate (IO.openFile dir m) IO.hClose

writeGreetingFile :: IO ()
writeGreetingFile = do
    dir <- getDataDir
    h <- IO.openFile (dir </> "greeting.txt") WriteMode
    IO.hPutStrLn h "hello"
    IO.hPutStrLn h "word"
    IO.hClose h

writeGreetingSafe :: IO ()
writeGreetingSafe = runResourceT @IO do
    dir <- liftIO getDataDir
    (_releaseKey, h) <- fileResource (dir </> "greeting.txt") WriteMode
    liftIO (IO.hPutStrLn h "hello")
    liftIO (IO.hPutStrLn h "world")

-- Exercise 2 - Showing handles: Write a program that uses show and hShow
-- on a few handles to experiment and see the difference between these
-- two functions’ outputs.
handlePrintTest :: IO ()
handlePrintTest = runResourceT @IO do
    dir <- liftIO getDataDir
    (_, h) <- fileResource (dir </> "greeting.txt") ReadMode
    contents <- liftIO (IO.hShow h)
    putStrLn contents
    putStrLn $ show h

-- Excercise 3 - Exhaustion: How many file handles can you have open at
-- once
howManyHandles :: IO ()
howManyHandles = runResourceT @IO do
    hs <- openManyHandles
    putStrLn ("Opened" <> show (length hs) <> "handles")

openManyHandles :: ResourceT IO [Handle]
openManyHandles = _

fileResourceMaybe :: ResourceT IO (Maybe Handle)
fileResourceMaybe = do
    dir <- liftIO getDataDir
    result <- Ex.tryIO do
        (_, h) <- fileResource (dir </> "greeting.txt") ReadMode
        pure $ Just h
    case result of
        Right x -> pure x
        Left e -> do
            print (displayException e)
            pure Nothing
