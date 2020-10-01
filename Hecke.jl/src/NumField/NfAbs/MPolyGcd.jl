add_verbose_scope(:MPolyGcd)

module MPolyGcd

using Hecke
import Nemo, Nemo.nmod_mpoly, Nemo.NmodMPolyRing
import AbstractAlgebra

function Hecke.gcd(f::Hecke.Generic.MPoly{nf_elem}, g::Hecke.Generic.MPoly{nf_elem})
  Hecke.check_parent(f, g)
  @vprint :MPolyGcd 1 "multivariate gcd of f with $(length(f)) and g with $(length(g)) terms over $(base_ring(f))\n"

  k = base_ring(f)
  ps = PrimesSet(Hecke.p_start, -1)
  fl, c = Hecke.iscyclotomic_type(k)
  if fl
    @vprint :MPolyGcd 2 "field is cyclotomic with conductor $c\n"
    ps = PrimesSet(Hecke.p_start, -1, c, 1)
  end
  fl, c = Hecke.isquadratic_type(k)
  if fl && abs(c) < typemax(Int)
    @vprint :MPolyGcd 2 "field is quadratic, using conductor $(4*c)\n"
    ps = PrimesSet(Hecke.p_start, -1, Int(4*c), 1)
  end
  return _gcd(f, g, ps)
end

function _gcd(f::Hecke.Generic.MPoly{nf_elem}, g::Hecke.Generic.MPoly{nf_elem}, ps::PrimesSet{Int})
#  @show "gcd start"
  p = iterate(ps)[1]
  K = base_ring(f)
  max_stable = 2
  stable = max_stable

  if iszero(f)
    return g
  end
  if iszero(g)
    return f
  end

  # compute deflation and deflate
  shifta, defla = Generic.deflation(f)
  shiftb, deflb = Generic.deflation(g)
  shiftr = min.(shifta, shiftb)
  deflr = broadcast(gcd, defla, deflb)
  f = deflate(f, shifta, deflr)
  g = deflate(g, shiftb, deflr)

  d = fmpz(1)
  gc = parent(f)()
  gd = parent(f)()
  idl = FlintZZ["x"][1]()
  bm = zero_matrix(FlintZZ, degree(K), degree(K))

  #TODO: scale input to make it integral
  de = lcm(lcm(map(denominator, coefficients(f))), lcm(map(denominator, coefficients(g))))
  f*=de
  g*=de
  E = equation_order(K)
  lI =E*E(lead(f)) + E*E(lead(g))
  gl = Hecke.short_elem(lI)
  gl *= evaluate(derivative(K.pol), gen(K))  # use Kronnecker basis

  fl = true
  while true
    p = iterate(ps, p)[1]
    @vprint :MPolyGcd 2 "Main loop: using $p\n"
    @vtime :MPolyGcd 3 me = Hecke.modular_init(K, p, deg_limit = 1)
    if isempty(me)
      continue
    end
    R = ResidueRing(FlintZZ, p)
    Rt, t = PolynomialRing(R, "t", cached = false)
    @vtime :MPolyGcd 3 fp = Hecke.modular_proj(me, f)
    @vtime :MPolyGcd 3 gp = Hecke.modular_proj(me, g)
    glp = Hecke.modular_proj(gl, me)
    gcd_p = nmod_mpoly[]
    @vtime :MPolyGcd 3 for i=1:length(fp)
      _g = gcd(fp[i], gp[i])
      if length(_g) == 1 && iszero(exponent_vector(_g, 1))
        return inflate(one(parent(f)), shiftr, deflr)
      end
      push!(gcd_p, coeff(glp[i], 0)*_g)
    end
    #gcd_p = [coeff(glp[i], 0)*gcd(fp[i], gp[i]) for i=1:length(fp)]
    @vtime :MPolyGcd 3 tp = Hecke.modular_lift(me, gcd_p)
    if d==1
      d = fmpz(p)
      gc = tp
      idl = lift(parent(idl), me.ce.pr[end])
      bm = lll(basis_matrix(fmpz(p), idl, K))
      R = RecoCtx(bm, K)
      fl, gd = rational_reconstruct(gc, R, true)
      if fl && divides(f, gd)[1] && divides(g, gd)[1]
