>{-# LANGUAGE GADTs, ExistentialQuantification, DataKinds, KindSignatures, TypeFamilies#-}
>module Playground where
>import Control.Concurrent.STM

GADTS 

>data Expr a where
>        Add :: Num a => Expr a -> Expr a -> Expr a
>        Eq  :: Eq a => Expr a -> Expr a -> Expr Bool

We can use GADT's to provide run-time information about whether or not the list is empty
If the list contains 'Z' we know it is empty

>data Z
>data S n
>data List a n where
>        Nil  :: List a Z
>        Cons :: a -> List a b -> List a (S b)

By using the fact that the list must be non-empty we can get the help of the type checker to prevent us writing:
let emptylist = Nil
safeHead emptyList
This will return a type error as 'List a Z' will not match the expected 'List a (S n)'

>safeHead :: List a (S n) -> a 
>safeHead (Cons a _ ) = a

This comes with some caveats ofcourse, we can no longer wirte the following function
f 0 = Nil
f 1 = Cons 1 Nil

'f 0' binds 'List a Z' to the type of 'f'
The compiler will shout at us because expected 'List a Z' will not match the expected 'List a (S Z)'

AVL Tree

>data AVL a n where
>       Empty :: AVL a Z
>       Node  :: AVL a b -> AVL a b -> AVL a (S b)
>       LNode :: AVL a (S b) -> AVL a b -> AVL a (S (S b))
>       RNode :: AVL a b -> AVL a (S b) -> AVL a (S (S b))

Heterogenous List

>data HList0 where
>       HNil0  :: HList0
>       HCons0 :: a -> HList0 -> HList0 

        HCons0 :: Show a -> HList0i -> HList0
        HCons0 :: (a, a -> String) -> HList0

Existential Quantification 

Useless
We dont know anything about the types, so we cannot perform any computations

>data HList = HNil
>             | forall a. HCons a HList 

Useful
Constrain it to the class Showable, which provides useful functions that can used accross all types in the list

>data HList1 = HNil1
>              | forall a. Show a => HCons1 a HList1

>printList1 :: HList1 -> IO ()
>printList1 HNil1 = return ()
>printList1 (HCons1 x xs) = putStrLn (show x) >> printList1 xs

Package our own functions up with the list

>data HList2 = HNil2
>              | forall a. HCons2 (a,a -> String) HList2

>printList2 :: HList2 -> IO ()
>printList2 HNil2 = return ()
>printList (HCons2 (x,s) xs) = putStrLn (s x) >> printList2 xs

Phantom Types

We can teach the compiler the difference in Even and Odd length lists

>newtype Lis a = Lis [Int]
>data Odd = Odd
>data Even = Even
>
>nil :: Lis Odd
>nil = Lis []
>consE :: Int -> Lis Even -> Lis Odd 
>consE x (Lis y) = Lis (x:y) 
>consO :: Int -> Lis Odd -> Lis Even
>consO x (Lis y) = Lis (x:y)

the following will not compile
nil = Lis []
consO 1 $ nil
This will work
:t consO 1 $ consE 2 $ Lis []
consO 1 $ consE 2 $ Lis [] :: Lis Even

:t consE 2 $ consO 1 $ consE $ Lis []

<interactive>:1:21: error:
    • Couldn't match expected type ‘Lis Odd’
                  with actual type ‘Lis Even -> Lis Odd’
    • In the second argument of ‘($)’, namely ‘consE $ Lis []’
      In the second argument of ‘($)’, namely ‘consO 1 $ consE $ Lis []’
      In the expression: consE 2 $ consO 1 $ consE $ Lis []

    • Couldn't match type ‘Odd’ with ‘Even’
      Expected type: Lis Even
        Actual type: Lis Odd
    • In the second argument of ‘($)’, namely ‘consE 2 $ Lis []’
      In the expression: consE 1 $ consE 2 $ Lis []


data Ptr a = MkPtr Addr
Say we had the following functions 
peek :: Ptr a -> IO a
poke :: Ptr a -> a -> IO ()
The compiler will protect us from the following
        do 
          ptr <- allocPtr
          poke ptr (42 :: Int)
          f :: Float <- peek ptr

Type Kinds

Tells us how many paramters a function takes
Int :: *
fmap :: (* -> *) -> * -> *

Data Kinds
:

>data Nat = Zero | Succ Nat

Lets us encode the length of a vector into its type

>data Vec a (l :: Nat) where
>     VNil  :: Vec a Zero
>     VCons :: a -> Vec a n -> Vec a (Succ n) 

for example this wont work
vecL :: Vec Int (Succ (Succ Zero))
vecL = VCons 1 $ VCons 2 $ VCons 3 VNil 

This will

>vecL :: Vec Int (Succ (Succ (Succ Zero)))
>vecL = VCons 1 $ VCons 2 $ VCons 3 VNil

Now in order to write useful functions we need the help of the TypeFamilies extension.
Lets write an append function that actually works.

First we declare `Add` which is a `Type Family` or in other words type-level operation

>type family Add (x :: Nat) (y :: Nat) :: Nat
>type instance Add Zero y = y
>type instance Add (Succ x) y = Succ (Add x y)

We now use this Add to increase the kind of Vec to the size of both the Vectors

>append :: Vec a x -> Vec a y -> Vec a (Add x y)
>append (VCons x xs) ys = VCons x $ append xs ys
>append VNil ys = ys

:t append vecL vecL
append vecL vecL :: Vec Int ('Succ ('Succ ('Succ ('Succ 'Zero))))

>type Account = TVar Int 
>transfer :: Account -> Account -> Int -> IO ()
>transfer acc1 acc2 amount = atomically $ do
>   bal1 <- readTVar acc1
>   always (return $ bal1 > amount) 
>   bal2 <- readTVar acc2
>   writeTVar acc1 (bal1 - amount)
>   writeTVar acc2 (bal2 + amount)


>testFunc = putStr "hello" >> getLine >>= putStr . reverse




