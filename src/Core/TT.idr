module Core.TT

import public Core.FC
import public Core.Name

import Data.NameMap
import Data.Vect

%default covering

%hide Raw -- from Reflection in the Prelude
%hide Binder
%hide NameType

public export
data NameType : Type where
     Bound   : NameType
     Func    : NameType
     DataCon : (tag : Int) -> (arity : Nat) -> NameType
     TyCon   : (tag : Int) -> (arity : Nat) -> NameType

public export
data Constant 
    = I Int
    | BI Integer
    | Str String
    | Ch Char
    | Db Double
    | WorldVal

    | IntType
    | IntegerType
    | StringType
    | CharType
    | DoubleType
    | WorldType

export
constantEq : (x, y : Constant) -> Maybe (x = y)
constantEq (I x) (I y) = case decEq x y of
                              Yes Refl => Just Refl
                              No contra => Nothing
constantEq (BI x) (BI y) = case decEq x y of
                                Yes Refl => Just Refl
                                No contra => Nothing
constantEq (Str x) (Str y) = case decEq x y of
                                  Yes Refl => Just Refl
                                  No contra => Nothing
constantEq (Ch x) (Ch y) = case decEq x y of
                                Yes Refl => Just Refl
                                No contra => Nothing
constantEq (Db x) (Db y) = Nothing -- no DecEq for Doubles!
constantEq WorldVal WorldVal = Just Refl
constantEq IntType IntType = Just Refl
constantEq IntegerType IntegerType = Just Refl
constantEq StringType StringType = Just Refl
constantEq CharType CharType = Just Refl
constantEq DoubleType DoubleType = Just Refl
constantEq WorldType WorldType = Just Refl
constantEq _ _ = Nothing

export
Show Constant where
  show (I x) = show x
  show (BI x) = show x
  show (Str x) = show x
  show (Ch x) = show x
  show (Db x) = show x
  show WorldVal = "%MkWorld"
  show IntType = "Int"
  show IntegerType = "Integer"
  show StringType = "String"
  show CharType = "Char"
  show DoubleType = "Double"
  show WorldType = "%World"

export
Eq Constant where
  (I x) == (I y) = x == y
  (BI x) == (BI y) = x == y
  (Str x) == (Str y) = x == y
  (Ch x) == (Ch y) = x == y
  (Db x) == (Db y) = x == y
  WorldVal == WorldVal = True
  IntType == IntType = True
  IntegerType == IntegerType = True
  StringType == StringType = True
  CharType == CharType = True
  DoubleType == DoubleType = True
  WorldType == WorldType = True
  _ == _ = False

public export
data PiInfo = Implicit | Explicit | AutoImplicit

export
Show PiInfo where
  show Implicit = "Implicit"
  show Explicit = "Explicit"
  show AutoImplicit = "AutoImplicit"

export
Eq PiInfo where
  (==) Implicit Implicit = True
  (==) Explicit Explicit = True
  (==) AutoImplicit AutoImplicit = True
  (==) _ _ = False

public export
data RigCount = Rig0 | Rig1 | RigW

export
isLinear : RigCount -> Bool
isLinear Rig1 = True
isLinear _ = False

export
Eq RigCount where
  (==) Rig0 Rig0 = True
  (==) Rig1 Rig1 = True
  (==) RigW RigW = True
  (==) _ _ = False

export
Ord RigCount where
  compare Rig0 Rig0 = EQ
  compare Rig0 Rig1 = LT
  compare Rig0 RigW = LT

  compare Rig1 Rig0 = GT
  compare Rig1 Rig1 = EQ
  compare Rig1 RigW = LT

  compare RigW Rig0 = GT
  compare RigW Rig1 = GT
  compare RigW RigW = EQ

export
Show RigCount where
  show Rig0 = "Rig0"
  show Rig1 = "Rig1"
  show RigW = "RigW"

export
rigPlus : RigCount -> RigCount -> RigCount
rigPlus Rig0 Rig0 = Rig0
rigPlus Rig0 Rig1 = Rig1
rigPlus Rig0 RigW = RigW
rigPlus Rig1 Rig0 = Rig1
rigPlus Rig1 Rig1 = RigW
rigPlus Rig1 RigW = RigW
rigPlus RigW Rig0 = RigW
rigPlus RigW Rig1 = RigW
rigPlus RigW RigW = RigW

