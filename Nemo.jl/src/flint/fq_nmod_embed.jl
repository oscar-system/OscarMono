###############################################################################
#
#   fq_nmod_embed.jl : Flint finite fields embeddings
#
###############################################################################

###############################################################################
#
#   Linear factor
#
###############################################################################

function linear_factor(x::fq_nmod_poly)
    y = parent(x)()
    ccall((:fq_nmod_poly_factor_split_single, libflint), Nothing, (Ref{fq_nmod_poly},
          Ref{fq_nmod_poly}, Ref{FqNmodFiniteField}), y, x, base_ring(x))
    return y
end

###############################################################################
#
#   Naive functions
#
###############################################################################

function embed_gens(k::FqNmodFiniteField, K::FqNmodFiniteField)
    a = k()
    b = K()
    p::Int = characteristic(k)
    R = ResidueRing(ZZ, p)
    PR = PolynomialRing(R, "T")[1]
    P = PR()

    ccall((:fq_nmod_embed_gens, libflint), Nothing, (Ref{fq_nmod}, Ref{fq_nmod},
    Ref{nmod_poly}, Ref{FqNmodFiniteField}, Ref{FqNmodFiniteField}), a, b,
    P, k, K)

    return a, b, P
end

function embed_matrices(k::FqNmodFiniteField, K::FqNmodFiniteField)

    m, n = degree(k), degree(K)
    if m == n
        T1, T2 = modulus(k), modulus(K)
        if T1 == T2
            s1 = identity_matrix(base_ring(T1), n)
            s2 = s1
            return s1, s2
        end
    end

    a, b, P = embed_gens(k, K)
    R = base_ring(P)
    S1 = MatrixSpace(R, n, m)
    S2 = MatrixSpace(R, m, n)
    s1 = S1()
    s2 = S2()

    ccall((:fq_nmod_embed_matrices, libflint), Nothing, (Ref{nmod_mat},
    Ref{nmod_mat}, Ref{fq_nmod}, Ref{FqNmodFiniteField}, Ref{fq_nmod},
    Ref{FqNmodFiniteField}, Ref{nmod_poly}), s1, s2, a, k, b, K, P)
    return s1, s2
end

function embed_matrices_pre(a::fq_nmod, b::fq_nmod, P::nmod_poly)
    k = parent(a)
    K = parent(b)
    m, n = degree(k), degree(K)
    R = base_ring(P)
    S1 = MatrixSpace(R, n, m)
    S2 = MatrixSpace(R, m, n)
    s1 = S1()
    s2 = S2()

    ccall((:fq_nmod_embed_matrices, libflint), Nothing, (Ref{nmod_mat},
    Ref{nmod_mat}, Ref{fq_nmod}, Ref{FqNmodFiniteField}, Ref{fq_nmod},
    Ref{FqNmodFiniteField}, Ref{nmod_poly}), s1, s2, a, k, b, K, P)
    return s1, s2
end

function coeff!(x::fq_nmod, j::Int, c::Int)
    ccall((:nmod_poly_set_coeff_ui, libflint), Nothing,
          (Ref{fq_nmod}, Int, UInt), x, j, c)
end

function embed_pre_mat(x::fq_nmod, K::FqNmodFiniteField, M::nmod_mat)

    d = degree(parent(x))
    S = MatrixSpace(base_ring(M), d, 1)
    col = S()

    for j in 0:(d - 1)
        col[j + 1, 1] = coeff(x, j)
    end

    product = M*col
    res = K()

    for j in degree(K):-1:1
        coeff!(res, j - 1, Int(data(product[j, 1])))
    end

    return res
end

################################################################################
#
#   Embedding a polynomial
#
################################################################################

function embed_polynomial(P::fq_nmod_poly, f::FinFieldMorphism)
    S = PolynomialRing(codomain(f), "T")[1]
    return S([f(coeff(P, j)) for j in 0:degree(P)])
end
