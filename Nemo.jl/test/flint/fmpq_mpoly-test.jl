@testset "fmpq_mpoly.constructors..." begin
   R = FlintQQ

   for num_vars = 1:10
      var_names = ["x$j" for j in 1:num_vars]
      ord = rand_ordering()

      S, varlist = PolynomialRing(R, var_names, ordering = ord)

      SS, varlist = PolynomialRing(R, var_names, ordering = ord)

      @test S === SS

      SSS, varlist = PolynomialRing(R, var_names, ordering = ord, cached = false)
      SSSS, varlist = PolynomialRing(R, var_names, ordering = ord, cached = false)

      @test !(SSS === SSSS)

      @test nvars(S) == num_vars

      @test elem_type(S) == fmpq_mpoly
      @test elem_type(FmpqMPolyRing) == fmpq_mpoly
      @test parent_type(fmpq_mpoly) == FmpqMPolyRing

      @test typeof(S) <: FmpqMPolyRing

      isa(symbols(S), Array{Symbol, 1})

      for j = 1:num_vars
         @test isa(varlist[j], fmpq_mpoly)
         @test isa(gens(S)[j], fmpq_mpoly)
      end

      f =  rand(S, 0:5, 0:100, -100:100)

      @test isa(f, fmpq_mpoly)

      @test isa(S(2), fmpq_mpoly)

      @test isa(S(R(2)), fmpq_mpoly)

      @test isa(S(f), fmpq_mpoly)

      V = [R(rand(-100:100)) for i in 1:5]

      W0 = [ UInt[rand(0:100) for i in 1:num_vars] for j in 1:5]

      @test isa(S(V, W0), fmpq_mpoly)

      for i in 1:num_vars
        f = gen(S, i)
        @test isgen(f, i)
        @test isgen(f)
        @test !isgen(f + 1, i)
        @test !isgen(f + 1)
      end
   end
end

@testset "fmpq_mpoly.manipulation..." begin
   R = FlintQQ

   for num_vars = 1:10
      var_names = ["x$j" for j in 1:num_vars]
      ord = rand_ordering()

      S, varlist = PolynomialRing(R, var_names, ordering = ord)
      g = gens(S)

      @test characteristic(S) == 0

      @test !isgen(S(1))

      for i = 1:num_vars
         @test isgen(varlist[i])
         @test isgen(g[i])
         @test !isgen(g[i] + 1)
      end

      f = rand(S, 0:5, 0:100, -100:100)

      @test f == deepcopy(f)

      if length(f) > 0
         i = rand(1:(length(f)))
         @test isa(coeff(f, i), elem_type(R))
      end

      f = rand(S, 1:5, 0:100, -100:100)

      if length(f) > 0
        @test f == sum((coeff(f, i) * S(fmpq[1], [Nemo.exponent_vector_fmpz(f, i)])  for i in 1:length(f)))
      end

      c = @inferred content(f)
      if length(f) > 0
        @test abs(reduce(gcd, (coeff(f, i) for i in 1:length(f)))) == c
      else
        @test iszero(c)
      end

      c = @inferred denominator(f)
      g = c * f
      @test isone(denominator(g))

      r = S()
      m = S()
      for i = 1:length(f)
         m = monomial!(m, f, i)
         @test m == monomial(f, i)
         @test term(f, i) == coeff(f, i)*monomial(f, i)
         r += coeff(f, i)*monomial(f, i)
      end
      @test f == r

      for i = 1:length(f)
         i1 = rand(1:length(f))
         i2 = rand(1:length(f))
         @test (i1 < i2) == (monomial(f, i1) > monomial(f, i2))
         @test (i1 > i2) == (monomial(f, i1) < monomial(f, i2))
         @test (i1 == i2) == (monomial(f, i1) == monomial(f, i2))
      end

      deg = isdegree(ordering(S))
      rev = isreverse(ordering(S))

      @test ord == ordering(S)

      @test isone(one(S))

      @test iszero(zero(S))

      @test isconstant(S(rand(-100:100)))
      @test isconstant(S(zero(S)))

      g = rand(S, 1:1, 0:100, 1:100)
      h = rand(S, 1:1, 0:100, 1:1)
      h2 = rand(S, 2:2, 1:100, 1:1)

      @test isterm(h)
      @test !isterm(h2 + 1 + gen(S, 1))

      @test isunit(S(1))
      @test !isunit(gen(S, 1))

      @test ismonomial(gen(S, 1)*gen(S, num_vars))
      @test !ismonomial(2*gen(S, 1)*gen(S, num_vars))

      monomialexp = unique([UInt[rand(0:10) for j in 1:num_vars] for k in 1:10])
      coeffs = [rand(FlintQQ, 1:10) for k in 1:length(monomialexp)]
      h = S(coeffs, monomialexp)
      @test length(h) == length(monomialexp)
      for k in 1:length(h)
        @test coeff(h, S(fmpq[1], [monomialexp[k]])) == coeffs[k]
      end

      max_degs = max.(monomialexp...)
      for k = 1:num_vars
         @test (degree(h, k) == max_degs[k]) || (h == 0 && degree(h, k) == -1)
         @test degrees(h)[k] == degree(h, k)
         @test degrees_fmpz(h)[k] == degree(h, k)
         @test degrees_fmpz(h)[k] == degree_fmpz(h, k)
      end

      @test degrees_fit_int(h)

      @test (total_degree(h) == max(sum.(monomialexp)...)) || (h == 0 && total_degree(h) == -1)
      @test (total_degree_fmpz(h) == max(sum.(monomialexp)...)) || (h == 0 && total_degree(h) == -1)
      @test total_degree_fits_int(h)
   end