export
rigMult : RigCount -> RigCount -> RigCount
rigMult Rig0 Rig0 = Rig0
rigMult Rig0 Rig1 = Rig0
rigMult Rig0 RigW = Rig0
rigMult Rig1 Rig0 = Rig0
rigMult Rig1 Rig1 = Rig1
rigMult Rig1 RigW = RigW
rigMult RigW Rig0 = Rig0
rigMult RigW Rig1 = RigW
rigMult RigW RigW = RigW

public export
data Binder : Type -> Type where
	   -- Lambda bound variables with their implicitness
     Lam : RigCount -> PiInfo -> (ty : type) -> Binder type
		 -- Let bound variables with their value
     Let : RigCount -> (val : type) -> (ty : type) -> Binder type
		 -- Forall/pi bound variables with their implicitness
     Pi : RigCount -> PiInfo -> (ty : type) -> Binder type
		 -- pattern bound variables
     PVar : RigCount -> (ty : type) -> Binder type 
		 -- variable bound for an as pattern
     -- TODO: Possibly remove, 'Let', 'As' and 'PAs' might be enough
     PLet : RigCount -> (val : type) -> (ty : type) -> Binder type 
		 -- the type of pattern bound variables
     PVTy : RigCount -> (ty : type) -> Binder type

export
binderType : Binder tm -> tm
binderType (Lam _ x ty) = ty
binderType (Let _ val ty) = ty
binderType (Pi _ x ty) = ty
binderType (PVar _ ty) = ty
binderType (PLet _ val ty) = ty
binderType (PVTy _ ty) = ty

export
multiplicity : Binder tm -> RigCount
multiplicity (Lam c x ty) = c
multiplicity (Let c val ty) = c
multiplicity (Pi c x ty) = c
multiplicity (PVar c ty) = c
multiplicity (PLet c val ty) = c
multiplicity (PVTy c ty) = c
  
export
setMultiplicity : Binder tm -> RigCount -> Binder tm
setMultiplicity (Lam c x ty) c' = Lam c' x ty
setMultiplicity (Let c val ty) c' = Let c' val ty
setMultiplicity (Pi c x ty) c' = Pi c' x ty
setMultiplicity (PVar c ty) c' = PVar c' ty
setMultiplicity (PLet c val ty) c' = PLet c' val ty
setMultiplicity (PVTy c ty) c' = PVTy c' ty

showCount : RigCount -> String
showCount Rig0 = "0 "
showCount Rig1 = "1 "
showCount RigW = ""
  
Show ty => Show (Binder ty) where
	show (Lam c _ t) = "\\" ++ showCount c ++ show t
	show (Pi c _ t) = "Pi " ++ showCount c ++ show t
	show (Let c v t) = "let " ++ showCount c ++ show v ++ " : " ++ show t
	show (PVar c t) = "pat " ++ showCount c ++ show t
	show (PLet c v t) = "plet " ++ showCount c ++ show v ++ " : " ++ show t
	show (PVTy c t) = "pty " ++ showCount c ++ show t

export
setType : Binder tm -> tm -> Binder tm
setType (Lam c x _) ty = Lam c x ty
setType (Let c val _) ty = Let c val ty
setType (Pi c x _) ty = Pi c x ty
setType (PVar c _) ty = PVar c ty
setType (PLet c val _) ty = PLet c val ty
setType (PVTy c _) ty = PVTy c ty

export
Functor Binder where
  map func (Lam c x ty) = Lam c x (func ty)
  map func (Let c val ty) = Let c (func val) (func ty)
  map func (Pi c x ty) = Pi c x (func ty)
  map func (PVar c ty) = PVar c (func ty)
  map func (PLet c val ty) = PLet c (func val) (func ty)
  map func (PVTy c ty) = PVTy c (func ty)

public export
data IsVar : Name -> Nat -> List Name -> Type where
     First : IsVar n Z (n :: ns)
     Later : IsVar n i ns -> IsVar n (S i) (m :: ns)

public export
data Var : List Name -> Type where
     MkVar : {i : Nat} -> {n : _} -> IsVar n i vars -> Var vars

export
sameVar : {i, j : _} -> IsVar n i xs -> IsVar m j xs -> Bool
sameVar {i} {j} _ _ = i == j

public export
record AppInfo where
  constructor MkAppInfo
  argname : Maybe Name
  plicit : PiInfo

export
appInf : Maybe Name -> PiInfo -> AppInfo
appInf n p = MkAppInfo n p

export
implApp : Maybe Name -> AppInfo
implApp n = appInf n Implicit

