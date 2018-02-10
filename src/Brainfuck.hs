module Brainfuck (
        Expression (..),
        Statement (..),
        isLoop,
        isComment,
        addExpressions,
        isZeroShift,
        usedOffsets,
        parseStatements
    )
    where

import Data.Char
import Data.List
import Data.Maybe
import Data.Ratio

type IntRatio = Ratio Int

data Expression
    = Const Int                 --arg0
    | Var Int IntRatio          --p[arg0] * arg1
    | Sum Int [(Int, IntRatio)] --arg0 + p[arg1[0].0] * arg1[0].1 + p[arg1[1].0] * arg1[1].1 + ...
    deriving(Eq, Show)

data Statement
    = Add Int Expression    -- p[arg0] += arg1
    | Set Int Expression    -- p[arg0] = arg1
    | Shift Int             -- p += arg
    | Loop Int [Statement]  -- while(p[arg0]) { arg1 }
    | Input Int             -- p[arg0] = getchar()
    | Output Expression     -- putchar(p[arg0])
    | Print String          -- puts(arg0) --only generated by ConstantFold
    | Comment String        -- /*arg0*/
    deriving(Eq, Show)

isLoop (Loop _ _)       = True
isLoop _                = False

isComment (Comment _)   = True
isComment _             = False

addExpressions expr1 expr2
    | null vars                     = Const val
    | val == 0 && length vars == 1  = Var (fst $ head vars) (snd $ head vars)
    | otherwise                     = Sum val vars
    where
        exprToSum expr              = case expr of
            Const val               -> (val, [])
            Var off mul             -> (0, [(off, mul)])
            Sum val vars            -> (val, vars)
        (val1, vars1)               = exprToSum expr1
        (val2, vars2)               = exprToSum expr2
        val                         = val1 + val2
        vars                        = vars1 ++ vars2

isZeroShift statements              = all isJust vals && valSum == 0
    where
        vals                        = map getShift statements
        valSum                      = sum $ catMaybes vals
        getShift (Shift val)        = Just val
        getShift (Loop _ children)  = if isZeroShift children
            then Just 0
            else Nothing
        getShift _                  = Just 0

usedOffsets stmt            = case stmt of
    Add off expr            -> ([off], exprUsedOffsets expr)
    Set off expr            -> ([off], exprUsedOffsets expr)
    Shift _                 -> ([], [])
    Input off               -> ([off], [])
    Output expr             -> ([], exprUsedOffsets expr)
    Print _                 -> ([], [])
    Loop off children       -> (childSet, off : childUsed)
        where
            result          = map usedOffsets children
            childSet        = (concat . map fst) result
            childUsed       = (concat . map snd) result
    Comment _               -> ([], [])
    where
        exprUsedOffsets expr= case expr of
            Const _         -> []
            Var off _       -> [off]
            Sum _ vars      -> map fst vars

parseStatements str         = fst $ parseStatements' str False

parseStatements' [] True    = error "Too many [ or too few ]"
parseStatements' [] False   = ([], [])
parseStatements' (x:xs) inner
    | x == ']' && inner     = ([], xs)
    | x == ']'              = error "Too many ] or too few ["
    | x == '['              = ((Loop 0 body) : rest', xs'')
    | otherwise             = (curr : rest, xs')
    where
        curr                = case x of
            '+'             -> Add 0 (Const 1)
            '-'             -> Add 0 (Const (-1))
            '>'             -> Shift 1
            '<'             -> Shift (-1)
            ','             -> Input 0
            '.'             -> Output (Var 0 1)
            _               -> Comment [x]
        (rest, xs')         = parseStatements' xs inner
        (body, bodyXS)      = parseStatements' xs True
        (rest', xs'')       = parseStatements' bodyXS inner
