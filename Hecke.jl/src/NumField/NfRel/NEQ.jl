
function isnorm_fac_elem(K::NfRel{nf_elem}, a::nf_elem)
  Ka, mKa, mkK = absolute_field(K)

  ZKa = lll(maximal_order(Ka))
  C, mC = class_group(ZKa)

  S = collect(keys(factor(mkK(a)*ZKa)))

  c = _get_ClassGrpCtx_of_order(ZKa)
  FB = c.FB.ideals
  i = length(FB)
  q, mq = quo(C, [preimage(mC, I) for I = S])
  while length(q) > 1
    while FB[i] in S || iszero(mq(preimage(mC, FB[i])))
      i -= 1
    end
    push!(S, FB[i])
    q, mmq = quo(q, [mq(preimage(mC, FB[i]))])
    mq = mq*mmq
  end
  
  s = Set([minimum(mkK, I) for I = S])
  #make S relative Galois closed:
  PS = IdealSet(ZKa)
  S = vcat([collect(keys(factor(PS(mkK, p)))) for p = s]...)

  if length(S) == 0
    U, mU = unit_group_fac_elem(ZKa)
  else
    U, mU = sunit_group_fac_elem(collect(S))
  end
  class_group(parent(a))
  if length(s) == 0
    u, mu = unit_group_fac_elem(maximal_order(parent(a)))
  else
    u, mu = sunit_group_fac_elem(collect(s))
  end
  No = hom(U, u, elem_type(u)[preimage(mu, norm(mkK, mU(g))) for g = gens(U)])
  aa = preimage(mu, FacElem(a))
  fl, so = haspreimage(No, aa)
  fl || return fl, FacElem(Dict(K(1)=>1))
  return true, FacElem(Dict([image(mKa, k) => v for (k,v) = mU(so)]))
end

function isnorm(K::NfRel{nf_elem}, a::nf_elem)
  fl, s = isnorm_fac_elem(K, a)
  return fl, evaluate(s)
end

function norm_equation(K::NfRel{nf_elem}, a::nf_elem)
  fl, s = isnorm(K, a)
  fl || error("no solution")
  return s
end
