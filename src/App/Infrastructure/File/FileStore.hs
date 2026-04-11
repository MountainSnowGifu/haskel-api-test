{-# LANGUAGE OverloadedStrings #-}

module App.Infrastructure.File.FileStore
  ( boardUploadDir,
    uploadUrlPrefix,
    deleteFileIfExists,
  )
where

import Data.Text (Text)
import System.Directory (copyFile, createDirectoryIfMissing, doesFileExist, getFileSize, removeFile)

boardUploadDir :: String
boardUploadDir = "static/board/uploads"

uploadUrlPrefix :: Text
uploadUrlPrefix = "/api/board/uploads/"

deleteFileIfExists :: FilePath -> IO ()
deleteFileIfExists path = do
  exists <- doesFileExist path
  if exists
    then removeFile path
    else putStrLn $ "ファイルが存在しません: " ++ path