export
explApp : Maybe Name -> AppInfo
explApp n = appInf n Explicit

namespace CList
  -- A list correspoding to another list
  public export
  data CList : List a -> Type -> Type where
       Nil : CList [] ty
       (::) : (x : ty) -> CList cs ty -> CList (c :: cs) ty

-- Typechecked terms
-- These are guaranteed to be well-scoped wrt local variables, because they are
-- indexed by the names of local variables in scope
public export
data LazyReason = LInf | LLazy 

public export
data Term : List Name -> Type where
     Local : {name : _} ->
             FC -> Maybe RigCount -> 
             (idx : Nat) -> IsVar name idx vars -> Term vars
     Ref : FC -> NameType -> (name : Name) -> Term vars
     -- Metavariables and the scope they are applied to
     Meta : FC -> Name -> Int -> List (Term vars) -> Term vars
     Bind : FC -> (x : Name) -> 
            (b : Binder (Term vars)) -> 
            (scope : Term (x :: vars)) -> Term vars
     App : FC -> (fn : Term vars) -> (p : AppInfo) -> (arg : Term vars) -> Term vars
     -- as patterns; since we check LHS patterns as terms before turning
     -- them into patterns, this helps us get it right. When normalising,
     -- we just reduce the inner term and ignore the 'as' part
     As : FC -> (as : Term vars) -> (pat : Term vars) -> Term vars
     -- Typed laziness annotations
     TDelayed : FC -> LazyReason -> Term vars -> Term vars
     TDelay : FC -> LazyReason -> Term vars -> Term vars
     TForce : FC -> Term vars -> Term vars
     PrimVal : FC -> (c : Constant) -> Term vars
     Erased : FC -> Term vars
     TType : FC -> Term vars

export
getLoc : Term vars -> FC
getLoc (Local fc x idx y) = fc
getLoc (Ref fc x name) = fc
getLoc (Meta fc x y xs) = fc
getLoc (Bind fc x b scope) = fc
getLoc (App fc fn p arg) = fc
getLoc (As fc x y) = fc
getLoc (TDelayed fc x y) = fc
getLoc (TDelay fc x y) = fc
getLoc (TForce fc x) = fc
getLoc (PrimVal fc c) = fc
getLoc (Erased fc) = fc
getLoc (TType fc) = fc

export
Eq LazyReason where
  (==) LInf LInf = True
  (==) LLazy LLazy = True
  (==) _ _ = False

export
varExtend : IsVar x idx xs -> IsVar x idx (xs ++ ys)
-- What Could Possibly Go Wrong?
-- This relies on the runtime representation of the term being the same
-- after embedding! It is just an identity function at run time, though, and
-- we don't need its definition at compile time, so let's do it...
varExtend p = believe_me p

export
embed : Term vars -> Term (vars ++ more)
embed tm = believe_me tm

public export
ClosedTerm : Type
ClosedTerm = Term []

export
apply : FC -> AppInfo -> Term vars -> List (Term vars) -> Term vars
apply loc p fn [] = fn
apply loc p fn (a :: args) = apply loc p (App loc fn p a) args

export
applyInfo : FC -> Term vars -> List (AppInfo, Term vars) -> Term vars
applyInfo loc fn [] = fn
applyInfo loc fn ((p, a) :: args) = applyInfo loc (App loc fn p a) args

export
getFnArgs : Term vars -> (Term vars, List (AppInfo, Term vars))
getFnArgs tm = getFA [] tm
  where
    getFA : List (AppInfo, Term vars) -> Term vars -> 
            (Term vars, List (AppInfo, Term vars))
    getFA args (App _ f i a) = getFA ((i, a) :: args) f
    getFA args tm = (tm, args)

export
getFn : Term vars -> Term vars
getFn (App _ f _ a) = getFn f
getFn tm = tm

export
getArgs : Term vars -> (List (AppInfo, Term vars))
getArgs = snd . getFnArgs

public export
data Visibility = Private | Export | Public

export
Show Visibility where
  show Private = "private"
  show Export = "export"
  show Public = "public export"

export
Eq Visibility where
  Private == Private = True
  Export == Export = True
  Public == Public = True
  _ == _ = False

export
Ord Visibility where
  compare Private Export = LT
  compare Private Public = LT
  compare Export Public = LT

  compare Private Private = EQ
  compare Export Export = EQ
  compare Public Public = EQ

  compare Export Private = GT
  compare Public Private = GT
  compare Public Export = GT

