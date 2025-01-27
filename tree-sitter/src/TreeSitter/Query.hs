module TreeSitter.Query
  ( Query,
    withQuery,
    withQueryMatches,
    ts_query_new_p,
    ts_query_delete,
    ts_query_cursor_new_p,
    ts_query_cursor_delete_p,
    ts_query_cursor_exec_p,
    ts_query_matches_to_nodes_p,
  )
where

import Control.Exception as Exc
import Data.Word
import Foreign
import Foreign.C
import TreeSitter.Cursor
import TreeSitter.Language
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

-- | Execute a query and process the matched nodes with a callback function.
-- The matched nodes array is automatically freed after the callback is executed.
withQueryMatches :: Ptr Cursor -> Ptr Query -> Ptr Node -> (Ptr Node -> Word32 -> IO a) -> IO a
withQueryMatches cursor query node action = alloca $ \countPtr ->
  Exc.bracket
    (ts_query_matches_to_nodes_p cursor countPtr)
    free
    ( \nodesPtr -> do
        ts_query_cursor_exec_p cursor query node
        count <- peek countPtr
        action nodesPtr count
    )

foreign import ccall unsafe "src/bridge.c ts_query_new_p" ts_query_new_p :: Ptr Language -> CString -> Word32 -> IO (Ptr Query)

foreign import ccall unsafe "ts_query_delete" ts_query_delete :: Ptr Query -> IO ()

foreign import ccall unsafe "src/bridge.c ts_query_cursor_new_p" ts_query_cursor_new_p :: IO (Ptr Cursor)

foreign import ccall unsafe "src/bridge.c ts_query_cursor_delete_p" ts_query_cursor_delete_p :: Ptr Cursor -> IO ()

foreign import ccall unsafe "src/bridge.c ts_query_cursor_exec_p" ts_query_cursor_exec_p :: Ptr Cursor -> Ptr Query -> Ptr Node -> IO ()

foreign import ccall unsafe "src/bridge.c ts_query_matches_to_nodes_p" ts_query_matches_to_nodes_p :: Ptr Cursor -> Ptr Word32 -> IO (Ptr Node)
