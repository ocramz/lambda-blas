{-# LANGUAGE BangPatterns #-}
-- | This module provides BLAS library functions for vectors of
-- single precision floating point numbers.
module Numerical.BLAS.Single(
   sdot_zip,
   sdot,
    ) where

import Data.Vector.Storable(Vector)
import qualified Data.Vector.Storable as V

{- | O(n) compute the dot product of two vectors using zip and fold
-}
sdot_zip :: Vector Float -- ^ The vector u
    -> Vector Float      -- ^ The vector v
    -> Float             -- ^ The dot product u . v
sdot_zip u v = V.foldl (+) 0 $ V.zipWith (*) u v


{- | O(n) sdot computes the sum of the products of elements drawn from two
   vectors according to the following specification:

@
   sdot n u incx v incy = sum { u[f incx k] * v[f incy k] | k<=[0..n-1] }
   where
   f inc k | inc > 0  = inc * k
           | inc < 0  = (1-n+k)*inc
@

  The elements selected from the two vectors are controlled by the parameters
  n, incx and incy.   The parameter n determines the number of summands, while
  the parameters incx and incy determine the spacing between selected elements
  and the direction which the vectors are traversed.  When both incx and incy
  are unity and n is the length of both vectors then
  sdot corresponds to the dot product of two vectors.
-}
sdot :: Int -- ^ The number of summands
    -> Vector Float -- ^ the vector u
    -> Int          -- ^ the space between elements drawn from u
    -> Vector Float -- ^ the vector v
    -> Int          -- ^ the space between elements drawn from v
    -> Float        -- ^ The sum of the product of the elements.
sdot n sx incx sy incy
   | n < 1                  = error "Encountered zero or negative length vector"
   | incx /=1 || incy /= 1 = V.foldl1' (+) . V.generate n $ productElems (ithIndex incx) (ithIndex incy)
   | n < 5     = V.foldl1' (+) . V.zipWith (*) (V.take m sx) $ (V.take m sy)
   | m == 0    = hylo_loop 0 0
   | otherwise =
        let subtotal = V.foldl1' (+) . V.zipWith (*) (V.take m sx) $ (V.take m sy)
        in  hylo_loop subtotal m
    where
        m :: Int
        m = n `mod` 5
        productElems :: (Int->Int) -> (Int->Int) -> Int -> Float
        {-# INLINE [0] productElems #-}
        productElems indexX indexY i = sx `V.unsafeIndex` (indexX i)
                        * sy `V.unsafeIndex` (indexY i)
        ithIndex :: Int -> Int -> Int
        {-# INLINE [0] ithIndex #-}
        ithIndex !inc
            | inc>0     = \ i -> inc*i
            | otherwise = \ i -> (1+i-n)*inc
        -- hyloL :: ( a -> Maybe (b,a)) -> (c -> b -> c) -> c -> a -> c
        {-# INLINE [1] hylo_loop #-}
        hylo_loop !c !i
           | i>=n = c
           | otherwise =
               let i'  = i+5
                   i1  = i+1
                   i2  = i+2
                   i3  = i+3
                   i4  = i+4
                   c'  = c + (sx `V.unsafeIndex` i)*(sy `V.unsafeIndex` i)
                       + (sx `V.unsafeIndex` i1)*(sy `V.unsafeIndex` i1)
                       + (sx `V.unsafeIndex` i2)*(sy `V.unsafeIndex` i2)
                       + (sx `V.unsafeIndex` i3)*(sy `V.unsafeIndex` i3)
                       + (sx `V.unsafeIndex` i4)*(sy `V.unsafeIndex` i4)
               in  hylo_loop c' i'