end

@testset "fmpq_mpoly.multivariate_coeff..." begin
   R = FlintQQ

   for ord in Nemo.flint_orderings
      S, (x, y, z) = PolynomialRing(R, ["x", "y", "z"]; ordering=ord)

      f = -8*x^5*y^3*z^5+9*x^5*y^2*z^3-8*x^4*y^5*z^4-10*x^4*y^3*z^2+8*x^3*y^2*z-10*x*y^3*
z^4-4*x*y-10*x*z^2+8*y^2*z^5-9*y^2*z^3

      @test coeff(f, [1], [1]) == -10*y^3*z^4-4*y-10*z^2
      @test coeff(f, [2, 3], [3, 2]) == -10*x^4
      @test coeff(f, [1, 3], [4, 5]) == 0

      @test coeff(f, [x], [1]) == -10*y^3*z^4-4*y-10*z^2
      @test coeff(f, [y, z], [3, 2]) == -10*x^4
      @test coeff(f, [x, z], [4, 5]) == 0
   end
end

@testset "fmpq_mpoly.unary_ops..." begin
   R = FlintQQ

   for num_vars = 1:10
      var_names = ["x$j" for j in 1:num_vars]
      ord = rand_ordering()

      S, varlist = PolynomialRing(R, var_names, ordering = ord)

      for iter = 1:10
         f = rand(S, 0:5, 0:100, -100:100)

         @test f == -(-f)
      end
   end
end

@testset "fmpq_mpoly.binary_ops..." begin
   R = FlintQQ

   for num_vars = 1:10
      var_names = ["x$j" for j in 1:num_vars]
      ord = rand_ordering()

      S, varlist = PolynomialRing(R, var_names, ordering = ord)

      for iter = 1:10
         f = rand(S, 0:5, 0:100, -100:100)
         g = rand(S, 0:5, 0:100, -100:100)
         h = rand(S, 0:5, 0:100, -100:100)

         @test f + g == g + f
         @test f - g == -(g - f)
         @test f*g == g*f
         @test f*g + f*h == f*(g + h)
         @test f*g - f*h == f*(g - h)
      end
   end
end

