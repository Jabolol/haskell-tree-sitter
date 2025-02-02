module TreeSitter.JavaScript
( tree_sitter_javascript
, getNodeTypesPath
, getTestCorpusDir
) where

import Foreign.Ptr
import TreeSitter.Language
import Paths_tree_sitter_javascript

foreign import ccall unsafe "vendor/tree-sitter-javascript/javascript/src/parser.c tree_sitter_javascript" tree_sitter_javascript :: Ptr Language

getNodeTypesPath :: IO FilePath
getNodeTypesPath = getDataFileName "vendor/tree-sitter-javascript/javascript/src/node-types.json"

getTestCorpusDir :: IO FilePath
getTestCorpusDir = getDataFileName "vendor/tree-sitter-javascript/javascript/corpus"