#          @show "gcd stop", nbits(d), length(gd), gd
#          @time fl, q = divides(f, gd)
#          @time q = div(f, gd)
#          @time q*gd == f
          gd*=inv(gl)
          @assert isone(lead(gd))
          return inflate(gd, shiftr, deflr)
      end
      stable = max_stable
    else
      #TODO: instead of lifting "idl" and doing basis_matrix from
      #      scratch, do the basis_matrix for the new ideal and
      #      use CRT to combine them
      #TODO: explore combining LLL matrices to speed up LLL....
#TODO: deal with bad primes...
      idl, _ = induce_crt(idl, d, lift(parent(idl), me.ce.pr[end]), fmpz(p))
      if (!fl) || any(i->(parent(me.ce.pr[end])(coeff(tp, i) - coeff(gd, i))) % me.ce.pr[end] != 0, 1:length(tp))
        gc, d = induce_crt(gc, d, tp, fmpz(p), true)
        R = RecoCtx(basis_matrix(d, idl, K), K)
        fl, gd = rational_reconstruct(gc, R, true)
        stable = max_stable
      else
        d *= p
        stable -= 1
      end
        if true || stable <= 0 
          if divides(f, gd)[1] && divides(g, gd)[1]
#            @show "gcd stop", nbits(d), length(gd), gd
            gd*=inv(gl)
            @assert isone(lead(gd))
            return inflate(gd, shiftr, deflr)
          else
            stable = max_stable
          end
        end
      #before I forget: gc is "the" gcd modulo <d, idl>
    end
  end
end

function Hecke.induce_crt(a::Hecke.Generic.MPoly{nf_elem}, p::fmpz, b::Hecke.Generic.MPoly{nf_elem}, q::fmpz, signed::Bool = false)
  pi = invmod(p, q)
  mul!(pi, pi, p)
  pq = p*q
  if signed
    pq2 = div(pq, 2)
  else
    pq2 = fmpz(0)
  end
  z = zero(base_ring(a))

  #=
  c = (b-a)*pi+a
  mod!(c, pq)
  return c
  =#

  N = ngens(parent(a))

  ta = terms(a)
  tb = terms(b)
  c = MPolyBuildCtx(parent(a))
  aa, sa = iterate(ta)
  bb, sb = iterate(tb)
#  @assert length(a) == length(b)
#  @assert ==(aa, bb, true) # leading terms must agree or else...
  while !(aa === nothing) && !(bb === nothing)
    if ==(aa.exps, bb.exps) #monomial equality
      push_term!(c, Hecke.induce_inner_crt(coeff(aa, 1), coeff(bb, 1), pi, pq, pq2), exponent_vector(aa, 1))
      aa = iterate(ta, sa)
      bb = iterate(tb, sb)
      aa === nothing && break
      aa, sa = aa
      bb === nothing && break
      bb, sb = bb
    elseif Generic.monomial_isless(aa.exps, 1, bb.exps, 1, N, parent(aa), UInt(0)) #aa < bb
#      error("bad 1")
      push_term!(c, Hecke.induce_inner_crt(z, coeff(bb, 1), pi, pq, pq2), exponent_vector(bb, 1))
      bb, sb = iterate(tb, sb)
      bb === nothing && break
      bb, sb = bb
    else
#      error("bad 2")
      push_term!(c, Hecke.induce_inner_crt(coeff(aa, 1), z, pi, pq, pq2), exponent_vector(aa, 1))
      aa = iterate(ta, sa)
      aa === nothing && break
      aa, sa = aa
    end
  end
  while !(aa === nothing)
#      error("bad 3")
    push_term!(c, Hecke.induce_inner_crt(coeff(aa, 1), z, pi, pq, pq2), exponent_vector(aa, 1))
    aa = iterate(ta, sa)
    if !aa == nothing
      aa, sa = aa
    end
  end
  while !(bb === nothing)
#      error("bad 4")
    push_term!(c, Hecke.induce_inner_crt(z, coeff(bb, 1), pi, pq, pq2), exponent_vector(bb, 1))
    bb = iterate(tb, sb)
    if !(bb === nothing)
      bb, sb = bb
    end
  end
  return finish(c), pq
end   