@testset "fmpq_mpoly.adhoc_binary..." begin
   R = FlintQQ

   for num_vars = 1:10
      var_names = ["x$j" for j in 1:num_vars]
      ord = rand_ordering()

      S, varlist = PolynomialRing(R, var_names, ordering = ord)

      for iter = 1:100
         f = rand(S, 0:5, 0:100, -100:100)

         d1 = rand(-20:20)
         d2 = rand(-20:20)
         g1 = rand(R, -10:10)
         g2 = rand(R, -10:10)

         @test f*d1 + f*d2 == (d1 + d2)*f
         @test f*BigInt(d1) + f*BigInt(d2) == (BigInt(d1) + BigInt(d2))*f
         @test f*Rational{Int}(d1) + f*Rational{Int}(d2) == (Rational{Int}(d1) + Rational{Int}(d2))*f
         @test f*g1 + f*g2 == (g1 + g2)*f

         @test f + d1 + d2 == d1 + d2 + f
         @test f + BigInt(d1) + BigInt(d2) == BigInt(d1) + BigInt(d2) + f
         @test f + Rational{Int}(d1) + Rational{Int}(d2) == Rational{Int}(d1) + Rational{Int}(d2) + f
         @test f + g1 + g2 == g1 + g2 + f

         @test f - d1 - d2 == -((d1 + d2) - f)
         @test f - BigInt(d1) - BigInt(d2) == -((BigInt(d1) + BigInt(d2)) - f)
         @test f - Rational{Int}(d1) - Rational{Int}(d2) == -((Rational{Int}(d1) + Rational{Int}(d2)) - f)
         @test f - g1 - g2 == -((g1 + g2) - f)

         @test f + d1 - d1 == f
         @test f + BigInt(d1) - BigInt(d1) == f
         @test f + Rational{Int}(d1) - Rational{Int}(d1) == f
         @test f + g1 - g1 == f
      end
   end
end

@testset "fmpq_mpoly.adhoc_comparison..." begin
   R = FlintQQ

   for num_vars = 1:10
      var_names = ["x$j" for j in 1:num_vars]
      ord = rand_ordering()

      S, varlist = PolynomialRing(R, var_names, ordering = ord)

      for iter = 1:100
         d = rand(-100:100)

         @test S(d) == d
         @test d == S(d)
         @test S(fmpz(d)) == fmpz(d)
         @test fmpz(d) == S(fmpz(d))
         @test S(fmpq(d)) == fmpq(d)
         @test fmpq(d) == S(fmpq(d))
         @test S(d) == BigInt(d)
         @test BigInt(d) == S(d)
         @test S(d) == Rational{Int}(d)
         @test Rational{Int}(d) == S(d)
      end
   end
end

@testset "fmpq_mpoly.powering..." begin
   R = FlintQQ

   for num_vars = 1:10
      var_names = ["x$j" for j in 1:num_vars]
      ord = rand_ordering()

      S, varlist = PolynomialRing(R, var_names, ordering = ord)

      for iter = 1:10
         f = rand(S, 0:5, 0:100, -100:100)

         expn = rand(0:10)

         r = S(1)
         for i = 1:expn
            r *= f
         end

         @test (f == 0 && expn == 0 && f^expn == 0) || f^expn == r

         @test_throws DomainError f^-1
         @test_throws DomainError f^fmpz(-1)
      end
   end
end

@testset "fmpq_mpoly.divides..." begin
   R = FlintQQ

   for num_vars = 1:10
      var_names = ["x$j" for j in 1:num_vars]
      ord = rand_ordering()

      S, varlist = PolynomialRing(R, var_names, ordering = ord)

      for iter = 1:10
         f = rand(S, 0:5, 0:100, -100:100)
         g = rand(S, 0:5, 0:100, -100:100)

         p = f*g

         flag, q = divides(p, f)

         if flag
           @test q * f == p
         end

         if !iszero(f)
           q = divexact(p, f)
           @test q == g
         end
      end
   end
end

