{-# LANGUAGE
    MultiParamTypeClasses,
    RankNTypes,
    ScopedTypeVariables,
    FlexibleInstances,
    FlexibleContexts,
    UndecidableInstances,
    PolyKinds,
    LambdaCase,
    NoMonomorphismRestriction,
    TypeFamilies,
    LiberalTypeSynonyms,
    EmptyCase,
    FunctionalDependencies,
    ExistentialQuantification #-}

module DBI where
import qualified Prelude as P
import Prelude (($), (.), (+), (-), (++), show, (>>=), (*), (/), undefined)
import Util
import Data.Void
import Control.Monad (when)
import qualified Control.Monad.Writer as P
import qualified Data.Functor.Identity as P
import qualified Data.Tuple as P

class DBI repr where
  z :: repr (a, h) a
  s :: repr h b -> repr (a, h) b
  lam :: repr (a, h) b -> repr h (a -> b)
  app :: repr h (a -> b) -> repr h a -> repr h b
  mkProd :: repr h (a -> b -> (a, b))
  zro :: repr h ((a, b) -> a)
  fst :: repr h ((a, b) -> b)
  lit :: P.Double -> repr h P.Double
  litZero :: repr h P.Double
  litZero = lit 0
  litOne :: repr h P.Double
  litOne = lit 1
  doublePlus :: repr h (P.Double -> P.Double -> P.Double)
  doubleMinus :: repr h (P.Double -> P.Double -> P.Double)
  doubleMult :: repr h (P.Double -> P.Double -> P.Double)
  doubleDivide :: repr h (P.Double -> P.Double -> P.Double)
  hoas :: (repr (a, h) a -> repr (a, h) b) -> repr h (a -> b)
  hoas f = lam $ f z
  fix :: repr h ((a -> a) -> a)
  left :: repr h (a -> P.Either a b)
  right :: repr h (b -> P.Either a b)
  sumMatch :: repr h ((a -> c) -> (b -> c) -> P.Either a b -> c)
  unit :: repr h ()
  exfalso :: repr h (Void -> a)
  nothing :: repr h (P.Maybe a)
  just :: repr h (a -> P.Maybe a)
  optionMatch :: repr h (b -> (a -> b) -> P.Maybe a -> b)
  ioRet :: repr h (a -> P.IO a)
  ioBind :: repr h (P.IO a -> (a -> P.IO b) -> P.IO b)
  ioMap :: repr h ((a -> b) -> P.IO a -> P.IO b)
  nil :: repr h [a]
  cons :: repr h (a -> [a] -> [a])
  listMatch :: repr h (b -> (a -> [a] -> b) -> [a] -> b)
  com :: repr h ((b -> c) -> (a -> b) -> (a -> c))
  com = hlam3 $ \f g x -> app f (app g x)
  listAppend :: repr h ([a] -> [a] -> [a])
  listAppend = hlam2 $ \l r -> fix2 (hlam $ \self -> listMatch2 r (hlam2 $ \a as -> cons2 a (app self as))) l
  writer :: repr h ((a, w) -> P.Writer w a)
  runWriter :: repr h (P.Writer w a -> (a, w))
  swap :: repr h ((l, r) -> (r, l))
  swap = hlam $ \p -> mkProd2 (fst1 p) (zro1 p)
  flip :: repr h ((a -> b -> c) -> (b -> a -> c))
  flip = hlam3 $ \f b a -> app2 f a b
  id :: repr h (a -> a)
  id = hlam $ \x -> x
  const :: repr h (a -> b -> a)
  const = hlam2 $ \x _ -> x
  scomb :: repr h ((a -> b -> c) -> (a -> b) -> (a -> c))
  scomb = hlam3 $ \f x arg -> app (app f arg) (app x arg)

const1 = app const
cons2 = app2 cons
listMatch2 = app2 listMatch
fix2 = app2 fix

class Monoid r m where
  zero :: r h m
  plus :: r h (m -> m -> m)

class (DBI r, Monoid r g) => Group r g where
  invert :: r h (g -> g)
  minus :: r h (g -> g -> g)
  invert = minus1 zero
  minus = hlam2 $ \x y -> plus2 x (invert1 y)
  {-# MINIMAL (invert | minus) #-}

minus1 = app minus
divide1 = app divide

recip = divide1 litOne
recip1 = app recip

class Group r v => Vector r v where
  mult :: r h (P.Double -> v -> v)
  divide :: r h (v -> P.Double -> v)
  mult = hlam2 $ \x y -> divide2 y (recip1 x)
  divide = hlam2 $ \x y -> mult2 (recip1 y) x
  {-# MINIMAL (mult | divide) #-}

instance DBI r => Monoid r P.Double where
  zero = litZero
  plus = doublePlus

instance DBI r => Group r P.Double where
  minus = doubleMinus

instance DBI r => Vector r P.Double where
  mult = doubleMult
  divide = doubleDivide

instance (DBI repr, Monoid repr l, Monoid repr r) => Monoid repr (l, r) where
  zero = mkProd2 zero zero
  plus = hlam2 $ \l r -> mkProd2 (plus2 (zro1 l) (zro1 r)) (plus2 (fst1 l) (fst1 r))

instance (DBI repr, Group repr l, Group repr r) => Group repr (l, r) where
  invert = bimap2 invert invert

instance (DBI repr, Vector repr l, Vector repr r) => Vector repr (l, r) where
  mult = hlam $ \x -> bimap2 (mult1 x) (mult1 x)

instance (DBI repr, Monoid repr l, Monoid repr r) => Monoid repr (l -> r) where
  zero = const1 zero
  plus = hlam3 $ \l r x -> plus2 (app l x) (app r x)

instance (DBI repr, Group repr l, Group repr r) => Group repr (l -> r) where
  invert = hlam2 $ \l x -> app l (invert1 x)

instance (DBI repr, Vector repr l, Vector repr r) => Vector repr (l -> r) where
  mult = hlam3 $ \l r x -> app r (mult2 l x)

instance DBI r => Monoid r [a] where
  zero = nil
  plus = listAppend

class Functor r f where
  map :: r h ((a -> b) -> (f a -> f b))

class Functor r a => Applicative r a where
  pure :: r h (x -> a x)
  ap :: r h (a (x -> y) -> a x -> a y)

return = pure

class (DBI r, Applicative r m) => Monad r m where
  bind :: r h (m a -> (a -> m b) -> m b)
  join :: r h (m (m a) -> m a)
  join = hlam $ \m -> bind2 m id
  bind = hlam2 $ \m f -> join1 (app2 map f m)
  {-# MINIMAL (join | bind) #-}

bind2 = app2 bind
map1 = app map
join1 = app join
bimap2 = app2 bimap
flip1 = app flip
flip2 = app2 flip

class DBI r => BiFunctor r p where
  bimap :: r h ((a -> b) -> (c -> d) -> p a c -> p b d)

instance DBI r => BiFunctor r (,) where
  bimap = hlam3 $ \l r p -> mkProd2 (app l (zro1 p)) (app r (fst1 p))

instance DBI r => Functor r (P.Writer w) where
  map = hlam $ \f -> com2 writer (com2 (bimap2 f id) runWriter)

writer1 = app writer
runWriter1 = app runWriter

instance (DBI r, Monoid r w) => Applicative r (P.Writer w) where
  pure = com2 writer (flip2 mkProd zero)
  ap = hlam2 $ \f x -> writer1 (mkProd2 (app (zro1 (runWriter1 f)) (zro1 (runWriter1 x))) (plus2 (fst1 (runWriter1 f)) (fst1 (runWriter1 x))))

instance (DBI r, Monoid r w) => Monad r (P.Writer w) where
  join = hlam $ \x -> writer1 $ mkProd2 (zro1 $ runWriter1 $ zro1 $ runWriter1 x) (plus2 (fst1 $ runWriter1 $ zro1 $ runWriter1 x) (fst1 $ runWriter1 x))

instance DBI r => Functor r P.IO where
  map = ioMap

ioBind2 = app2 ioBind

instance DBI r => Applicative r P.IO where
  pure = ioRet
  ap = hlam2 $ \f x -> ioBind2 f (flip2 ioMap x)

instance DBI r => Monad r P.IO where
  bind = ioBind

app3 f x y z = app (app2 f x y) z

optionMatch2 = app2 optionMatch
optionMatch3 = app3 optionMatch
com2 = app2 com

instance DBI r => Functor r P.Maybe where
  map = hlam $ \func -> optionMatch2 nothing (com2 just func)

instance DBI r => Applicative r P.Maybe where
  pure = just
  ap = optionMatch2 (const1 nothing) map

instance DBI r => Monad r P.Maybe where
  bind = hlam2 $ \x func -> optionMatch3 nothing func x

newtype Eval h x = Eval {runEval :: h -> x}

comb = Eval . P.const

instance DBI Eval where
  z = Eval P.fst
  s (Eval a) = Eval $ a . P.snd
  lam (Eval f) = Eval $ \a h -> f (h, a)
  app (Eval f) (Eval x) = Eval $ \h -> f h $ x h
  zro = comb P.fst
  fst = comb P.snd
  mkProd = comb (,)
  lit = comb
  doublePlus = comb (+)
  doubleMinus = comb (-)
  doubleMult = comb (*)
  doubleDivide = comb (/)
  fix = comb loop
    where loop x = x $ loop x
  left = comb P.Left
  right = comb P.Right
  sumMatch = comb $ \l r -> \case
                             P.Left x -> l x
                             P.Right x -> r x
  unit = comb ()
  exfalso = comb absurd
  nothing = comb P.Nothing
  just = comb P.Just
  ioRet = comb P.return
  ioBind = comb (>>=)
  nil = comb []
  cons = comb (:)
  listMatch = comb $ \l r -> \case
                            [] -> l
                            x:xs -> r x xs
  optionMatch = comb $ \l r -> \case
                              P.Nothing -> l
                              P.Just x -> r x
  ioMap = comb P.fmap
  writer = comb (P.WriterT . P.Identity)
  runWriter = comb P.runWriter

data AST = Leaf P.String | App P.String AST [AST] | Lam P.String [P.String] AST

appAST (Leaf f) x = App f x []
appAST (App f x l) r = App f x (l ++ [r])
appAST lam r = appAST (Leaf $ show lam) r

lamAST str (Lam s l t) = Lam str (s:l) t
lamAST str r = Lam str [] r

instance P.Show AST where
  show (Leaf f) = f
  show (App f x l) = "(" ++ f ++ " " ++ show x ++ P.concatMap ((" " ++) . show) l ++ ")"
  show (Lam s l t) = "(\\" ++ s ++ P.concatMap (" " ++) l ++ " -> " ++ show t ++ ")"
newtype Show h a = Show {runShow :: [P.String] -> P.Int -> AST}
name = Show . P.const . P.const . Leaf

instance DBI Show where
  z = Show $ P.const $ Leaf . show . P.flip (-) 1
  s (Show v) = Show $ \vars -> v vars . P.flip (-) 1
  lam (Show f) = Show $ \vars x -> lamAST (show x) (f vars (x + 1))
  app (Show f) (Show x) = Show $ \vars h -> appAST (f vars h) (x vars h)
  hoas f = Show $ \(v:vars) h ->
    lamAST v (runShow (f $ Show $ P.const $ P.const $ Leaf v) vars h)
  mkProd = name "mkProd"
  zro = name "zro"
  fst = name "fst"
  lit = name . show
  doublePlus = name "plus"
  doubleMinus = name "minus"
  doubleMult = name "mult"
  doubleDivide = name "divide"
  fix = name "fix"
  left = name "left"
  right = name "right"
  sumMatch = name "sumMatch"
  unit = name "unit"
  exfalso = name "exfalso"
  nothing = name "nothing"
  just = name "just"
  ioRet = name "ioRet"
  ioBind = name "ioBind"
  nil = name "nil"
  cons = name "cons"
  listMatch = name "listMatch"
  optionMatch = name "optionMatch"
  ioMap = name "ioMap"
  writer = name "writer"
  runWriter = name "runWriter"

class NT repr l r where
    conv :: repr l t -> repr r t

instance {-# INCOHERENT #-} (DBI repr, NT repr l r) => NT repr l (a, r) where
    conv = s . conv

instance NT repr x x where
    conv = P.id

hlam :: forall repr a b h. DBI repr =>
  ((forall k. NT repr (a, h) k => repr k a) -> (repr (a, h)) b) -> repr h (a -> b)
hlam f = hoas (\x -> f $ conv x)

hlam2 :: forall repr a b c h. DBI repr =>
  ((forall k. NT repr (a, h) k => repr k a) -> (forall k. NT repr (b, (a, h)) k => repr k b) -> (repr (b, (a, h))) c) -> repr h (a -> b -> c)
hlam2 f = hlam $ \x -> hlam $ \y -> f x y

hlam3 f = hlam2 $ \x y -> hlam $ \z -> f x y z

type family Diff v x
type instance Diff v P.Double = (P.Double, v)
type instance Diff v () = ()
type instance Diff v (a, b) = (Diff v a, Diff v b)
type instance Diff v (a -> b) = Diff v a -> Diff v b
type instance Diff v (P.Either a b) = P.Either (Diff v a) (Diff v b)
type instance Diff v Void = Void
type instance Diff v (P.Maybe a) = P.Maybe (Diff v a)
type instance Diff v (P.IO a) = P.IO (Diff v a)
type instance Diff v [a] = [Diff v a]
type instance Diff v (P.Writer w a) = P.Writer (Diff v w) (Diff v a)

newtype WDiff repr v h x = WDiff {runWDiff :: repr (Diff v h) (Diff v x)}

app2 f a = app (app f a)

mkProd1 = app mkProd
mkProd2 = app2 mkProd
plus2 = app2 plus
zro1 = app zro
fst1 = app fst
minus2 = app2 minus
mult1 = app mult
mult2 = app2 mult
divide2 = app2 divide
invert1 = app invert

instance (Vector repr v, DBI repr) => DBI (WDiff repr v) where
  z = WDiff z
  s (WDiff x) = WDiff $ s x
  lam (WDiff f) = WDiff $ lam f
  app (WDiff f) (WDiff x) = WDiff $ app f x
  mkProd = WDiff mkProd
  zro = WDiff zro
  fst = WDiff fst
  lit x = WDiff $ mkProd2 (lit x) zero
  doublePlus = WDiff $ hlam2 $ \l r ->
    mkProd2 (plus2 (zro1 l) (zro1 r)) (plus2 (fst1 l) (fst1 r))
  doubleMinus = WDiff $ hlam2 $ \l r ->
    mkProd2 (minus2 (zro1 l) (zro1 r)) (minus2 (fst1 l) (fst1 r))
  doubleMult = WDiff $ hlam2 $ \l r ->
    mkProd2 (mult2 (zro1 l) (zro1 r))
      (plus2 (mult2 (zro1 l) (fst1 r)) (mult2 (zro1 r) (fst1 l)))
  doubleDivide = WDiff $ hlam2 $ \l r ->
    mkProd2 (divide2 (zro1 l) (zro1 r))
      (divide2 (minus2 (mult2 (zro1 r) (fst1 l)) (mult2 (zro1 l) (fst1 r)))
        (mult2 (zro1 r) (zro1 r)))
  hoas f = WDiff $ hoas (runWDiff . f . WDiff)
  fix = WDiff fix
  left = WDiff left
  right = WDiff right
  sumMatch = WDiff sumMatch
  unit = WDiff unit
  exfalso = WDiff exfalso
  nothing = WDiff nothing
  just = WDiff just
  ioRet = WDiff ioRet
  ioBind = WDiff ioBind
  nil = WDiff nil
  cons = WDiff cons
  listMatch = WDiff listMatch
  optionMatch = WDiff optionMatch
  ioMap = WDiff ioMap
  writer = WDiff writer
  runWriter = WDiff runWriter

noEnv :: repr () x -> repr () x
noEnv = P.id