function Hecke.induce_crt(a::fmpz_mat, p::fmpz, b::fmpz_mat, q::fmpz, signed::Bool = false)
  pi = invmod(p, q)
  mul!(pi, pi, p)
  pq = p*q
  if signed
    pq2 = div(pq, 2)
  else
    pq2 = fmpz(0)
  end

  @assert size(a) == size(b)
  c = similar(a)
  for i=1:nrows(a)
    for j=1:ncols(a)
      c[i,j] = Hecke.inner_crt(a[i,j], b[i,j], pi, pq, pq2)
    end
  end
  return c, pq
end   

function Hecke.modular_proj(me::Hecke.modular_env, f::Generic.MPoly{nf_elem})
  if !isdefined(me, :Kxy)
    me.Kxy = parent(f)
  else
    @assert me.Kxy === parent(f)
  end
  if !isdefined(me, :Kpxy)
    p = characteristic(me.Fpx)
    me.Kpxy, _ = PolynomialRing(base_ring(me.Fpx), ["$(x)_$p" for x = me.Kxy.S])
  end
  fp = [MPolyBuildCtx(me.Kpxy) for x = me.fld]
  s = length(me.fld)
  for i=1:length(f)
    c = coeff(f, i)
    e = exponent_vector(f, i)
    cp = Hecke.modular_proj(c, me)
    R = base_ring(me.Fpx)
    for x = 1:s
      push_term!(fp[x], Hecke.nmod(coeff(cp[x], 0), R), e)
    end
  end
  return map(finish, fp)
end

function Hecke.modular_lift(me::Hecke.modular_env, g::Array{nmod_mpoly, 1})

  #TODO: no dict, but do s.th. similar to induce_crt
  d = Dict{Array{Int, 1}, Array{Tuple{Int, Hecke.nmod}, 1}}()
  for i=1:length(g)
    for (c, e) = Base.Iterators.zip(Generic.MPolyCoeffs(g[i]), Generic.MPolyExponentVectors(g[i]))
      if Base.haskey(d, e)
        push!(d[e], (i, c))
      else
        d[e] = [(i, c)]
      end
    end
  end
  bt = MPolyBuildCtx(me.Kxy)

  for e = keys(d)
    for x=1:length(g)
      me.res[x] = zero!(me.res[x])
    end
    for (i, c) = d[e]
      me.res[i] = parent(me.res[i])(lift(c))
    end
    push_term!(bt, Hecke.modular_lift(me.res, me), e)
  end
  return finish(bt)

  bt = MPolyBuildCtx(me.Kxy)
  #TODO deal with different vectors properly (check induce_crt)
  @assert all(x->collect(exponent_vectors(g[1])) == collect(exponent_vectors(g[x])), 2:length(g))
  for i=1:length(g[1])
    for x=1:length(g)
      me.res[x] = parent(me.res[x])(lift(coeff(g[x], i)))
    end
    push_term!(bt, Hecke.modular_lift(me.res, me), exponent_vector(g[1], i))
  end
  return finish(bt)
end

function Hecke.mod!(f::fmpz_poly, p::fmpz)
  for i=0:degree(f)
    setcoeff!(f, i, mod(coeff(f, i), p))
  end
end

function Hecke.mod(f::fmpz_poly, p::fmpz)
  g = parent(f)()
  for i=0:degree(f)
    setcoeff!(g, i, mod(coeff(f, i), p))
  end
  return g
end

function Hecke.mod_sym!(f::fmpz_poly, p::fmpz)
  for i=0:degree(f)
    setcoeff!(f, i, Hecke.mod_sym(coeff(f, i), p))
  end
end