@testset "fmpq_mpoly.euclidean_division..." begin
   R = FlintQQ

   for num_vars = 1:10
      var_names = ["x$j" for j in 1:num_vars]
      ord = rand_ordering()

      S, varlist = PolynomialRing(R, var_names, ordering = ord)

      for iter = 1:10
         f = S(0)
         while iszero(f)
            f = rand(S, 0:5, 0:100, -100:100)
         end
         g = rand(S, 0:5, 0:100, -100:100)

         p = f*g

         q1, r = divrem(p, f)
         q2 = div(p, f)

         @test q1 == g
         @test q2 == g
         @test f*q1 + r == p

         q3, r3 = divrem(g, f)
         q4 = div(g, f)
         flag, q5 = divides(g, f)

         @test q3*f + r3 == g
         @test q3 == q4
         @test (r3 == 0 && flag == true && q5 == q3) || (r3 != 0 && flag == false)
      end
   end
end

@testset "fmpq_mpoly.ideal_reduction..." begin
   R = FlintQQ

   for num_vars = 1:10
      var_names = ["x$j" for j in 1:num_vars]
      ord = rand_ordering()

      S, varlist = PolynomialRing(R, var_names, ordering = ord)

      for iter = 1:10
         f = S(0)
         while iszero(f)
            f = rand(S, 0:5, 0:100, -100:100)
         end
         g = rand(S, 0:5, 0:100, -100:100)

         p = f*g

         q1, r = divrem(p, [f])

         @test q1[1] == g
         @test r == 0
      end

      for iter = 1:10
         num = rand(1:5)

         V = Vector{elem_type(S)}(undef, num)

         for i = 1:num
            V[i] = S(0)
            while iszero(V[i])
               V[i] = rand(S, 0:5, 0:100, -100:100)
            end
         end
         g = rand(S, 0:5, 0:100, -100:100)

         q, r = divrem(g, V)

         p = r
         for i = 1:num
            p += q[i]*V[i]
         end

         @test p == g
      end
   end
end

@testset "fmpq_mpoly.gcd..." begin
   for num_vars = 1:4
      var_names = ["x$j" for j in 1:num_vars]
      ord = rand_ordering()

      S, varlist = PolynomialRing(FlintQQ, var_names, ordering = ord)

      for iter = 1:10
         f = rand(S, 0:4, 0:5, -10:10)
         g = rand(S, 0:4, 0:5, -10:10)
         h = rand(S, 0:4, 0:5, -10:10)

         g1 = gcd(f, g)
         g2 = gcd(f*h, g*h)

         if !iszero(h) && !iszero(g1)
            b, q = divides(g2, g1 * h)
            @test b
            @test isconstant(q)
         end
      end
   end
end

@testset "fmpq_mpoly.evaluation..." begin
   R = FlintQQ

   for num_vars = 1:10
      var_names = ["x$j" for j in 1:num_vars]
      ord = rand_ordering()

      S, varlist = PolynomialRing(R, var_names, ordering = ord)

      for iter = 1:100
         f = rand(S, 0:5, 0:100, -100:100)
         g = rand(S, 0:5, 0:100, -100:100)

         V1 = [rand(-10:10) for i in 1:num_vars]

         r1 = evaluate(f, V1)
         r2 = evaluate(g, V1)
         r3 = evaluate(f + g, V1)

         @test r3 == r1 + r2
         @test (f + g)(V1...) == f(V1...) + g(V1...)

         V2 = [BigInt(rand(-10:10)) for i in 1:num_vars]

         r1 = evaluate(f, V2)
         r2 = evaluate(g, V2)
         r3 = evaluate(f + g, V2)

         @test r3 == r1 + r2
         @test (f + g)(V2...) == f(V2...) + g(V2...)

         V3 = [R(rand(-10:10)) for i in 1:num_vars]

         r1 = evaluate(f, V3)
         r2 = evaluate(g, V3)
         r3 = evaluate(f + g, V3)

         @test r3 == r1 + r2
         @test (f + g)(V3...) == f(V3...) + g(V3...)
      end
   end

   # Individual tests

   S, (x, y) = PolynomialRing(R, ["x", "y"])
   T = MatrixAlgebra(R, 2)

   f = x^2*y^2+2*x+1

   M1 = T([1 2; 3 4])
   M2 = T([1 1; 2 4])

   @test f(M1, M2) == T([124 219; 271 480])
