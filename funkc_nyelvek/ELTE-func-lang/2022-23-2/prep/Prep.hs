import Data.Map
import Control.Monad.State

-- data model
data Graph = Graph
    { nodes   :: Map Int Node
    , edges   :: Map Int Edge
    , node_id :: Int
    , edge_id :: Int
    } deriving (Show)

data Node = Node
    { nodeId     :: Int
    , nodeClass  :: String
    , nodeData   :: NodeData
    , edgesFwd   :: [Int]
    , edgesBack  :: [Int]
    }
instance Show Node where
  show (Node id nodeClass nodeData fwd bck) = 
    "\nNode #" ++ show id ++ {-" " ++ show nodeData ++-} " f:" ++ show fwd ++ " b:" ++ show bck

data Edge = Edge
    { edgeId   :: Int
    , from     :: Int
    , tag      :: String
    , idx      :: Int
    , to       :: Int
    }
instance Show Edge where
  show (Edge id from tag idx to) = 
    "\n#" ++ show id ++ " " ++ show from ++ "-[" ++ tag ++ "," ++ show idx ++ "]->" ++ show to


data NodeData
    = Root
    | FileData { fileType :: String, filePath :: String, eol :: String, lastModified :: String, hash :: String }
    | FormData { formType :: String, formTag :: String, paren :: String, pp :: String, hash :: String, formLength :: Int, startScalar :: Int, startLine :: Int, cache :: String }
    | ClauseData { clauseType :: String, var :: String, pp :: String }
    | ExprData { exprType :: String, role :: String, value :: String, pp :: String }
    | TypexpData { typexpType :: String, typexprTag :: String }
    | LexData { lexType :: String, lexData :: String }
    | TokenData { tokenType :: String, text :: String, prews :: String, postws :: String, scalar :: String, linecol :: String }
    | ModuleData { moduleName :: String }
    | RecordData { recordName :: String }
    | FieldData { fieldName :: String }
    | MapData { mapId :: String }
    | MapKeyData { mapKeyId :: String }
    | SpecData { specName :: String, specArity :: Int }
    | SpecParamData { specParamType :: String, specParamName :: String, specParamValue :: String }
    | SpecClauseData -- Empty record
    | SpecGuardData { specGuardValue :: String }
    | NamedTypeData { namedTypeName :: String, namedTypeArity :: Int, isOpaque :: Bool, isBuiltin :: Bool }
    | NamedTypeParamData { namedTypeParamName :: String, namedTypeParamType :: String }
    | NamedTypeBodyData { namedTypeBodyValue :: String }
    | FuncData { funcName :: String, funcArity :: Int, dirty :: String, funcType :: String, opaque :: Bool }
    | VariableData { variableName :: String }
    | EnvData { envName :: String, envValue :: String }
    | EtsTabData { etsTabNames :: String }
    | PidData { pidRegNames :: [String], pidMod :: String, pidFunc :: String, pidAry :: String }
    deriving (Show)


-- type class for database operations
class DB state where
  nodeById :: state -> Int -> Node
  create :: state -> NodeData -> state
  path :: state -> Node -> [Int] -> [Node]

instance DB Graph where
  nodeById state id = nodes state ! id
  create state nodeData =
      let id = node_id state
          node = Node id "Node" nodeData [] []
          newNodes = insert id node (nodes state)
      in Graph newNodes (edges state) (id + 1) (edge_id state)
  path state startN steps = go startN steps where
    go node [] = [node]
    go node (step:xs) =
      let nextNodes = Prelude.map (nodeById state) (edgesFwd node)
      in Prelude.foldl (\acc next -> path state next xs ++ acc) [] nextNodes


-- example graph
init :: Graph
init = Graph empty empty 0 0

graph :: Graph
graph = let 
  nodes = fromList [
    (0, Node 0 "root" Root [1,2] []),
    (1, Node 1 "file" (FileData "file" "/home" "eol" "2023" "hash") [3] [1]),
    (2, Node 2 "file" (FileData "file" "/var" "eol" "2019" "hash") [] [2,3])
    ]
  edges = fromList [
    (1, Edge 1 0 "tag" 1 1),
    (2, Edge 2 0 "tag" 2 2),
    (3, Edge 3 1 "tag" 1 2)
    ]
  in Graph nodes edges 3 4



-- operations on State Monad
-- @see https://wiki.haskell.org/State_Monad
createM :: NodeData -> State Graph Graph
createM nodeData = do {
  state <- get;
  put $ create state nodeData;
  return state
}

dataM :: Int -> State Graph NodeData
dataM id = do {
  state <- get;
  return $ nodeData $ nodeById state id
}

-- exaple usages
addNode :: Graph
addNode = execState (createM (FileData "file" "/home/marcell" "eol" "1998" "hash")) graph

getNodeDataById :: Int -> NodeData
getNodeDataById id = evalState (dataM id) graph
