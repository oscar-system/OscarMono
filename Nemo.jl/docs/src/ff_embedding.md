```@meta
CurrentModule = Nemo
```

# Finite field embeddings

## Introduction

Nemo allows the construction of finite field embeddings making use of the
algorithm of Bosma, Cannon and Steel behind the scenes to ensure compatibility.
Critical routines (e.g. polynomial factorization, matrix computations) are
provided by the C library Flint, whereas high level tasks are written directly in Nemo.

## Embedding functionality

It is possible to explicitly call the embedding `embed` function to create an embedding,
but it is also possible to directly ask for the conversion of a finite field element `x` in
some other finite field `k` via calling `k(x)`. The resulting embedding is of
type `FinFieldMorphism`. It is also possible to
compute the preimage map of an embedding via the `preimage_map` function, applied to an
embedding or directly to the finite fields (this actually first computes the
embedding), or via conversion. An error is thrown if the element you want to
compute the preimage of is not in the image of the embedding.

### Computing an embedding

```@docs
embed(::FqNmodFiniteField, ::FqNmodFiniteField)
```

**Examples**

```julia
julia> k2, x2 = FiniteField(19, 2, "x2")
(Finite field of degree 2 over F_19, x2)

julia> k4, x4 = FiniteField(19, 4, "x4")
(Finite field of degree 4 over F_19, x4)

julia> f = embed(k2, k4)
Morphism from Finite field of degree 2 over F_19
to Finite field of degree 4 over F_19

julia> y = f(x2)
6*x4^3+5*x4^2+9*x4+17

julia> z = k4(x2)
6*x4^3+5*x4^2+9*x4+17
```

### Computing the preimage of an embedding

```@docs
preimage_map(::FqNmodFiniteField, ::FqNmodFiniteField)
preimage_map(::FinFieldMorphism)
```

**Examples**

```julia
julia> k7, x7 = FiniteField(13, 7, "x7")
(Finite field of degree 7 over F_13, x7)

julia> k21, x21 = FiniteField(13, 21, "x21")
(Finite field of degree 21 over F_13, x21)

julia> s = preimage_map(k7, k21)
Preimage of the morphism from Finite field of degree 7 over F_13
to Finite field of degree 21 over F_13

julia> y = k21(x7);

julia> z = s(y)
x7

julia> t = k7(y)
x7
```