end

@testset "fmpq_mpoly.valuation..." begin
   R = FlintQQ

   for num_vars = 1:10
      var_names = ["x$j" for j in 1:num_vars]
      ord = rand_ordering()

      S, varlist = PolynomialRing(R, var_names, ordering = ord)

      for iter = 1:100
         f = S()
         g = S()
         while f == 0 || g == 0 || isconstant(g)
            f = rand(S, 0:5, 0:100, -100:100)
            g = rand(S, 0:5, 0:100, -100:100)
         end

         d1 = valuation(f, g)

         expn = rand(1:5)

         d2 = valuation(f*g^expn, g)

         @test d2 == d1 + expn

         d3, q3 = remove(f, g)

         @test d3 == d1
         @test f == q3*g^d3

         d4, q4 = remove(q3*g^expn, g)

         @test d4 == expn
         @test q4 == q3
      end
   end
end

@testset "fmpq_mpoly.derivative_integral..." begin
   R = FlintQQ

   for num_vars = 1:10
      var_names = ["x$j" for j in 1:num_vars]
      ord = rand_ordering()

      S, varlist = PolynomialRing(R, var_names, ordering = ord)

      for j in 1:100
         f = rand(S, 0:5, 0:100, -100:100)

         for i in 1:num_vars
            @test degree((integral(derivative(f, i), i) - f), i) <= 0 # Constant or zero
            @test derivative(integral(f, i), i) == f
         end
      end
   end
end

@testset "fmpq_mpoly.combine_like_terms..." begin
  for num_vars = 1:10
     var_names = ["x$j" for j in 1:num_vars]
     ord = rand_ordering()

     R, vars_R = PolynomialRing(FlintQQ, var_names; ordering=ord)

     for iter in 1:10
        f = R()
        while f == 0
           f = rand(R, 5:10, 1:10, -100:100)
        end

        lenf = length(f)
        f = setcoeff!(f, rand(1:lenf), 0)
        f = combine_like_terms!(f)

        @test length(f) == lenf - 1

        while length(f) < 2
           f = rand(R, 5:10, 1:10, -100:100)
        end

        lenf = length(f)
        nrand = rand(1:lenf - 1)
        v = exponent_vector(f, nrand)
        f = set_exponent_vector!(f, nrand + 1, v)
        terms_cancel = coeff(f, nrand) == -coeff(f, nrand + 1)
        f = combine_like_terms!(f)
        @test length(f) == lenf - 1 - terms_cancel
     end
  end
end

@testset "fmpq_mpoly.exponents..." begin
  for num_vars = 1:10
     var_names = ["x$j" for j in 1:num_vars]
     ord = rand_ordering()

     R, vars_R = PolynomialRing(FlintQQ, var_names; ordering=ord)

     for iter in 1:10
        f = R()
        while f == 0
           f = rand(R, 5:10, 1:10, -100:100)
        end

        nrand = rand(1:length(f))
        v = exponent_vector(f, nrand)
        c = coeff(f, v)

        @test c == coeff(f, nrand)
        for ind = 1:length(v)
           @test v[ind] == exponent(f, nrand, ind)
        end
     end

     for iter in 1:10
        num_vars = nvars(R)

        f = R()
        rand_len = rand(0:10)

        for i = 1:rand_len
           f = set_exponent_vector!(f, i, [rand(0:10) for j in 1:num_vars])
           f = setcoeff!(f, i, rand(ZZ, -10:10))
        end

        f = sort_terms!(f)
        f = combine_like_terms!(f)

        for i = 1:length(f) - 1
           @test exponent_vector(f, i) != exponent_vector(f, i + 1)
           @test coeff(f, i) != 0
        end
        if length(f) > 0
           @test coeff(f, length(f)) != 0
        end
     end

     f = rand(vars_R)^(fmpz(2)^64)
     @test_throws DomainError exponent_vector(f, 1)
  end
end