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
