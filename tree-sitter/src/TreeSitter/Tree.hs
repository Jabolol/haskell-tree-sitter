{-# LANGUAGE DeriveGeneric #-}

module TreeSitter.Tree
  ( Tree,
    TSInputEdit (..),
    withRootNode,
    withFRootNode,
    ts_tree_edit,
    ts_tree_delete,
    ts_tree_root_node_p,
    ts_tree_to_string,
  )
where

import Foreign
import Foreign.C
import GHC.Generics
import TreeSitter.Language
import TreeSitter.Node

-- | This type is uninhabited and used only for type safety within 'Ptr' values.
data Tree

withRootNode :: Ptr Tree -> (Ptr Node -> IO a) -> IO a
withRootNode tree action = alloca $ \ptr -> do
  ts_tree_root_node_p tree ptr
  action ptr

withFRootNode :: Ptr Tree -> (ForeignPtr Node -> IO a) -> IO a
withFRootNode tree action =
  alloca $ \outPtr -> do
    ts_tree_root_node_p tree outPtr
    fPtr <- newForeignPtr_ outPtr
    action fPtr

-- | Locational info used for to adjust the source ranges of a 'Tree'\'s nodes.
--   This record dirrectly corresponds to the C struct of the same name.
data TSInputEdit = TSInputEdit
  { start_byte :: !Word32,
    old_end_byte :: !Word32,
    new_end_byte :: !Word32,
    start_point :: !TSPoint,
    old_end_point :: !TSPoint,
    new_end_point :: !TSPoint
  }
  deriving (Show, Eq, Generic)

instance Storable TSInputEdit where
  alignment _ = alignment (0 :: Int32)
  sizeOf _ = 36
  peek =
    evalStruct $
      TSInputEdit
        <$> peekStruct
        <*> peekStruct
        <*> peekStruct
        <*> peekStruct
        <*> peekStruct
        <*> peekStruct
  poke ptr (TSInputEdit sb oldEb newEb sp oldEp newEp) =
    flip evalStruct ptr $ do
      pokeStruct sb
      pokeStruct oldEb
      pokeStruct newEb
      pokeStruct sp
      pokeStruct oldEp
      pokeStruct newEp

foreign import ccall safe "ts_tree_edit" ts_tree_edit :: Ptr Tree -> Ptr TSInputEdit -> IO ()

foreign import ccall safe "ts_tree_delete" ts_tree_delete :: Ptr Tree -> IO ()

foreign import ccall unsafe "src/bridge.c ts_tree_root_node_p" ts_tree_root_node_p :: Ptr Tree -> Ptr Node -> IO ()

foreign import ccall unsafe "src/bridge.c ts_tree_to_string" ts_tree_to_string :: CString -> Ptr Language -> IO CString
