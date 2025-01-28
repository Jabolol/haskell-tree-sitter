module TreeSitter.Query
  ( Query,
    withQuery,
    withFQuery,
    withQueryMatches,
    withFQueryMatches,
    ts_query_new_p,
    ts_query_delete,
    ts_query_cursor_new_p,
    ts_query_cursor_delete_p,
    ts_query_cursor_exec_p,
    ts_query_matches_to_nodes,
  )
where

import Control.Exception as Exc
import Data.Word
import Foreign
import Foreign.C
import TreeSitter.Cursor
import TreeSitter.Language
import TreeSitter.Tree
import TreeSitter.Node

-- | A tree-sitter query for pattern matching in syntax trees.
--
--   This type is uninhabited and used only for type safety within 'Ptr' values.
data Query

withQuery :: Ptr Language -> CString -> Word32 -> (Ptr Query -> IO a) -> IO a
withQuery language source len action =
  Exc.bracket
    (ts_query_new_p language source len)
    ts_query_delete
    action

withFQuery :: Ptr Language -> CString -> Word32 -> (ForeignPtr Query -> IO a) -> IO a
withFQuery lang cstr size action = do
  rawQuery <- ts_query_new_p lang cstr size
  fPtr <- newForeignPtr p_ts_query_delete rawQuery
  action fPtr

-- | Execute a query and process the matched nodes with a callback function.
-- The matched nodes array is automatically freed after the callback is executed.
withQueryMatches :: Ptr Tree -> Ptr Query -> (Ptr Node -> Word32 -> IO a) -> IO a
withQueryMatches tree query action = alloca $ \matchCountPtr -> 
  Exc.bracket
    (ts_query_matches_to_nodes tree query matchCountPtr)
    free
    (\nodesPtr -> peek matchCountPtr >>= action nodesPtr)

withFQueryMatches :: Ptr Tree -> Ptr Query -> (ForeignPtr Node -> Word32 -> IO a) -> IO a
withFQueryMatches tree query action = alloca $ \countPtr -> do
  nodesPtr <- ts_query_matches_to_nodes tree query countPtr
  countVal <- peek countPtr
  fPtr <- newForeignPtr finalizerFree nodesPtr
  action fPtr countVal

foreign import ccall unsafe "src/bridge.c ts_query_new_p" ts_query_new_p :: Ptr Language -> CString -> Word32 -> IO (Ptr Query)

foreign import ccall unsafe "ts_query_delete" ts_query_delete :: Ptr Query -> IO ()

foreign import ccall unsafe "src/bridge.c ts_query_cursor_new_p" ts_query_cursor_new_p :: IO (Ptr Cursor)

foreign import ccall unsafe "src/bridge.c ts_query_cursor_delete_p" ts_query_cursor_delete_p :: Ptr Cursor -> IO ()

foreign import ccall unsafe "src/bridge.c ts_query_cursor_exec_p" ts_query_cursor_exec_p :: Ptr Cursor -> Ptr Query -> Ptr Node -> IO ()

foreign import ccall unsafe "src/bridge.c ts_query_matches_to_nodes" ts_query_matches_to_nodes :: Ptr Tree -> Ptr Query -> Ptr Word32 -> IO (Ptr Node)

foreign import ccall "&ts_query_delete" p_ts_query_delete :: FunPtr (Ptr Query -> IO ())