public export
interface Weaken (tm : List Name -> Type) where
  weaken : tm vars -> tm (n :: vars)
  weakenNs : (ns : List Name) -> tm vars -> tm (ns ++ vars)

  weakenNs [] t = t
  weakenNs (n :: ns) t = weaken (weakenNs ns t)

  weaken = weakenNs [_]

export
insertVar : {outer : _} ->
            (idx : _) -> 
            IsVar name idx (outer ++ inner) ->
            (idx' ** IsVar name idx' (outer ++ n :: inner))
insertVar {outer = []} idx x = (_ ** Later x)
insertVar {outer = (name :: xs)} Z First = (_ ** First)
insertVar {n} {outer = (x :: xs)} (S i) (Later y) 
    = let (_ ** prf) = insertVar {n} i y in
          (_ ** Later prf)

weakenVar : (ns : List Name) -> IsVar name idx inner ->
            (idx' ** IsVar name idx' (ns ++ inner))
weakenVar [] x = (_ ** x)
weakenVar (y :: xs) x 
   = let (_ ** x') = weakenVar xs x in
         (_ ** Later x')

export
insertVarNames : {outer, ns : _} ->
                 (idx : _) -> 
                 IsVar name idx (outer ++ inner) ->
                 (idx' ** IsVar name idx' (outer ++ (ns ++ inner)))
insertVarNames {ns} {outer = []} idx prf = weakenVar ns prf
insertVarNames {outer = (y :: xs)} Z First = (_ ** First)
insertVarNames {ns} {outer = (y :: xs)} (S i) (Later x) 
    = let (_ ** prf) = insertVarNames {ns} i x in
          (_ ** Later prf)

export
thin : {outer, inner : _} ->
       (n : Name) -> Term (outer ++ inner) -> Term (outer ++ n :: inner)
thin n (Local fc r idx prf) 
    = let (idx' ** var') = insertVar {n} idx prf in
          Local fc r idx' var'
thin n (Ref fc nt name) = Ref fc nt name
thin n (Meta fc name idx args) = Meta fc name idx (map (thin n) args)
thin {outer} {inner} n (Bind fc x b scope) 
    = let sc' = thin {outer = x :: outer} {inner} n scope in
          Bind fc x (assert_total (map (thin n) b)) sc'
thin n (App fc fn p arg) = App fc (thin n fn) p (thin n arg)
thin n (As fc nm tm) = As fc (thin n nm) (thin n tm)
thin n (TDelayed fc r ty) = TDelayed fc r (thin n ty)
thin n (TDelay fc r tm) = TDelay fc r (thin n tm)
thin n (TForce fc tm) = TForce fc (thin n tm)
thin n (PrimVal fc c) = PrimVal fc c
thin n (Erased fc) = Erased fc
thin n (TType fc) = TType fc

export
insertNames : {outer, inner : _} ->
              (ns : List Name) -> Term (outer ++ inner) ->
              Term (outer ++ (ns ++ inner))
insertNames ns (Local fc r idx prf) 
    = let (_ ** prf') = insertVarNames {ns} idx prf in
          Local fc r _ prf'
insertNames ns (Ref fc nt name) = Ref fc nt name
insertNames ns (Meta fc name idx args)
    = Meta fc name idx (map (insertNames ns) args)
insertNames {outer} {inner} ns (Bind fc x b scope) 
    = Bind fc x (assert_total (map (insertNames ns) b)) 
           (insertNames {outer = x :: outer} {inner} ns scope)
insertNames ns (App fc fn p arg) 
    = App fc (insertNames ns fn) p (insertNames ns arg)
insertNames ns (As fc as tm) 
    = As fc (insertNames ns as) (insertNames ns tm)
insertNames ns (TDelayed fc r ty) = TDelayed fc r (insertNames ns ty)
insertNames ns (TDelay fc r tm) = TDelay fc r (insertNames ns tm)
insertNames ns (TForce fc tm) = TForce fc (insertNames ns tm)
insertNames ns (PrimVal fc c) = PrimVal fc c
insertNames ns (Erased fc) = Erased fc
insertNames ns (TType fc) = TType fc

thinVar : (n : Name) -> Var (outer ++ inner) -> Var (outer ++ n :: inner)
thinVar n (MkVar prf) 
    = let (_ ** prf') = insertVar {n} _ prf in
          MkVar prf'

insertNamesVar : (ns : List Name) -> Var (outer ++ inner) -> Var (outer ++ (ns ++ inner))
insertNamesVar ns (MkVar prf) 
    = let (_ ** prf') = insertVarNames {ns} _ prf in
          MkVar prf'

export 
Weaken Term where
  weaken tm = thin {outer = []} _ tm
  weakenNs ns tm = insertNames {outer = []} ns tm

public export
data CompatibleVars : List Name -> List Name -> Type where
     CompatPre : CompatibleVars xs xs
     CompatExt : CompatibleVars xs ys -> CompatibleVars (n :: xs) (m :: ys)

export
areVarsCompatible : (xs : List Name) -> (ys : List Name) -> 
                    Maybe (CompatibleVars xs ys)
areVarsCompatible [] [] = pure CompatPre
areVarsCompatible (x :: xs) (y :: ys)
    = do compat <- areVarsCompatible xs ys
         pure (CompatExt compat)
areVarsCompatible _ _ = Nothing

extendCompats : (args : List Name) ->
                CompatibleVars xs ys ->
                CompatibleVars (args ++ xs) (args ++ ys)
extendCompats [] prf = prf
extendCompats (x :: xs) prf = CompatExt (extendCompats xs prf)

renameLocalRef : CompatibleVars xs ys -> IsVar name idx xs -> (name' ** IsVar name' idx ys)
renameLocalRef CompatPre First = (_ ** First)
renameLocalRef (CompatExt x) First = (_ ** First)
renameLocalRef CompatPre (Later p) = (_ ** Later p)
renameLocalRef (CompatExt y) (Later p) 
    = let (_ ** p') = renameLocalRef y p in (_ ** Later p')

renameVarList : CompatibleVars xs ys -> Var xs -> Var ys
renameVarList prf (MkVar p) = MkVar (snd (renameLocalRef prf p))

-- TODO: Surely identity at run time, can we replace with 'believe_me'?
export
renameVars : CompatibleVars xs ys -> Term xs -> Term ys 
renameVars CompatPre tm = tm
renameVars prf (Local fc r idx vprf) 
    = Local fc r idx (snd (renameLocalRef prf vprf))
renameVars prf (Ref fc x name) = Ref fc x name
renameVars prf (Meta fc n i args) 
    = Meta fc n i (map (renameVars prf) args)
renameVars prf (Bind fc x b scope) 
    = Bind fc x (map (renameVars prf) b) (renameVars (CompatExt prf) scope)
renameVars prf (App fc fn p arg) 
    = App fc (renameVars prf fn) p (renameVars prf arg)
renameVars prf (As fc as tm)
    = As fc  (renameVars prf as) (renameVars prf tm)
renameVars prf (TDelayed fc r ty) = TDelayed fc r (renameVars prf ty)
renameVars prf (TDelay fc r tm) = TDelay fc r (renameVars prf tm)
renameVars prf (TForce fc x) = TForce fc (renameVars prf x)
renameVars prf (PrimVal fc c) = PrimVal fc c
renameVars prf (Erased fc) = Erased fc
renameVars prf (TType fc) = TType fc

export
renameTop : (m : Name) -> Term (n :: vars) -> Term (m :: vars)
renameTop m tm = renameVars (CompatExt CompatPre) tm

public export
data SubVars : List Name -> List Name -> Type where
     SubRefl  : SubVars xs xs
     DropCons : SubVars xs ys -> SubVars xs (y :: ys)
     KeepCons : SubVars xs ys -> SubVars (x :: xs) (x :: ys)

export
subElem : IsVar name x xs -> SubVars ys xs -> Maybe (x' ** IsVar name x' ys)
subElem prf SubRefl = Just (_ ** prf)
subElem First (DropCons p) = Nothing
subElem (Later x) (DropCons p) 
    = do (_ ** prf') <- subElem x p
         Just (_ ** prf')
subElem First (KeepCons p) = Just (_ ** First)
subElem (Later x) (KeepCons p) 
    = do (_ ** prf') <- subElem x p
         Just (_ ** Later prf')

export
subExtend : (ns : List Name) -> SubVars xs ys -> SubVars (ns ++ xs) (ns ++ ys)
subExtend [] sub = sub
subExtend (x :: xs) sub = KeepCons (subExtend xs sub)

mutual
  shrinkBinder : Binder (Term vars) -> SubVars newvars vars -> 
                 Maybe (Binder (Term newvars))
  shrinkBinder (Lam c p ty) prf 
      = Just (Lam c p !(shrinkTerm ty prf))
  shrinkBinder (Let c val ty) prf
      = Just (Let c !(shrinkTerm val prf) !(shrinkTerm ty prf))
  shrinkBinder (Pi c p ty) prf
      = Just (Pi c p !(shrinkTerm ty prf))
  shrinkBinder (PVar c ty) prf
      = Just (PVar c !(shrinkTerm ty prf))
  shrinkBinder (PLet c val ty) prf
      = Just (PLet c !(shrinkTerm val prf) !(shrinkTerm ty prf))
  shrinkBinder (PVTy c ty) prf
      = Just (PVTy c !(shrinkTerm ty prf))

  export
  shrinkVar : Var vars -> SubVars newvars vars -> Maybe (Var newvars)
  shrinkVar (MkVar x) prf 
      = case subElem x prf of
             Nothing => Nothing
             Just (_ ** x') => Just (MkVar x')

  export
  shrinkTerm : Term vars -> SubVars newvars vars -> Maybe (Term newvars)
  shrinkTerm (Local fc r idx loc) prf 
     = case subElem loc prf of
            Nothing => Nothing
            Just (_ ** loc') => Just (Local fc r _ loc')
  shrinkTerm (Ref fc x name) prf = Just (Ref fc x name)
  shrinkTerm (Meta fc x y xs) prf 
     = do xs' <- traverse (\x => shrinkTerm x prf) xs
          Just (Meta fc x y xs')
  shrinkTerm (Bind fc x b scope) prf 
     = Just (Bind fc x !(shrinkBinder b prf) !(shrinkTerm scope (KeepCons prf)))
  shrinkTerm (App fc fn p arg) prf 
     = Just (App fc !(shrinkTerm fn prf) p !(shrinkTerm arg prf))
  shrinkTerm (As fc as tm) prf 
     = Just (As fc !(shrinkTerm as prf) !(shrinkTerm tm prf))
  shrinkTerm (TDelayed fc x y) prf 
     = Just (TDelayed fc x !(shrinkTerm y prf))
  shrinkTerm (TDelay fc x y) prf
     = Just (TDelay fc x !(shrinkTerm y prf))
  shrinkTerm (TForce fc x) prf
     = Just (TForce fc !(shrinkTerm x prf))
  shrinkTerm (PrimVal fc c) prf = Just (PrimVal fc c)
  shrinkTerm (Erased fc) prf = Just (Erased fc)
  shrinkTerm (TType fc) prf = Just (TType fc)

public export
data Bounds : List Name -> Type where
     None : Bounds []
     Add : (x : Name) -> Name -> Bounds xs -> Bounds (x :: xs)

addVars : {later, bound : _} ->
          Bounds bound -> IsVar name idx (later ++ vars) ->
          (idx' ** IsVar name idx' (later ++ (bound ++ vars)))
addVars {later = []} {bound} bs p = weakenVar bound p
addVars {later = (x :: xs)} bs First = (_ ** First)
addVars {later = (x :: xs)} bs (Later p) 
  = let (_ ** p') = addVars {later = xs} bs p in
        (_ ** Later p')

-- resolveRef : (done : List Name) -> Bounds bound -> FC -> Name -> 
--              Term (later ++ (done ++ bound ++ vars))
-- resolveRef done None fc n = Ref fc Bound n
-- resolveRef {later} {vars} done (Add {xs} new old bs) fc n 
--     = if n == old
--          then rewrite appendAssociative later done (new :: xs ++ vars) in
--               let (_ ** p) = weakenVar {inner = new :: xs ++ vars}
--                                        (later ++ done) First in
--                     Local fc Nothing _ p
--          else rewrite appendAssociative done [new] (xs ++ vars)
--                 in resolveRef (done ++ [new]) bs fc n

resolveRef : (done : List Name) -> Bounds bound -> FC -> Name -> 
             Maybe (Term (later ++ (done ++ bound ++ vars)))
resolveRef done None fc n = Nothing
resolveRef {later} {vars} done (Add {xs} new old bs) fc n 
    = if n == old
         then rewrite appendAssociative later done (new :: xs ++ vars) in
              let (_ ** p) = weakenVar {inner = new :: xs ++ vars}
                                       (later ++ done) First in
                    Just (Local fc Nothing _ p)
         else rewrite appendAssociative done [new] (xs ++ vars)
                in resolveRef (done ++ [new]) bs fc n

mkLocalVar : {later, bound : _} ->
             Bounds bound -> 
             Var (later ++ vars) -> Var (later ++ (bound ++ vars))
mkLocalVar bs (MkVar p) 
    = let (_ ** p') = addVars bs p in MkVar p'

mkLocals : {later, bound : _} ->
           Bounds bound -> 
           Term (later ++ vars) -> Term (later ++ (bound ++ vars))
mkLocals bs (Local fc r idx p) 
    = let (_ ** p') = addVars bs p in Local fc r _ p'
mkLocals bs (Ref fc Bound name) 
    = maybe (Ref fc Bound name) id (resolveRef [] bs fc name)
mkLocals bs (Ref fc nt name) 
    = Ref fc nt name
mkLocals bs (Meta fc name y xs) 
    = maybe (Meta fc name y (map (mkLocals bs) xs))
            id (resolveRef [] bs fc name)
mkLocals {later} bs (Bind fc x b scope) 
    = Bind fc x (map (mkLocals bs) b) 
           (mkLocals {later = x :: later} bs scope)
mkLocals bs (App fc fn p arg) 
    = App fc (mkLocals bs fn) p (mkLocals bs arg)
mkLocals bs (As fc as tm) 
    = As fc (mkLocals bs as) (mkLocals bs tm)
mkLocals bs (TDelayed fc x y) 
    = TDelayed fc x (mkLocals bs y)
mkLocals bs (TDelay fc x y)
    = TDelay fc x (mkLocals bs y)
mkLocals bs (TForce fc x)
    = TForce fc (mkLocals bs x)
mkLocals bs (PrimVal fc c) = PrimVal fc c
mkLocals bs (Erased fc) = Erased fc
mkLocals bs (TType fc) = TType fc

export
refsToLocals : Bounds bound -> Term vars -> Term (bound ++ vars)
refsToLocals bs y = mkLocals {later = []} bs y

-- Substitute some explicit terms for names in a term, and remove those
-- names from the scope
namespace SubstEnv
  data SubstEnv : List Name -> List Name -> Type where
       Nil : SubstEnv [] vars
       (::) : Term vars -> 
              SubstEnv ds vars -> SubstEnv (d :: ds) vars

  findDrop : {drop, idx : _} ->
             FC -> Maybe RigCount -> IsVar name idx (drop ++ vars) -> 
             SubstEnv drop vars -> Term vars
  findDrop {drop = []} fc r var env = Local fc r _ var
  findDrop {drop = x :: xs} fc r First (tm :: env) = tm
  findDrop {drop = x :: xs} fc r (Later p) (tm :: env) 
      = findDrop fc r p env

  find : {outer, idx : _} ->
         FC -> Maybe RigCount -> IsVar name idx (outer ++ (drop ++ vars)) ->
         SubstEnv drop vars ->
         Term (outer ++ vars)
  find {outer = []} fc r var env = findDrop fc r var env
  find {outer = x :: xs} fc r First env = Local fc r _ First
  find {outer = x :: xs} fc r (Later p) env = weaken (find fc r p env)

  substEnv : {outer : _} ->
             SubstEnv drop vars -> Term (outer ++ (drop ++ vars)) -> 
             Term (outer ++ vars)
  substEnv env (Local fc r _ prf) 
      = find fc r prf env
  substEnv env (Ref fc x name) = Ref fc x name
  substEnv env (Meta fc n i xs) 
      = Meta fc n i (map (substEnv env) xs)
  substEnv {outer} env (Bind fc x b scope) 
      = Bind fc x (map (substEnv env) b) 
                  (substEnv {outer = x :: outer} env scope)
  substEnv env (App fc fn p arg) 
      = App fc (substEnv env fn) p (substEnv env arg)
  substEnv env (As fc as pat) 
      = As fc (substEnv env as) (substEnv env pat)
  substEnv env (TDelayed fc x y) = TDelayed fc x (substEnv env y)
  substEnv env (TDelay fc x y) = TDelay fc x (substEnv env y)
  substEnv env (TForce fc x) = TForce fc (substEnv env x)
  substEnv env (PrimVal fc c) = PrimVal fc c
  substEnv env (Erased fc) = Erased fc
  substEnv env (TType fc) = TType fc

export
subst : Term vars -> Term (x :: vars) -> Term vars
subst val tm = substEnv {outer = []} {drop = [_]} [val] tm

-- Get the metavariable names in a term
export
getMetas : Term vars -> NameMap ()
getMetas tm = getMap empty tm
  where
    getMap : NameMap () -> Term vars -> NameMap ()
    getMap ns (Local fc x idx y) = ns
    getMap ns (Ref fc x name) = ns
    getMap ns (Meta fc n i xs) = insert n () ns
    getMap ns (Bind fc x (Let c val ty) scope) 
        = getMap (getMap (getMap ns val) ty) scope
    getMap ns (Bind fc x b scope) 
        = getMap (getMap ns (binderType b)) scope
    getMap ns (App fc fn p arg) 
        = getMap (getMap ns fn) arg
    getMap ns (As fc as tm) = getMap ns tm
    getMap ns (TDelayed fc x y) = getMap ns y
    getMap ns (TDelay fc x y) = getMap ns y
    getMap ns (TForce fc x) = getMap ns x
    getMap ns (PrimVal fc c) = ns
    getMap ns (Erased fc) = ns
    getMap ns (TType fc) = ns

-- As above, but for references (the only difference is between the 'Ref' and
-- 'Meta' cases, perhaps refector a bit?)
export
getRefs : Term vars -> NameMap ()
getRefs tm = getMap empty tm
  where
    getMap : NameMap () -> Term vars -> NameMap ()
    getMap ns (Local fc x idx y) = ns
    getMap ns (Ref fc x name) = insert name () ns
    getMap ns (Meta fc n i xs) = ns
    getMap ns (Bind fc x (Let c val ty) scope) 
        = getMap (getMap (getMap ns val) ty) scope
    getMap ns (Bind fc x b scope) 
        = getMap (getMap ns (binderType b)) scope
    getMap ns (App fc fn p arg) 
        = getMap (getMap ns fn) arg
    getMap ns (As fc as tm) = getMap ns tm
    getMap ns (TDelayed fc x y) = getMap ns y
    getMap ns (TDelay fc x y) = getMap ns y
    getMap ns (TForce fc x) = getMap ns x
    getMap ns (PrimVal fc c) = ns
    getMap ns (Erased fc) = ns
    getMap ns (TType fc) = ns

export Show (Term vars) where
  show tm = let (fn, args) = getFnArgs tm in showApp fn args
    where
      showApp : Term vars -> List (AppInfo, Term vars) -> String
      showApp (Local {name} _ _ idx _) [] = show name ++ "[" ++ show idx ++ "]"
      showApp (Ref _ _ n) [] = show n
      showApp (Meta _ n _ args) [] = "?" ++ show n ++ "_" ++ show (length args)
      showApp (Bind _ x (Lam c p ty) sc) [] 
          = "\\" ++ showCount c ++ show x ++ " : " ++ show ty ++ 
            " => " ++ show sc
      showApp (Bind _ x (Let c val ty) sc) [] 
          = "let " ++ showCount c ++ show x ++ " : " ++ show ty ++ 
            " = " ++ show val ++ " in " ++ show sc
      showApp (Bind _ x (Pi c Explicit ty) sc) [] 
          = "(" ++ showCount c ++ show x ++ " : " ++ show ty ++ 
            ") -> " ++ show sc
      showApp (Bind _ x (Pi c Implicit ty) sc) [] 
          = "{" ++ showCount c ++ show x ++ " : " ++ show ty ++ 
            "} -> " ++ show sc
      showApp (Bind _ x (Pi c AutoImplicit ty) sc) [] 
          = "{auto" ++ showCount c ++ show x ++ " : " ++ show ty ++ 
            "} -> " ++ show sc
      showApp (Bind _ x (PVar c ty) sc) [] 
          = "pat " ++ showCount c ++ show x ++ " : " ++ show ty ++ 
            " => " ++ show sc
      showApp (Bind _ x (PLet c val ty) sc) [] 
          = "plet " ++ showCount c ++ show x ++ " : " ++ show ty ++ 
            " = " ++ show val ++ " in " ++ show sc
      showApp (Bind _ x (PVTy c ty) sc) [] 
          = "pty " ++ showCount c ++ show x ++ " : " ++ show ty ++ 
            " => " ++ show sc
      showApp (App _ _ _ _) [] = "[can't happen]"
      showApp (TDelayed _ _ tm) [] = "Delayed " ++ show tm
      showApp (TDelay _ _ tm) [] = "Delay " ++ show tm
      showApp (TForce _ tm) [] = "Force " ++ show tm
      showApp (PrimVal _ c) [] = show c
      showApp (Erased _) [] = "[__]"
      showApp (TType _) [] = "Type"
      showApp _ [] = "???"
      showApp f args = "(" ++ assert_total (show f) ++ " " ++
                        assert_total (showSep " " (map (show . snd) args))
                     ++ ")"