function basis_matrix(d::fmpz, f::fmpz_poly, k::AnticNumberField)
  #assumes f is idl as above!!!
  #1st need to deconstruct f into the different degrees:
  #CRT of degree a>b and implies lead(b) = 0 mod q, hence gcd's are my friend
  #claim: in this situation, the "obvious" method will produce a Howell form
  de = []
  g = d
  N = zero_matrix(FlintZZ, degree(k), degree(k))
  dN = fmpz(1)
  res = []
  f_orig = f
  d_orig = d
  for i=degree(f):-1:1
    if degree(f)<i
      continue
    end
    r = Base.gcd(coeff(f, i), g)
    #so I have <d/r, f> of degree i and
    #          <f, f mod r> of smaller degree
    n = div(g, r)
    c = invmod(lead(f), n)
    fn = mod(c*f, n)
    @assert ismonic(fn)
    @assert degree(fn) == i
    if degree(f) == degree(k)
      M = MatrixSpace(FlintZZ, degree(k), degree(k))(n)
    else
      M = zero_matrix(FlintZZ, degree(k), degree(k))
      for j=1:i
        M[j,j] = n
      end
      for j=1:degree(fn)+1
        M[i+1, j] = coeff(fn, j-1)
      end
      t = gen(parent(fn))^i-fn
      for j=i+2:degree(k)
        t = t*gen(parent(fn))
        t -= lead(t)*fn
        mod!(t, n)
        M[j,j] = 1
        for k=1:j-1
          M[j, k] = -coeff(t, k-1)
        end
      end
    end
    if dN == 1
      N = M
      dN = n
    else
      N, dN = induce_crt(N, dN, M, n)
    end
    f = mod(f, r)
    g = r
    if isone(g)
      break
    end
  end
  #TODO: implement the Fieker-Hofmann lifting step to avoid the hnf...
  N = Hecke._hnf_modular_eldiv(N, dN, :lowerleft)
  return N
end

mutable struct RecoCtx
  L::fmpz_mat
  LI::fmpz_mat
  d::fmpz
  k::AnticNumberField
  function RecoCtx(A::fmpz_mat, k::AnticNumberField)
    r= new()
    r.k = k
    r.L = lll(A)
    return r
  end
end

function small_coeffs(a::nf_elem, B::fmpz)
  z = fmpz()
  for i=0:degree(parent(a))-1
    Nemo.num_coeff!(z, a, i)
    if cmpabs(z, B) >0
      return false
    end
  end
  return true
end

function rational_reconstruct(a::Generic.MPoly{nf_elem}, R::RecoCtx, integral::Bool = false)
  b = MPolyBuildCtx(parent(a))
  k = base_ring(a)
  d = k(2)
  if integral
    B = fmpz(1)
  else
    B = abs(det(R.L))
    B = fmpz(2)^div(nbits(B), 2*degree(k))
  end
  for i=1:length(a)
    if integral
      fl, c = rational_reconstruct(coeff(a, i), R, integral)
      if !fl
        return fl, a
      end
    else
      #implicitly assumes elements have a common denominator
      fl, c = rational_reconstruct(coeff(a, i)*d, R, true)
      if !fl || !small_coeffs(c, B)
        fl, c, dd = rational_reconstruct(coeff(a, i)*d, R, false, true)
        !fl && return fl, a
        (small_coeffs(c, B) && small_coeffs(d*dd, B)) || return false, a
        d *= dd
      end
      c = c//d
    end
    push_term!(b, c, exponent_vector(a, i))
  end
  return true, finish(b)
end

