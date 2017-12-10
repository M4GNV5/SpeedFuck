module Brainfuck where

import Data.List

data Statement
    = Math Int Int          -- p[arg0] += arg1
    | Set Int Int Int Int   -- p[arg0] = p[arg1] * arg2 + arg3
    | Shift Int             -- p += arg
    | Loop [Statement]      -- while(*p) { arg }
    | Input Int             -- p[arg0] = getchar()
    | Output Int            -- putchar(p[arg0])
    | Comment String        -- //arg0
    deriving(Eq)

instance Show Statement where
    show (Math off val)
        | val < 0       = "p[" ++ (show off) ++ "] -= " ++ (show (-val))
        | otherwise     = "p[" ++ (show off) ++ "] += " ++ (show val)
    show (Shift x)      = "p += " ++ (show x)
    show (Set x y z a) = "p[" ++ (show x) ++ "] = " ++ mulStr ++ addStr
        where
            mulStr      = case z of
                0       -> ""
                1       -> "p[" ++ (show y) ++ "]"
                _       -> "p[" ++ (show y) ++ "] * " ++ (show z)
            addStr
                | z == 0    = show a
                | a == 0    = ""
                | a < 0     = " - " ++ (show (-a))
                | otherwise = " + " ++ (show a)
    show (Loop s)       = "while(*p) { " ++ (intercalate "; " $ map show s) ++ " }"
    show (Input off)    = "p[" ++ (show off) ++ "] = getchar()"
    show (Output off)   = "putchar(p[" ++ (show off) ++ "])"
    show (Comment str)  = "/*" ++ str ++ "*/"

isLoop (Loop _)         = True
isLoop _                = False

isComment (Comment _)   = True
isComment _             = False

parseStatements str     = fst $ parseStatements' str

parseStatements' []     = ([], [])
parseStatements' (x:xs)
    | x == ']'          = ([], xs)
    | x == '['          = ((Loop rest) : rest', xs'')
    | otherwise         = (curr : rest, xs')
    where
        curr            = case x of
            '+'         -> Math 0 1
            '-'         -> Math 0 (-1)
            '>'         -> Shift 1
            '<'         -> Shift (-1)
            ','         -> Input 0
            '.'         -> Output 0
            _           -> Comment [x]
        (rest, xs')     = parseStatements' xs
        (rest', xs'')   = parseStatements' xs'
