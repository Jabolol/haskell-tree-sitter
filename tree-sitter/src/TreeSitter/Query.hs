module TreeSitter.Query
  ( Query,
    withQuery,
    ts_query_new_p,
    ts_query_delete,
  )
where

import Control.Exception as Exc
import Data.Word
import Foreign.C
import Foreign.Ptr
import TreeSitter.Language

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

foreign import ccall unsafe "src/bridge.c ts_query_new_p" ts_query_new_p :: Ptr Language -> CString -> Word32 -> IO (Ptr Query)

foreign import ccall unsafe "ts_query_delete" ts_query_delete :: Ptr Query -> IO ()