#TODO: split needs to be a val-arg
function rational_reconstruct(a::nf_elem, R::RecoCtx, integral::Bool = false, split::Bool = false)
  if integral
    if !isdefined(R, :LI)
      R.LI, R.d = pseudo_inv(R.L)
    end
    t = zero_matrix(FlintZZ, 1, degree(R.k))
    z = fmpz()
    for i=1:degree(R.k)
      Nemo.num_coeff!(z, a, i-1)
      t[1, i] = z
    end
    s = t*R.LI
    for i=1:degree(R.k)
      s[1, i] = round(s[1, i]//R.d)
    end
    tt = s*R.L
    b = parent(a)()
    nb = div(3*nbits(R.d), 2)
    for i=1:degree(R.k)
      Hecke._num_setcoeff!(b, i-1, t[1, i]-tt[1, i])
      nb -= nbits(t[1, i] - tt[1, i])
    end
    return nb >= 0, b
  end
  n = degree(parent(a))
  Znn = MatrixSpace(FlintZZ, n, n)
  L = [ Znn(1) representation_matrix_q(a)[1] ; Znn(0) R.L]
  lll!(L)
  K = parent(a)
  d = Nemo.elem_from_mat_row(K, sub(L, 1:1, 1:n), 1, fmpz(1))
  n = Nemo.elem_from_mat_row(K, sub(L, 1:1, n+1:2*n), 1, fmpz(1))
  if split 
    return true, n, d
  else
    return true, n//d
  end
end

function Hecke.toMagma(io::IOStream, R::AbstractAlgebra.MPolyRing; base_name::String = "S", name::String = "R")
  print(io, "$name<")
  S = symbols(R)
  for i = 1:length(S)-1
    print(io, "$(S[i]),")
  end
  print(io, "$(S[end])> := PolynomialRing($base_name, $(length(S)));\n")
end

function Hecke.toMagma(p::String, R::AbstractAlgebra.MPolyRing; base_name::String = "S", name::String = "R", make::String = "w")
  f = open(p, mode)
  Hecke.toMagma(f, R, base_name = base_name, name = name)
  close(f)
end

function Hecke.toMagma(io::IOStream, f::Generic.MPolyElem)
  S = symbols(parent(f))
  for i=1:length(f)
    if i>1
      print(io, "+")
    end
    s = "$(coeff(f, i))"
    s = replace(s, "//" => "/")
    print(io, "($s)")
    e = exponent_vector(f, i)
    if iszero(e)
      continue
    end
    print(io, "*")
    fi = true
    for j=1:length(S)
      if e[j] > 0
        if !fi
          print(io, "*")
        else
          fi = false
        end
        print(io, "$(S[j])^$(e[j])")
      end
    end
  end
end

function Hecke.toMagma(io::IOStream, k::AnticNumberField; name::String = "S", gen_name::String="_a")
  print(io, "$name<$gen_name> := NumberField($(k.pol));\n")
end

function Hecke.toMagma(io::IOStream, s::Symbol, v::Any)
  print(io, "$s := ")
  Hecke.toMagma(io, v)
  print(io, ";\n")
end

#=
import Base.//, Base.==

struct Term{T}
  f::T
  i::Int
  function Term(f::T, i::Int) where {T <: AbstractAlgebra.MPolyElem}
    return new{T}(f, i)
  end
end

function Base.show(io::IO, t::Term)
  print(io, "$(t.i)-th term of $(t.f)")
end

struct Terms{T}
  f::T
  function Terms(f::T) where {T <: AbstractAlgebra.MPolyElem}
    return new{T}(f)
  end
end

function Base.show(io::IO, t::Terms)
  print(io, "Iterator for the terms of $(t.f)")
end

function Base.iterate(T::Terms, st::Int = 0)
  st += 1
  if st > length(T.f)
    return nothing
  end
  return Term(T.f, st), st
end

Base.IteratorEltype(M::Terms) = Base.HasEltype()
Base.eltype(M::Terms{T}) where {T} = Term{T}

Base.IteratorSize(M::Terms) = Base.HasLength()
Base.length(M::Terms) = length(M.f)

function Base.lastindex(a::Terms)
  return length(a.f)
end

function Base.getindex(a::Terms, i::Int)
  return Term(a.f, i)
end

function Base.isless(f::Term, g::Term)
  R = parent(f.f)
  @assert R == parent(g.f)
  return AbstractAlgebra.Generic.monomial_isless(f.f.exps, f.i, g.f.exps, g.i, ngens(R), R, UInt(0))
end

function ==(f::Term, g::Term, monomial_only::Bool = false)
  R = parent(f.f)
  @assert R == parent(g.f)

  return AbstractAlgebra.Generic.monomial_cmp(f.f.exps, f.i, g.f.exps, g.i, ngens(R), R, UInt(0))==0 && (monomial_only || coeff(f.f, f.i) == coeff(g.f, g.i))
end

#=
function push_term!(M::MPolyBuildCtx{<:Generic.MPoly{T}}, t::Term{T}) where {T}
  push_term!(M, coeff(t.f, t.f.i), exponent_vector(t.f, t.f.i))
end
=#

function Hecke.coeff(t::Term)
  return coeff(t.f, t.i)
end

function Hecke.exponent_vector(t::Term)
  return exponent_vector(t.f, t.i)
end

function monomial(t::Term)
  m = parent(r.f)()
  set_exponent_vector!(m, 1, exponent_vector(t))
  setcoeff!(m, one(base_ring(m)))
  return m
end

function lead_term(f::AbstractAlgebra.MPolyElem)
  return Term(f, 1)
end

=#
#=TODO
  fit! for nmod_mpoly
  coeff(fq_nmod) -> UInt (should be nmod)
  nmod_mpoly -> gfp_mpoly? at least in Nemo
  set_coeff should accept UInt

  deal with bad primes (wrong expo vectors)
  reconstruction - and use it in the _hensel stuff elsewhere...
  deal with content

=#


end

