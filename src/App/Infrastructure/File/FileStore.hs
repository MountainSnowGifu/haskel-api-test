{-# LANGUAGE OverloadedStrings #-}

module App.Infrastructure.File.FileStore
  ( boardUploadDir,
    deleteFileIfExists,
    deleteUploadedFile,
    prepareUpload,
    commitUpload,
    UploadError (..),
    UploadPlan (..),
  )
where

import Data.Char (toLower)
import Data.Text (Text, pack, unpack)
import Data.UUID (toText)
import Data.UUID.V4 (nextRandom)
import System.Directory (copyFile, createDirectoryIfMissing, doesFileExist, getFileSize, removeFile)
import System.FilePath (takeDirectory, takeExtension)

boardUploadDir :: String
boardUploadDir = "static/board/uploads"

uploadUrlPrefix :: Text
uploadUrlPrefix = "/api/board/uploads/"

allowedExtensions :: [String]
allowedExtensions = [".jpg", ".jpeg", ".png", ".gif", ".webp", ".pdf"]

maxFileSize :: Integer
maxFileSize = 10 * 1024 * 1024

data UploadError = FileTypeNotAllowed | FileTooLarge
  deriving (Show, Eq)

-- | ファイルコピー前に作成するアップロード計画。
-- バリデーション（拡張子・サイズ）と UUID 生成のみを行い、
-- ディスク書き込みは commitUpload に委ねる。
data UploadPlan = UploadPlan
  { planFileId   :: Text     -- UUID 文字列（DB の attachment_id に使う）
  , planUrl      :: Text     -- 公開 URL
  , planFileName :: Text     -- 保存ファイル名（uuid + 拡張子）
  , planDestPath :: FilePath -- 保存先フルパス
  }

-- | バリデーションと UUID 生成を行い UploadPlan を返す。
-- ディスクには触れない。
prepareUpload :: FilePath -> Int -> String -> IO (Either UploadError UploadPlan)
prepareUpload srcPath boardId originalName = do
  let ext = map toLower $ takeExtension originalName
  if ext `notElem` allowedExtensions
    then return (Left FileTypeNotAllowed)
    else do
      fileSize <- getFileSize srcPath
      if fileSize > maxFileSize
        then return (Left FileTooLarge)
        else do
          uuid <- nextRandom
          let fileId   = toText uuid
              fileName = fileId <> pack ext
              bidStr   = show boardId
              dest     = boardUploadDir ++ "/" ++ bidStr ++ "/" ++ unpack fileName
              url      = uploadUrlPrefix <> pack bidStr <> "/" <> fileName
          return $ Right $ UploadPlan fileId url fileName dest

-- | UploadPlan に従ってディレクトリを作成しファイルをコピーする。
commitUpload :: FilePath -> UploadPlan -> IO ()
commitUpload srcPath plan = do
  createDirectoryIfMissing True (takeDirectory (planDestPath plan))
  copyFile srcPath (planDestPath plan)

-- | board_id と filename から保存先パスを組み立てて削除する。
-- パスの知識をインフラ層に閉じ込めるためのヘルパー。
deleteUploadedFile :: Int -> Text -> IO ()
deleteUploadedFile boardId fileName =
  deleteFileIfExists (boardUploadDir ++ "/" ++ show boardId ++ "/" ++ unpack fileName)

deleteFileIfExists :: FilePath -> IO ()
deleteFileIfExists path = do
  exists <- doesFileExist path
  if exists
    then removeFile path
    else putStrLn $ "ファイルが存在しません: " ++ path