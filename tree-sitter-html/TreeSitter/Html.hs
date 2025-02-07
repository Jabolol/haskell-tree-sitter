module TreeSitter.Html
( tree_sitter_html
, getNodeTypesPath
, getTestCorpusDir
) where

import Foreign.Ptr
import TreeSitter.Language
import Paths_tree_sitter_html

foreign import ccall unsafe "vendor/tree-sitter-html/html/src/parser.c tree_sitter_html" tree_sitter_html :: Ptr Language

getNodeTypesPath :: IO FilePath
getNodeTypesPath = getDataFileName "vendor/tree-sitter-html/html/src/node-types.json"

getTestCorpusDir :: IO FilePath
getTestCorpusDir = getDataFileName "vendor/tree-sitter-html/html/corpus"
