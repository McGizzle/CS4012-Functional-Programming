{-# LANGUAGE FlexibleInstances      #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE MultiParamTypeClasses  #-}

module EitherT where

import           Control.Monad

newtype MyEitherT l m r = MyEitherT
  { runMyEitherT :: m (Either l r)
  }

class MonadTrans t where
  lift :: Monad m => m a -> t m a

class (Show e, Monad m) =>
      (MonadError e m) where
  eFail :: e -> m a
  eHandle :: m a -> (e -> m a) -> m a

instance (Monad m) => Functor (MyEitherT l m) where
  fmap = liftM

instance (Monad m) => Applicative (MyEitherT l m) where
  pure = MyEitherT . pure . Right
  (<*>) = ap

instance (Monad m) => Monad (MyEitherT l m) where
  return = pure
  (MyEitherT a) >>= b =
    MyEitherT $ do
      a' <- a
      case a' of
        Left err  -> pure . Left $ err
        Right res -> runMyEitherT $ b res

instance MonadTrans (MyEitherT l) where
  lift = MyEitherT . fmap Right

instance (Show l, Monad m) => MonadError l (MyEitherT l m) where
  eFail = MyEitherT . return . Left
  eHandle m1 m2 =
    MyEitherT $ do
      m1' <- runMyEitherT m1
      case m1' of
        Right res -> return m1'
        Left err  -> runMyEitherT $ m2 err
