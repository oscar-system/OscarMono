# In general we want to test over:
#    1) Exact rings, e.g. Z
#    2) Exact fields, e.g. Q or GFp
#    3) Inexact rings, e.g. polynomials over Julia RealField, or power series
#       over Z
#    4) Inexact fields, e.g. Julia RealField
#    5) A field of char p > 0, e.g. GF(p)
#    6) A ring of char p > 0, e.g. Z/pZ
#    7) Commutative ring, not an integral domain, e.g. Z/nZ or Z[x]/(f)
#       with reducible f
# In some cases, we may also wish to test over:
#    8) Polynomial rings, e.g. to test interpolation strategies
#    9) Fraction fields, such as Q, e.g. to test fraction free algorithms,
#       quasidivision, etc.
#   10) Generic towers, e.g. to test ad hoc functions
# Note: only useful to distinguish rings and fields for 1/2, 3/4, 5/6 if the
# algos differ, and 7 can often stand in for 5/6 if the algorithm supports it.

@testset "Generic.Poly.constructors..." begin
   R, x = ZZ["x"]
   S1 = R["y"]
   S2 = ZZ["x"]["y"]

   for (S, y) in (S1, S2)
      @test elem_type(S) == Generic.Poly{elem_type(R)}
      @test elem_type(Generic.PolyRing{elem_type(R)}) == Generic.Poly{elem_type(R)}
      @test parent_type(Generic.Poly{elem_type(R)}) == Generic.PolyRing{elem_type(R)}

      @test typeof(R) <: AbstractAlgebra.Ring
      @test typeof(S) <: Generic.PolyRing

      @test isa(y, PolyElem)
   end

   R, x = PolynomialRing(ZZ, "x")
   S, y = PolynomialRing(R, "y")

   @test typeof(S) <: Generic.PolyRing

   @test isa(y, PolyElem)

   T, z = PolynomialRing(S, "z")

   @test typeof(T) <: Generic.PolyRing

   @test isa(z, PolyElem)

   f = x^2 + y^3 + z + 1

   @test isa(f, PolyElem)

   g = S(2)

   @test isa(g, PolyElem)

   h = S(x^2 + 2x + 1)

   @test isa(h, PolyElem)

   j = T(x + 2)

   @test isa(j, PolyElem)

   k = S([x, x + 2, x^2 + 3x + 1])

   @test isa(k, PolyElem)

   l = S(k)

   @test isa(l, PolyElem)

   m = S([1, 2, 3])

   @test isa(m, PolyElem)

   n = S([ZZ(1), ZZ(2), ZZ(3)])

   @test isa(n, PolyElem)

   @test x in [x, y]
   @test x in [y, x]
   @test !(x in [y])

   @test x in keys(Dict(x => 1))
   @test !(y in keys(Dict(x => 1)))
end

@testset "Generic.Poly.rand..." begin
   R, x = PolynomialRing(ZZ, "x")
   f = rand(R, 0:10, -10:10)
   @test f isa Generic.Poly
   f = rand(rng, R, 0:10, -10:10)
   @test f isa Generic.Poly
end

@testset "Generic.Poly.manipulation..." begin
   R, x = PolynomialRing(ZZ, "x")
   S, y = PolynomialRing(R, "y")

   @test iszero(zero(S))

   @test isone(one(S))

   @test isgen(gen(S))

   @test isunit(one(S))

   f = 2x*y + x^2 + 1

   @test lead(f) == 2x

   @test trail(2x*y + x^2) == x^2

   @test degree(f) == 1

   h = x*y^2 + (x + 1)*y + 3

   @test coeff(h, 2) == x

   @test length(h) == 3

   @test canonical_unit(-x*y + x + 1) == -1

   @test deepcopy(h) == h

   @test isterm_recursive(2*x*y^2)
   @test !isterm_recursive(2*(x + 1)*y^2)

   @test !isterm(2*x*y^2 + 1)
   @test isterm(2*x*y^2)

   @test !ismonomial_recursive(2*x*y^2)

   @test ismonomial(y^2)

   @test !ismonomial_recursive(2*x*y^2 + y + 1)
   @test !ismonomial(2*y^2)

   @test characteristic(R) == 0
end

@testset "Generic.Poly.binary_ops..." begin
   #  Exact ring
   R, x = PolynomialRing(ZZ, "x")
   for iter = 1:100
      f = rand(R, 0:10, -10:10)
      g = rand(R, 0:10, -10:10)
      h = rand(R, 0:10, -10:10)
      @test f + g == g + f
      @test f + (g + h) == (f + g) + h
      @test f*g == g*f
      @test f*(g + h) == f*g + f*h
      @test (f - h) + (g + h) == f + g
      @test (f + g)*(f - g) == f*f - g*g
      @test f - g == -(g - f)
   end

   # Fake finite field of char 7, degree 2
   S, y = PolynomialRing(GF(7), "y")
   F = ResidueField(S, y^2 + 6y + 3)
   a = F(y)
   R, x = PolynomialRing(F, "x")
   for iter = 1:100
      f = rand(R, 0:10, 0:1)
      g = rand(R, 0:10, 0:1)
      h = rand(R, 0:10, 0:1)
      @test f + g == g + f
      @test f + (g + h) == (f + g) + h
      @test f*g == g*f
      @test f*(g + h) == f*g + f*h
      @test (f - h) + (g + h) == f + g
      @test (f + g)*(f - g) == f*f - g*g
      @test f - g == -(g - f)
   end

   #  Inexact field
   R, x = PolynomialRing(RealField, "x")
   for iter = 1:100
      f = rand(R, 0:10, -1:1)
      g = rand(R, 0:10, -1:1)
      h = rand(R, 0:10, -1:1)
      @test isapprox(f + (g + h), (f + g) + h)
      @test isapprox(f*g, g*f)
      @test isapprox(f*(g + h), f*g + f*h)
      @test isapprox((f - h) + (g + h), f + g)
      @test isapprox((f + g)*(f - g), f*f - g*g)
      @test isapprox(f - g, -(g - f))
   end

   # Non-integral domain
   T = ResidueRing(ZZ, 6)
   R, x = T["x"]
   for iter = 1:100
      f = rand(R, 0:10, 0:5)
      g = rand(R, 0:10, 0:5)
      h = rand(R, 0:10, 0:5)
      @test f + (g + h) == (f + g) + h
      @test f*g == g*f
      @test f*(g + h) == f*g + f*h
      @test (f - h) + (g + h) == f + g
      @test (f + g)*(f - g) == f*f - g*g
      @test f - g == -(g - f)
   end
end

@testset "Generic.Poly.adhoc_binary..." begin
   # Exact ring
   R, x = ZZ["x"]
   for iter = 1:500
      f = rand(R, 0:10, -10:10)
      c1 = rand(ZZ, -10:10)
      c2 = rand(ZZ, -10:10)
      d1 = rand(zz, -10:10)
      d2 = rand(zz, -10:10)

      @test c1*f - c2*f == (c1 - c2)*f
      @test c1*f + c2*f == (c1 + c2)*f
      @test d1*f - d2*f == (d1 - d2)*f
      @test d1*f + d2*f == (d1 + d2)*f

      @test f*c1 - f*c2 == f*(c1 - c2)
      @test f*c1 + f*c2 == f*(c1 + c2)
      @test f*d1 - f*d2 == f*(d1 - d2)
      @test f*d1 + f*d2 == f*(d1 + d2)
   end

   # Fake finite field of char 7, degree 2
   S, y = PolynomialRing(GF(7), "y")
   F = ResidueField(S, y^2 + 6y + 3)
   a = F(y)
   R, x = PolynomialRing(F, "x")
   for iter = 1:500
      f = rand(R, 0:10, 0:1)
      c1 = rand(ZZ, -10:10)
      c2 = rand(ZZ, -10:10)
      d1 = rand(zz, -10:10)
      d2 = rand(zz, -10:10)

      @test c1*f - c2*f == (c1 - c2)*f
      @test c1*f + c2*f == (c1 + c2)*f
      @test d1*f - d2*f == (d1 - d2)*f
      @test d1*f + d2*f == (d1 + d2)*f

      @test f*c1 - f*c2 == f*(c1 - c2)
      @test f*c1 + f*c2 == f*(c1 + c2)
      @test f*d1 - f*d2 == f*(d1 - d2)
      @test f*d1 + f*d2 == f*(d1 + d2)
   end

   # Inexact field
   R, x = RealField["x"]
   for iter = 1:500
      f = rand(R, 0:10, -1:1)
      c1 = rand(ZZ, -10:10)
      c2 = rand(ZZ, -10:10)
      d1 = rand(RealField, -1:1)
      d2 = rand(RealField, -1:1)

      @test isapprox(c1*f - c2*f, (c1 - c2)*f)
      @test isapprox(c1*f + c2*f, (c1 + c2)*f)
      @test isapprox(d1*f - d2*f, (d1 - d2)*f)
      @test isapprox(d1*f + d2*f, (d1 + d2)*f)

      @test isapprox(f*c1 - f*c2, f*(c1 - c2))
      @test isapprox(f*c1 + f*c2, f*(c1 + c2))
      @test isapprox(f*d1 - f*d2, f*(d1 - d2))
      @test isapprox(f*d1 + f*d2, f*(d1 + d2))
   end

   # Non-integral domain
   R = ResidueRing(ZZ, 6)
   S, x = R["x"]
   for iter = 1:500
      f = rand(S, 0:10, 0:5)
      c1 = rand(ZZ, -10:10)
      c2 = rand(ZZ, -10:10)
      d1 = rand(zz, -10:10)
      d2 = rand(zz, -10:10)
      a1 = rand(R, 0:5)
      a2 = rand(R, 0:5)

      @test a1*f - a2*f == (a1 - a2)*f
      @test a1*f + a2*f == (a1 + a2)*f
      @test c1*f - c2*f == (c1 - c2)*f
      @test c1*f + c2*f == (c1 + c2)*f
      @test d1*f - d2*f == (d1 - d2)*f
      @test d1*f + d2*f == (d1 + d2)*f

      @test f*a1 - f*a2 == f*(a1 - a2)
      @test f*a1 + f*a2 == f*(a1 + a2)
      @test f*c1 - f*c2 == f*(c1 - c2)
      @test f*c1 + f*c2 == f*(c1 + c2)
      @test f*d1 - f*d2 == f*(d1 - d2)
      @test f*d1 + f*d2 == f*(d1 + d2)
   end

   # Generic tower
   R, x = ZZ["x"]
   S, y = R["y"]
   for iter = 1:100
      f = rand(S, 0:10, 0:5, -10:10)
      c1 = rand(ZZ, -10:10)
      c2 = rand(ZZ, -10:10)
      d1 = rand(R, 0:5, -10:10)
      d2 = rand(R, 0:5, -10:10)

      @test c1*f - c2*f == (c1 - c2)*f
      @test c1*f + c2*f == (c1 + c2)*f
      @test d1*f - d2*f == (d1 - d2)*f
      @test d1*f + d2*f == (d1 + d2)*f

      @test f*c1 - f*c2 == f*(c1 - c2)
      @test f*c1 + f*c2 == f*(c1 + c2)
      @test f*d1 - f*d2 == f*(d1 - d2)
      @test f*d1 + f*d2 == f*(d1 + d2)
   end
end

@testset "Generic.Poly.comparison..." begin
   # Exact ring
   R, x = ZZ["x"]
   for iter = 1:500
      f = rand(R, 0:10, -10:10)
      g = deepcopy(f)
      h = R()
      while iszero(h)
         h = rand(R, 0:10, -10:10)
      end

      @test f == g
      @test isequal(f, g)
      @test f != g + h
   end

   # Fake finite field of char 7, degree 2
   S, y = PolynomialRing(GF(7), "y")
   F = ResidueField(S, y^2 + 6y + 3)
   a = F(y)
   R, x = PolynomialRing(F, "x")
   for iter = 1:500
      f = rand(R, 0:10, 0:1)
      g = deepcopy(f)
      h = R()
      while iszero(h)
         h = rand(R, 0:10, 0:1)
      end

      @test f == g
      @test isequal(f, g)
      @test f != g + h
   end

   # Inexact field
   R, x = RealField["x"]
   for iter = 1:500
      f = rand(R, 0:10, -1:1)
      g = deepcopy(f)
      h = R()
      while iszero(h)
         h = rand(R, 0:10, -1:1)
      end

      @test f == g
      @test isequal(f, g)
      @test f != g + h
   end

   # Non-integral domain
   R = ResidueRing(ZZ, 6)
   S, x = R["x"]
   for iter = 1:500
      f = rand(S, 0:10, 0:5)
      g = deepcopy(f)
      h = R()
      while iszero(h)
         h = rand(S, 0:10, 0:5)
      end

      @test f == g
      @test isequal(f, g)
      @test f != g + h
   end
end

@testset "Generic.Poly.adhoc_comparison..." begin
   # Exact ring
   R, x = ZZ["x"]
   for iter = 1:500
      f = R()
      while iszero(f)
         f = rand(R, 0:10, -10:10)
      end
      c1 = rand(ZZ, -10:10)
      d1 = rand(zz, -10:10)

      @test R(c1) == c1
      @test c1 == R(c1)
      @test R(d1) == d1
      @test d1 == R(d1)

      @test R(c1) != c1 + f
      @test c1 != R(c1) + f
      @test R(d1) != d1 + f
      @test d1 != R(d1) + f
   end

   # Fake finite field of char 7, degree 2
   S, y = PolynomialRing(GF(7), "y")
   F = ResidueField(S, y^2 + 6y + 3)
   a = F(y)
   R, x = PolynomialRing(F, "x")
   for iter = 1:500
      f = R()
      while iszero(f)
         f = rand(R, 0:10, 0:1)
      end
      c1 = rand(ZZ, -10:10)
      d1 = rand(zz, -10:10)

      @test R(c1) == c1
      @test c1 == R(c1)
      @test R(d1) == d1
      @test d1 == R(d1)

      @test R(c1) != c1 + f
      @test c1 != R(c1) + f
      @test R(d1) != d1 + f
      @test d1 != R(d1) + f
   end

   # Inexact field
   R, x = RealField["x"]
   for iter = 1:500
      f = R()
      while iszero(f)
         f = rand(R, 0:10, -1:1)
      end
      c1 = rand(ZZ, -10:10)
      d1 = rand(RealField, -1:1)

      @test R(c1) == c1
      @test c1 == R(c1)
      @test R(d1) == d1
      @test d1 == R(d1)

      @test R(c1) != c1 + f
      @test c1 != R(c1) + f
      @test R(d1) != d1 + f
      @test d1 != R(d1) + f
   end

   # Non-integral domain
   R = ResidueRing(ZZ, 6)
   S, x = R["x"]
   for iter = 1:500
      f = S()
      while iszero(f)
         f = rand(S, 0:10, 0:5)
      end
      c1 = rand(ZZ, -10:10)
      d1 = rand(zz, -10:10)
      a1 = rand(R, 0:5)

      @test S(a1) == a1
      @test a1 == S(a1)
      @test S(c1) == c1
      @test c1 == S(c1)
      @test S(d1) == d1
      @test d1 == S(d1)

      @test S(a1) != a1 + f
      @test a1 != S(a1) + f
      @test S(c1) != c1 + f
      @test c1 != S(c1) + f
      @test S(d1) != d1 + f
      @test d1 != S(d1) + f
   end

   # Generic tower
   R, x = ZZ["x"]
   S, y = R["y"]
   for iter = 1:100
      f = S()
      while iszero(f)
         f = rand(S, 0:10, 0:5, -10:10)
      end
      c1 = rand(ZZ, -10:10)
      d1 = rand(R, 0:5, -10:10)

      @test S(c1) == c1
      @test c1 == S(c1)
      @test S(d1) == d1
      @test d1 == S(d1)

      @test S(c1) != c1 + f
      @test c1 != S(c1) + f
      @test S(d1) != d1 + f
      @test d1 != S(d1) + f
   end
end

@testset "Generic.Poly.unary_ops..." begin
   #  Exact ring
   R, x = PolynomialRing(ZZ, "x")
   for iter = 1:300
      f = rand(R, 0:10, -10:10)

      @test -(-f) == f
      @test iszero(f + (-f))
   end

   # Fake finite field of char 7, degree 2
   S, y = PolynomialRing(GF(7), "y")
   F = ResidueField(S, y^2 + 6y + 3)
   a = F(y)
   R, x = PolynomialRing(F, "x")
   for iter = 1:300
      f = rand(R, 0:10, 0:1)

      @test -(-f) == f
      @test iszero(f + (-f))
   end

   #  Inexact field
   R, x = PolynomialRing(RealField, "x")
   for iter = 1:300
      f = rand(R, 0:10, -1:1)

      @test -(-f) == f
      @test iszero(f + (-f))
   end

   # Non-integral domain
   T = ResidueRing(ZZ, 6)
   R, x = T["x"]
   for iter = 1:300
      f = rand(R, 0:10, 0:5)

      @test -(-f) == f
      @test iszero(f + (-f))
   end
end

@testset "Generic.Poly.truncation..." begin
   #  Exact ring
   R, x = PolynomialRing(ZZ, "x")
   for iter = 1:300
      f = rand(R, 0:10, -10:10)
      g = rand(R, 0:10, -10:10)
      n = rand(0:20)

      @test truncate(f*g, n) == mullow(f, g, n)
   end

   # Fake finite field of char 7, degree 2
   S, y = PolynomialRing(GF(7), "y")
   F = ResidueField(S, y^2 + 6y + 3)
   a = F(y)
   R, x = PolynomialRing(F, "x")
   for iter = 1:300
      f = rand(R, 0:10, 0:1)
      g = rand(R, 0:10, 0:1)
      n = rand(0:20)

      @test truncate(f*g, n) == mullow(f, g, n)
   end

   #  Inexact field
   R, x = PolynomialRing(RealField, "x")
   for iter = 1:300
      f = rand(R, 0:10, -1:1)
      g = rand(R, 0:10, -1:1)
      n = rand(0:20)

      @test isapprox(truncate(f*g, n), mullow(f, g, n))
   end

   # Non-integral domain
   T = ResidueRing(ZZ, 6)
   R, x = T["x"]
   for iter = 1:300
      f = rand(R, 0:10, 0:5)
      g = rand(R, 0:10, 0:5)
      n = rand(0:20)

      r = mullow(f, g, n)

      @test truncate(f*g, n) == r
      @test r == 0 || !iszero(lead(r))
   end
end

@testset "Generic.Poly.reverse..." begin
   #  Exact ring
   R, x = ZZ["x"]
   for iter = 1:300
      f = rand(R, 0:10, -10:10)
      len = rand(length(f):12)
      frev = reverse(f, len)

      shift = 0
      for i = 1:len
         if coeff(f, i - 1) != 0
            break
         end
         shift += 1
      end

      @test length(frev) == len - shift
      @test f == reverse(frev, len)
   end

   f = rand(R, 0:10, -10:10)
   @test_throws DomainError reverse(f, -1)
   @test_throws DomainError reverse(f, -rand(2:100))

   # Fake finite field of char 7, degree 2
   S, y = PolynomialRing(GF(7), "y")
   F = ResidueField(S, y^2 + 6y + 3)
   a = F(y)
   R, x = PolynomialRing(F, "x")
   for iter = 1:300
      f = rand(R, 0:10, 0:1)
      len = rand(length(f):12)
      frev = reverse(f, len)

      shift = 0
      for i = 1:len
         if coeff(f, i - 1) != 0
            break
         end
         shift += 1
      end

      @test length(frev) == len - shift
      @test f == reverse(frev, len)
   end

   f = rand(R, 0:10, 0:1)
   @test_throws DomainError reverse(f, -1)
   @test_throws DomainError reverse(f, -rand(2:100))

   #  Inexact field
   R, x = PolynomialRing(RealField, "x")
   for iter = 1:300
      f = rand(R, 0:10, -1:1)
      len = rand(length(f):12)
      frev = reverse(f, len)

      shift = 0
      for i = 1:len
         if coeff(f, i - 1) != 0
            break
         end
         shift += 1
      end

      @test length(frev) == len - shift
      @test f == reverse(frev, len)
   end

   f = rand(R, 0:10, -1:1)
   @test_throws DomainError reverse(f, -1)
   @test_throws DomainError reverse(f, -rand(2:100))

   #  Non-integral domain
   T = ResidueRing(ZZ, 6)
   R, x = T["x"]
   for iter = 1:300
      f = rand(R, 0:10, 0:5)
      len = rand(length(f):12)
      frev = reverse(f, len)

      shift = 0
      for i = 1:len
         if coeff(f, i - 1) != 0
            break
         end
         shift += 1
      end

      @test length(frev) == len - shift
      @test f == reverse(frev, len)
   end

   f = rand(R, 0:10, 0:5)
   @test_throws DomainError reverse(f, -1)
   @test_throws DomainError reverse(f, -rand(2:100))
end

@testset "Generic.Poly.shift..." begin
   # Exact ring
   R, x = ZZ["x"]
   for iter = 1:300
      f = rand(R, 0:10, -10:10)
      s = rand(0:10)
      g = s == 0 ? R() : rand(R, 0:s - 1, -10:10)

      @test shift_right(shift_left(f, s) + g, s) == f
      @test shift_left(f, s) == x^s*f
      @test length(shift_right(f, s)) == max(0, length(f) - s)
   end

   f = rand(R, 0:10, -10:10)
   @test_throws DomainError shift_right(f, -1)
   @test_throws DomainError shift_right(f, -rand(2:100))
   @test_throws DomainError shift_left(f, -1)
   @test_throws DomainError shift_left(f, -rand(2:100))

   # Fake finite field of char 7, degree 2
   S, y = PolynomialRing(GF(7), "y")
   F = ResidueField(S, y^2 + 6y + 3)
   a = F(y)
   R, x = PolynomialRing(F, "x")
   for iter = 1:300
      f = rand(R, 0:10, 0:1)
      s = rand(0:10)
      g = s == 0 ? R() : rand(R, 0:s - 1, 0:1)

      @test shift_right(shift_left(f, s) + g, s) == f
      @test shift_left(f, s) == x^s*f
      @test length(shift_right(f, s)) == max(0, length(f) - s)
   end

   f = rand(R, 0:10, 0:1)
   @test_throws DomainError shift_right(f, -1)
   @test_throws DomainError shift_right(f, -rand(2:100))
   @test_throws DomainError shift_left(f, -1)
   @test_throws DomainError shift_left(f, -rand(2:100))

   # Inexact field
   R, x = PolynomialRing(RealField, "x")
   for iter = 1:300
      f = rand(R, 0:10, -1:1)
      s = rand(0:10)
      g = s == 0 ? R() : rand(R, 0:s - 1, -1:1)

      @test shift_right(shift_left(f, s) + g, s) == f
      @test shift_left(f, s) == x^s*f
      @test length(shift_right(f, s)) == max(0, length(f) - s)
   end

   f = rand(R, 0:10, -1:1)
   @test_throws DomainError shift_right(f, -1)
   @test_throws DomainError shift_right(f, -rand(2:100))
   @test_throws DomainError shift_left(f, -1)
   @test_throws DomainError shift_left(f, -rand(2:100))

   # Non-integral domain
   T = ResidueRing(ZZ, 6)
   R, x = T["x"]
   for iter = 1:300
      f = rand(R, 0:10, 0:5)
      s = rand(0:10)
      g = s == 0 ? R() : rand(R, 0:s - 1, 0:5)

      @test shift_right(shift_left(f, s) + g, s) == f
      @test shift_left(f, s) == x^s*f
      @test length(shift_right(f, s)) == max(0, length(f) - s)
   end

   f = rand(R, 0:10, 0:5)
   @test_throws DomainError shift_right(f, -1)
   @test_throws DomainError shift_right(f, -rand(2:100))
   @test_throws DomainError shift_left(f, -1)
   @test_throws DomainError shift_left(f, -rand(2:100))
end

@testset "Generic.Poly.powering..." begin
   # Exact ring
   R, x = PolynomialRing(ZZ, "x")

   for iter = 1:10
      f = rand(R, 0:10, -10:10)
      r2 = R(1)

      for expn = 0:10
         r1 = f^expn

         @test (f == 0 && expn == 0 && r1 == 0) || r1 == r2

         r2 *= f
      end
   end

   f = rand(R, 0:10, -10:10)
   @test_throws DomainError f^-1
   @test_throws DomainError f^-rand(2:100)
   @test_throws DomainError pow_multinomial(f, -1)
   @test_throws DomainError pow_multinomial(f, -rand(2:100))

   # Fake finite field of char 7, degree 2
   S, y = PolynomialRing(GF(7), "y")
   F = ResidueField(S, y^2 + 6y + 3)
   a = F(y)
   R, x = PolynomialRing(F, "x")

   for iter = 1:10
      f = rand(R, 0:10, 0:1)
      r2 = R(1)

      for expn = 0:10
         r1 = f^expn

         @test (f == 0 && expn == 0 && r1 == 0) || r1 == r2

         r2 *= f
      end
   end

   f = rand(R, 0:10, 0:1)
   @test_throws DomainError f^-1
   @test_throws DomainError f^-rand(2:100)
   @test_throws DomainError pow_multinomial(f, -1)
   @test_throws DomainError pow_multinomial(f, -rand(2:100))

   # Inexact field
   R, x = PolynomialRing(RealField, "x")

   for iter = 1:10
      f = rand(R, 0:10, -1:1)
      r2 = R(1)

      for expn = 0:4 # cannot set high power here
         r1 = f^expn

         @test (f == 0 && expn == 0 && r1 == 0) || isapprox(r1, r2)

         r2 *= f
      end
   end

   f = rand(R, 0:10, -1:1)
   @test_throws DomainError f^-1
   @test_throws DomainError f^-rand(2:100)
   @test_throws DomainError pow_multinomial(f, -1)
   @test_throws DomainError pow_multinomial(f, -rand(2:100))

   # Non-integral domain
   for iter = 1:10
      n = rand(2:26)

      Zn = ResidueRing(ZZ, n)
      R, x = PolynomialRing(Zn, "x")

      f = rand(R, 0:10, 0:n - 1)
      r2 = R(1)

      for expn = 0:10
         r1 = f^expn

         @test (f == 0 && expn == 0 && r1 == 0) || r1 == r2

         r2 *= f
      end
   end

   f = rand(R, 0:10, 0:rand(1:25))
   @test_throws DomainError f^-1
   @test_throws DomainError f^-rand(2:100)
   @test_throws DomainError pow_multinomial(f, -1)
   @test_throws DomainError pow_multinomial(f, -rand(2:100))
end

if false
   @testset "Generic.Poly.modular_arithmetic..." begin
      # Exact ring
      R = ResidueRing(ZZ, 23)
      S, x = PolynomialRing(R, "x")

      for iter = 1:100
         f = rand(S, 0:5, 0:22)
         g = rand(S, 0:5, 0:22)
         h = rand(S, 0:5, 0:22)
         k = S()
         while k == 0
            k = rand(S, 0:5, 0:22)
         end

         @test mulmod(mulmod(f, g, k), h, k) == mulmod(f, mulmod(g, h, k), k)
      end

      for iter = 1:100
         f = S()
         g = S()
         while f == 0 || g == 0 || gcd(f, g) != 1
            f = rand(S, 0:5, 0:22)
            g = rand(S, 0:5, 0:22)
         end

         @test mulmod(invmod(f, g), f, g) == mod(S(1), g)
      end

      for iter = 1:100
         f = rand(S, 0:5, 0:22)
         g = S()
         while g == 0
            g = rand(S, 0:5, 0:22)
         end
         p = mod(S(1), g)

         for expn = 0:5
            r = powmod(f, expn, g)

            @test (f == 0 && expn == 0 && r == 0) || r == p

            p = mulmod(p, f, g)
         end
      end

      # Fake finite field of char 7, degree 2
      R, y = PolynomialRing(GF(7), "y")
      F = ResidueField(R, y^2 + 6y + 3)
      a = F(y)
      S, x = PolynomialRing(F, "x")

      for iter = 1:100
         f = rand(S, 0:5, 0:1)
         g = rand(S, 0:5, 0:1)
         h = rand(S, 0:5, 0:1)
         k = S()
         while k == 0
            k = rand(S, 0:5, 0:1)
         end

         @test mulmod(mulmod(f, g, k), h, k) == mulmod(f, mulmod(g, h, k), k)
      end

      for iter = 1:100
         f = S()
         g = S()
         while f == 0 || g == 0 || gcd(f, g) != 1
            f = rand(S, 0:5, 0:1)
            g = rand(S, 0:5, 0:1)
         end

         @test mulmod(invmod(f, g), f, g) == mod(S(1), g)
      end

      for iter = 1:100
         f = rand(S, 0:5, 0:1)
         g = S()
         while g == 0
            g = rand(S, 0:5, 0:1)
         end
         p = mod(S(1), g)

         for expn = 0:5
            r = powmod(f, expn, g)

            @test (f == 0 && expn == 0 && r == 0) || r == p

            p = mulmod(p, f, g)
         end
      end

      # Inexact field
      S, x = PolynomialRing(RealField, "x")

      for iter = 1:100
         f = rand(S, 0:5, -1:1)
         g = rand(S, 0:5, -1:1)
         h = rand(S, 0:5, -1:1)
         k = R()
         while k == 0
            k = rand(S, 0:5, -1:1)
         end

         @test isapprox(mulmod(mulmod(f, g, k), h, k), mulmod(f, mulmod(g, h, k), k))
      end

      for iter = 1:100
         f = S()
         g = S()
         while f == 0 || g == 0 || gcd(f, g) != 1
            f = rand(S, 0:5, -1:1)
            g = rand(S, 0:5, -1:1)
         end

         @test isapprox(mulmod(invmod(f, g), f, g), mod(S(1), g))
      end

      for iter = 1:100
         f = rand(S, 0:5, -1:1)
         g = S()
         while g == 0
            g = rand(S, 0:5, -1:1)
         end
         p = mod(S(1), g)

         for expn = 0:5
            r = powmod(f, expn, g)

            @test (f == 0 && expn == 0 && r == 0) || isapprox(r, p)

            p = mulmod(p, f, g)
         end
      end

      # Exact field
      R, x = PolynomialRing(QQ, "y")

      for iter = 1:10
         f = rand(R, 0:5, -10:10)
         g = rand(R, 0:5, -10:10)
         h = rand(R, 0:5, -10:10)
         k = R()
         while k == 0
            k = rand(R, 0:5, -10:10)
         end

         @test mulmod(mulmod(f, g, k), h, k) == mulmod(f, mulmod(g, h, k), k)
      end

      for iter = 1:10
         f = R()
         g = R()
         while f == 0 || g == 0 || gcd(f, g) != 1
            f = rand(R, 0:5, -10:10)
            g = rand(R, 0:5, -10:10)
         end

         @test mulmod(invmod(f, g), f, g) == mod(R(1), g)
      end

      for iter = 1:10
         f = rand(R, 0:5, -10:10)
         g = R()
         while g == 0
            g = rand(R, 0:5, -10:10)
         end
         p = mod(R(1), g)

         for expn = 0:5
            r = powmod(f, expn, g)

            @test (f == 0 && expn == 0 && r == 0) || r == p

            p = mulmod(p, f, g)
         end
      end
   end
end

@testset "Generic.Poly.exact_division..." begin
   # Exact ring
   R, x = PolynomialRing(ZZ, "x")

   for iter = 1:100
      f = rand(R, 0:10, -100:100)
      g = R()
      while g == 0
         g = rand(R, 0:10, -100:100)
      end

      @test divexact(f*g, g) == f
   end

   @test_throws ArgumentError divexact(x^2, x - 1)

   # Fake finite field of char 7, degree 2
   S, y = PolynomialRing(GF(7), "y")
   F = ResidueField(S, y^2 + 6y + 3)
   a = F(y)
   R, x = PolynomialRing(F, "x")

   for iter = 1:100
      f = rand(R, 0:10, 0:1)
      g = R()
      while g == 0
         g = rand(R, 0:10, 0:1)
      end

      @test divexact(f*g, g) == f
   end

   # Inexact field
   R, x = PolynomialRing(RealField, "x")

   for iter = 1:100
      f = rand(R, 0:10, -1:1)
      g = R()
      while g == 0
         g = rand(R, 0:10, -1:1)
      end

      @test isapprox(divexact(f*g, g), f)
   end

   # Characteristic p ring
   n = 23
   Zn = ResidueRing(ZZ, n)
   R, x = PolynomialRing(Zn, "x")

   for iter = 1:100
      f = rand(R, 0:10, 0:n - 1)
      g = R()
      while g == 0
         g = rand(R, 0:10, 0:n - 1)
      end

      @test divexact(f*g, g) == f
   end
end

@testset "Generic.Poly.adhoc_exact_division..." begin
   # Exact ring
   R, x = PolynomialRing(ZZ, "x")

   for iter = 1:100
      f = rand(R, 0:10, -100:100)
      g = ZZ()
      while g == 0
         g = rand(ZZ, -10:10)
      end

      @test divexact(f*g, g) == f

      h = 0
      while h == 0
         h = rand(-10:10)
      end

      @test divexact(f*h, h) == f
   end

   # Fake finite field of char 7, degree 2
   S, y = PolynomialRing(GF(7), "y")
   F = ResidueField(S, y^2 + 6y + 3)
   a = F(y)
   R, x = PolynomialRing(F, "x")

   for iter = 1:100
      f = rand(R, 0:10, 0:1)
      g = ZZ()
      while g == 0
         g = rand(ZZ, 1:6)
      end

      @test divexact(f*g, g) == f

      h = 0
      while h == 0
         h = rand(1:6)
      end

      @test divexact(f*h, h) == f
   end

   # Inexact field
   R, x = PolynomialRing(RealField, "x")

   for iter = 1:100
      f = rand(R, 0:10, -1:1)
      g = ZZ()
      while g == 0
         g = rand(RealField, -1:1)
      end

      @test isapprox(divexact(f*g, g), f)

      h = 0
      while h == 0
         h = rand(-10:10)
      end

      @test isapprox(divexact(f*h, h), f)
   end

   # Characteristic p ring
   n = 23
   Zn = ResidueRing(ZZ, n)
   R, x = PolynomialRing(Zn, "x")

   for iter = 1:100
      f = rand(R, 0:10, 0:22)
      g = rand(Zn, 1:22)

      @test divexact(f*g, g) == f

      h = 0
      while (h % n) == 0
         h = rand(-100:100)
      end

      @test divexact(f*h, h) == f
   end

   # Generic tower
   R, x = PolynomialRing(ZZ, "x")
   S, y = PolynomialRing(R, "y")

   for iter = 1:100
      f = rand(S, 0:10, 0:10, -100:100)
      g = R()
      while g == 0
         g = rand(R, 0:10, -100:100)
      end

      @test divexact(f*g, g) == f

      h = ZZ()
      while h == 0
         h = rand(ZZ, -10:10)
      end

      @test divexact(f*h, h) == f
   end
end

@testset "Generic.Poly.euclidean_division..." begin
   # Exact ring
   R = ResidueRing(ZZ, 23)
   S, x = PolynomialRing(R, "x")

   for iter = 1:100
      f = rand(S, 0:5, 0:22)
      g = rand(S, 0:5, 0:22)
      h = S()
      while h == 0
         h = rand(S, 0:5, 0:22)
      end

      @test mod(f + g, h) == mod(f, h) + mod(g, h)
   end

   for iter = 1:10
      f = rand(S, 0:5, 0:22)
      g = S()
      while g == 0
         g = rand(S, 0:5, 0:22)
      end

      q, r = divrem(f, g)
      @test q*g + r == f

      @test mod(f, g) == r
   end

   # Fake finite field of char 7, degree 2
   R, y = PolynomialRing(GF(7), "y")
   F = ResidueField(R, y^2 + 6y + 3)
   a = F(y)
   S, x = PolynomialRing(F, "x")

   for iter = 1:100
      f = rand(S, 0:5, 0:1)
      g = rand(S, 0:5, 0:1)
      h = S()
      while h == 0
         h = rand(S, 0:5, 0:1)
      end

      @test mod(f + g, h) == mod(f, h) + mod(g, h)
   end

   for iter = 1:10
      f = rand(S, 0:5, 0:1)
      g = S()
      while g == 0
         g = rand(S, 0:5, 0:1)
      end

      q, r = divrem(f, g)
      @test q*g + r == f

      @test mod(f, g) == r
   end

   # Inexact field
   R, x = PolynomialRing(RealField, "x")

   for iter = 1:100
      f = rand(R, 0:5, -1:1)
      g = rand(R, 0:5, -1:1)
      h = R()
      while h == 0
         h = rand(R, 0:5, -1:1)
      end

      @test isapprox(mod(f + g, h), mod(f, h) + mod(g, h))
   end

   for iter = 1:10
      f = rand(R, 0:5, -1:1)
      g = R()
      while g == 0
         g = rand(R, 0:5, -1:1)
      end

      q, r = divrem(f, g)
      @test isapprox(q*g + r, f)

      @test isapprox(mod(f, g), r)
   end

   # Exact field
   R, x = PolynomialRing(QQ, "x")

   for iter = 1:100
      f = rand(R, 0:5, -10:10)
      g = rand(R, 0:5, -10:10)
      h = R()
      while h == 0
         h = rand(R, 0:5, -10:10)
      end

      @test mod(f + g, h) == mod(f, h) + mod(g, h)
   end

   for iter = 1:10
      f = rand(R, 0:5, -10:10)
      g = R()
      while g == 0
         g = rand(R, 0:5, -10:10)
      end

      q, r = divrem(f, g)
      @test q*g + r == f

      @test mod(f, g) == r
   end
end

@testset "Generic.Poly.pseudodivision..." begin
   # Exact ring
   R, x = PolynomialRing(ZZ, "x")

   for iter = 1:100
      f = rand(R, 0:5, -10:10)
      g = R()
      while g == 0
         g = rand(R, 0:5, -10:10)
      end

      q, r = pseudodivrem(f, g)

      if length(f) < length(g)
         @test f == r && q == 0
      else
         @test q*g + r == f*lead(g)^(length(f) - length(g) + 1)
      end

      @test pseudorem(f, g) == r
   end

   # Characteristic p ring
   Zn = ResidueRing(ZZ, 23)
   R, x = PolynomialRing(Zn, "x")

   for iter = 1:100
      f = rand(R, 0:5, 0:22)
      g = R()
      while g == 0
         g = rand(R, 0:5, 0:22)
      end

      q, r = pseudodivrem(f, g)

      if length(f) < length(g)
         @test f == r && q == 0
      else
         @test q*g + r == f*lead(g)^(length(f) - length(g) + 1)
      end

      @test pseudorem(f, g) == r
   end
end

@testset "Generic.Poly.content_primpart_gcd..." begin
   # Exact ring
   R, x = PolynomialRing(ZZ, "x")

   for iter = 1:100
      f = rand(R, 0:10, -10:10)

      g = R()
      while g == 0
         g = rand(ZZ, -10:10)
      end

      @test content(f*g) == divexact(g, canonical_unit(g))*content(f)

      @test primpart(f*g) == canonical_unit(g)*primpart(f)
   end

   for iter = 1:20
      f = rand(R, 0:10, -10:10)
      g = rand(R, 0:10, -10:10)
      h = R()
      while h == 0
         h = rand(R, 0:10, -10:10)
      end

      @test gcd(f*h, g*h) == divexact(h, canonical_unit(lead(h)))*gcd(f, g)

      @test lcm(f, h) == divexact(f*h, gcd(f, h))
   end

   # Exact field
   R, x = PolynomialRing(QQ, "x")

   for iter = 1:100
      f = rand(R, 0:5, -10:10)

      g = QQ()
      while g == 0
         g = rand(QQ, -10:10)
      end

      @test content(f*g) == content(f)*gcd(g, QQ()) # must normalise g correctly

      @test primpart(f*g) == primpart(f)*divexact(g, gcd(g, QQ()))
   end

   for iter = 1:20
      f = rand(R, 0:5, -10:10)
      g = rand(R, 0:5, -10:10)
      h = R()
      while h == 0
         h = rand(R, 0:5, -10:10)
      end

      @test gcd(f*h, g*h) == inv(lead(h))*h*gcd(f, g)
   end

   for iter = 1:10
      f = R()
      g = R()
      while f == 0 || g == 0 || gcd(f, g) != 1
         f = rand(R, 0:5, -10:10)
         g = rand(R, 0:5, -10:10)
      end

      d, inv = gcdinv(f, g)

      @test d == gcd(f, g)

      @test mod(f*inv, g) == mod(R(1), g)
   end

   # Characteristic p ring
   R = ResidueRing(ZZ, 23)
   S, x = PolynomialRing(R, "x")

   for iter = 1:100
      f = rand(S, 0:10, 0:22)
      g = rand(R, 1:22)

      @test content(f*g) == divexact(g, canonical_unit(g))*content(f)

      @test primpart(f*g) == canonical_unit(g)*primpart(f)
   end

   for iter = 1:100
      f = S()
      g = S()
      while f == 0 || g == 0 || gcd(f, g) != 1
         f = rand(S, 0:5, 0:22)
         g = rand(S, 0:5, 0:22)
      end

      d, inv = gcdinv(f, g)

      @test d == gcd(f, g)

      @test mod(f*inv, g) == mod(S(1), g)
   end

   # Characteristic p field
   R = GF(23)
   S, x = PolynomialRing(R, "x")

   for iter = 1:100
      f = rand(S, 0:10)
      g = R()
      while g == 0
         g = rand(R)
      end

      @test content(f*g) == divexact(g, canonical_unit(g))*content(f)

      @test primpart(f*g) == canonical_unit(g)*primpart(f)
   end

   for iter = 1:100
      f = S()
      g = S()
      while f == 0 || g == 0 || gcd(f, g) != 1
         f = rand(S, 0:5)
         g = rand(S, 0:5)
      end

      d, inv = gcdinv(f, g)

      @test d == gcd(f, g)

      @test mod(f*inv, g) == mod(S(1), g)
   end
end

@testset "Generic.Poly.evaluation..." begin
   # Exact ring
   R, x = PolynomialRing(ZZ, "x")

   for iter in 1:10
      f = rand(R, 0:4, -10:10)
      g = rand(R, 0:4, -10:10)

      d = rand(ZZ, -10:10)

      @test evaluate(g, evaluate(f, d)) == evaluate(subst(g, f), d)
   end

   for iter in 1:10
      f = rand(R, 0:4, -10:10)
      g = rand(R, 0:4, -10:10)

      d = rand(-10:10)

      @test evaluate(g, evaluate(f, d)) == evaluate(subst(g, f), d)
   end

   # Inexact field
   R, x = PolynomialRing(RealField, "x")

   for iter in 1:10
      f = rand(R, 0:4, 0:1)
      g = rand(R, 0:4, 0:1)

      d = rand(RealField, 0:1)

      @test isapprox(evaluate(g, evaluate(f, d)), evaluate(subst(g, f), d))
   end

   for iter in 1:10
      f = rand(R, 0:4, 0:1)
      g = rand(R, 0:4, 0:1)

      d = rand(-10:10)

      @test isapprox(evaluate(g, evaluate(f, d)), evaluate(subst(g, f), d))
   end

   # Non-integral domain
   Zn = ResidueRing(ZZ, 23)
   R, x = PolynomialRing(Zn, "x")

   for iter in 1:10
      f = rand(R, 0:4, 0:22)
      g = rand(R, 0:4, 0:22)

      d = rand(Zn, 0:22)

      @test evaluate(g, evaluate(f, d)) == evaluate(subst(g, f), d)
   end

   for iter in 1:10
      f = rand(R, 0:4, 0:22)
      g = rand(R, 0:4, 0:22)

      d = rand(-100:100)

      @test evaluate(g, evaluate(f, d)) == evaluate(subst(g, f), d)
   end
end

@testset "Generic.Poly.composition..." begin
   # Exact ring
   R, x = PolynomialRing(ZZ, "x")

   for iter in 1:10
      f = rand(R, 0:5, -10:10)
      g = rand(R, 0:5, -10:10)
      h = rand(R, 0:5, -10:10)

      @test compose(f, compose(g, h)) == compose(compose(f, g), h)
   end

   # Inexact field
   R, x = PolynomialRing(RealField, "x")

   for iter in 1:10
      f = rand(R, 0:5, 0:1)
      g = rand(R, 0:5, 0:1)
      h = rand(R, 0:5, 0:1)

      @test isapprox(compose(f, compose(g, h)), compose(compose(f, g), h))
   end

   # Non-integral domain
   Zn = ResidueRing(ZZ, 6)
   R, x = PolynomialRing(Zn, "x")

   for iter in 1:10
      f = rand(R, 0:5, 0:5)
      g = rand(R, 0:5, 0:5)
      h = rand(R, 0:5, 0:5)

      @test compose(f, compose(g, h)) == compose(compose(f, g), h)
   end
end

@testset "Generic.Poly.derivative..." begin
   # Exact ring
   R, x = PolynomialRing(ZZ, "x")

   for iter in 1:10
      f = rand(R, 0:4, -100:100)
      g = rand(R, 0:4, -100:100)

      @test derivative(f + g) == derivative(g) + derivative(f)

      @test derivative(g*f) == derivative(g)*f + derivative(f)*g
   end

   # Inexact field
   R, x = PolynomialRing(RealField, "x")

   for iter in 1:10
      f = rand(R, 0:4, 0:1)
      g = rand(R, 0:4, 0:1)

      @test isapprox(derivative(f + g), derivative(g) + derivative(f))

      @test isapprox(derivative(g*f), derivative(g)*f + derivative(f)*g)
   end

   # Non-integral domain
   Zn = ResidueRing(ZZ, 6)
   R, x = PolynomialRing(Zn, "x")

   for iter in 1:10
      f = rand(R, 0:4, 0:5)
      g = rand(R, 0:4, 0:5)

      @test derivative(f + g) == derivative(g) + derivative(f)

      @test derivative(g*f) == derivative(g)*f + derivative(f)*g
   end
end

@testset "Generic.Poly.integral..." begin
   # Exact field
   R, x = PolynomialRing(QQ, "x")

   for iter in 1:10
      f = rand(R, 0:10, -100:100)

      @test derivative(integral(f)) == f

      g = rand(R, 0:2, -100:100)

      @test integral(f + g) == integral(g) + integral(f)
      @test integral(f)*integral(g) == integral(integral(f)*g + integral(g)*f)
   end

   # Characteristic p ring
   Zn = ResidueRing(ZZ, 23)
   R, x = PolynomialRing(Zn, "x")

   for iter in 1:10
      f = rand(R, 0:10, 0:22)

      @test derivative(integral(f)) == f

      g = rand(R, 0:10, 0:22)

      @test integral(f + g) == integral(g) + integral(f)
      @test integral(f)*integral(g) == integral(integral(f)*g + integral(g)*f)
   end

   # Inexact field
   R, x = PolynomialRing(RealField, "x")

   for iter in 1:10
      f = rand(R, 0:10, 0:1)

      @test isapprox(derivative(integral(f)), f)

      g = rand(R, 0:10, 0:1)

      @test isapprox(integral(f + g), integral(g) + integral(f))
      @test isapprox(integral(f)*integral(g), integral(integral(f)*g + integral(g)*f))
   end
end

@testset "Generic.Poly.sylvester_matrix..." begin
   R, x = PolynomialRing(ZZ, "x")

   for iter in 1:10
      f = rand(R, 1:5, -10:10)
      g = rand(R, 1:5, -10:10)
      while degree(f) <= 0 || degree(g) <= 0
         f = rand(R, 1:5, -10:10)
         g = rand(R, 1:5, -10:10)
      end

      d1 = degree(f)
      d2 = degree(g)

      f1 = rand(R, 0:d2-1, -10:10)
      g1 = rand(R, 0:d1-1, -10:10)

      w = matrix(ZZ, 1, d2, [coeff(f1, d2 - i) for i in 1:d2])
      w = hcat(w, matrix(ZZ, 1, d1, [coeff(g1, d1 - i) for i in 1:d1]))

      h = f1 * f + g1 * g

      v = matrix(ZZ, 1, d1 + d2, [coeff(h, d1 + d2 - i) for i in 1:d1 + d2])
      M = sylvester_matrix(f, g)
      @test v == w * M
   end
end

@testset "Generic.Poly.resultant..." begin
   # Exact ring
   R, x = PolynomialRing(ZZ, "x")

   for iter in 1:10
      f = rand(R, 0:5, -10:10)
      g = rand(R, 0:5, -10:10)
      h = rand(R, 0:5, -10:10)

      @test resultant(f*g, h) == resultant(f, h) * resultant(g, h)
      @test resultant(f, g*h) == resultant(f, g) * resultant(f, h)

      @test resultant(f, g) == resultant_subresultant(f, g)
      @test resultant_ducos(f, g) == resultant_subresultant(f, g)
   end

   # Exact field
   R, x = PolynomialRing(QQ, "x")

   for iter in 1:10
      f = rand(R, 0:5, -10:10)
      g = rand(R, 0:5, -10:10)
      h = rand(R, 0:5, -10:10)

      @test resultant(f*g, h) == resultant(f, h) * resultant(g, h)
      @test resultant(f, g*h) == resultant(f, g) * resultant(f, h)

      @test resultant(f, g) == resultant_subresultant(f, g)
      @test resultant_ducos(f, g) == resultant_subresultant(f, g)
      @test resultant(f, g) == Generic.resultant_lehmer(f, g)
   end

   # Characteristic p ring
   Zn = ResidueRing(ZZ, 23)
   R, x = PolynomialRing(Zn, "x")

   for iter in 1:10
      f = rand(R, 0:5, 0:22)
      g = rand(R, 0:5, 0:22)
      h = rand(R, 0:5, 0:22)

      @test resultant(f*g, h) == resultant(f, h)*resultant(g, h)
      @test resultant(f, g*h) == resultant(f, g)*resultant(f, h)

      @test resultant(f, g) == resultant_subresultant(f, g)
      @test resultant_ducos(f, g) == resultant_subresultant(f, g)
   end

   # Characteristic p field
   R, x = PolynomialRing(GF(23), "x")

   for iter in 1:10
      f = rand(R, 0:5)
      g = rand(R, 0:5)
      h = rand(R, 0:5)

      @test resultant(f*g, h) == resultant(f, h)*resultant(g, h)
      @test resultant(f, g*h) == resultant(f, g)*resultant(f, h)

      @test resultant(f, g) == resultant_subresultant(f, g)
      @test resultant_ducos(f, g) == resultant_subresultant(f, g)
   end

   # Inexact field
   R, x = PolynomialRing(RealField, "x")

   for iter in 1:10
      f = rand(R, 0:5, 0:1)
      g = rand(R, 0:5, 0:1)
      h = rand(R, 0:5, 0:1)

      @test isapprox(resultant(f*g, h), resultant(f, h)*resultant(g, h))
      @test isapprox(resultant(f, g*h), resultant(f, g)*resultant(f, h))

      @test isapprox(resultant(f, g), resultant_subresultant(f, g))
   end

   # Non-integral domain
   Zn = ResidueRing(ZZ, 6)
   R, x = PolynomialRing(Zn, "x")

   for iter in 1:10
      f = rand(R, 0:5, 0:5)
      g = rand(R, 0:5, 0:5)
      h = rand(R, 0:5, 0:5)

      @test lead(f)*lead(g) == 0 || resultant(f*g, h) == resultant(f, h)*resultant(g, h)
      @test lead(g)*lead(h) == 0 || resultant(f, g*h) == resultant(f, g)*resultant(f, h)
   end
end

@testset "Generic.Poly.discriminant..." begin
   # Exact ring
   R, x = PolynomialRing(ZZ, "x")

   for iter = 1:100
      f = R()
      g = R()
      while length(f) < 2 || length(g) < 2
         f = rand(R, 1:5, -10:10)
         g = rand(R, 1:5, -10:10)
      end

      # See http://www2.math.uu.se/~svante/papers/sjN5.pdf 3.10
      # The identity on Wikipedia is incorrect as of 07.10.2017
      @test discriminant(f*g) == discriminant(f)*discriminant(g)*resultant(g, f)^2
   end

   # Inexact field
   R, x = PolynomialRing(RealField, "x")

   for iter = 1:100
      f = R()
      g = R()
      while length(f) < 2 || length(g) < 2
         f = rand(R, 0:10, 0:1)
         g = rand(R, 0:10, 0:1)
      end

      # See http://www2.math.uu.se/~svante/papers/sjN5.pdf 3.10
      # The identity on Wikipedia is incorrect as of 07.10.2017
      @test isapprox(discriminant(f*g), discriminant(f)*discriminant(g)*resultant(g, f)^2)
   end

#   TODO: Fix issue #291
#   # Non-integral domain
#   Zn = ResidueRing(ZZ, 6)
#   R, x = PolynomialRing(Zn, "x")
#
#   for iter = 1:100
#      f = R()
#      g = R()
#      while length(f) < 2 || length(g) < 2
#         f = rand(R, 1:5, 0:5)
#         g = rand(R, 1:5, 0:5)
#      end
#
#      # See http://www2.math.uu.se/~svante/papers/sjN5.pdf 3.10
#      # The identity on Wikipedia is incorrect as of 07.10.2017
#      @test discriminant(f*g) == discriminant(f)*discriminant(g)*resultant(g, f)^2
#   end
end

@testset "Generic.Poly.resx..." begin
   # Exact ring
   R, x = PolynomialRing(ZZ, "x")

   for iter in 1:100
      f = R()
      g = R()
      while length(f) <= 1 && length(g) <= 1
         f = rand(R, 0:5, -10:10)
         g = rand(R, 0:5, -10:10)
      end
      r, u, v = resx(f, g)

      @test u*f + v*g == r
      @test r == resultant(f, g)

      h = rand(R, 0:5, -10:10)
      r, u, v = resx(f*h, g*h)

      @test (u*f + v*g)*h == r
   end

   # Exact field
   R, x = PolynomialRing(QQ, "x")

   for iter in 1:100
      f = R()
      g = R()
      while length(f) <= 1 && length(g) <= 1
         f = rand(R, 0:5, -10:10)
         g = rand(R, 0:5, -10:10)
      end
      r, u, v = resx(f, g)

      @test u*f + v*g == r
      @test r == resultant(f, g)

      h = rand(R, 0:5, -10:10)
      r, u, v = resx(f*h, g*h)

      @test (u*f + v*g)*h == r
   end

   # Inexact field
   R, x = PolynomialRing(RealField, "x")

   for iter in 1:100
      f = R()
      g = R()
      while length(f) <= 1 && length(g) <= 1
         f = rand(R, 0:5, 0:1)
         g = rand(R, 0:5, 0:1)
      end
      r, u, v = resx(f, g)

      @test isapprox(u*f + v*g, r)
      @test isapprox(r, resultant(f, g))

      h = rand(R, 0:5, 0:1)
      r, u, v = resx(f*h, g*h)

      @test isapprox((u*f + v*g)*h, r)
   end

   # Characteristic p ring
   Zn = ResidueRing(ZZ, 23)
   R, x = PolynomialRing(Zn, "x")

   for iter in 1:100
      f = R()
      g = R()
      while length(f) <= 1 && length(g) <= 1
         f = rand(R, 0:5, 0:22)
         g = rand(R, 0:5, 0:22)
      end
      r, u, v = resx(f, g)

      @test u*f + v*g == r
      @test r == resultant(f, g)

      h = rand(R, 0:5, 0:22)
      r, u, v = resx(f*h, g*h)

      @test (u*f + v*g)*h == r
   end

   # Characteristic p field
   R, x = PolynomialRing(GF(23), "x")

   for iter in 1:100
      f = R()
      g = R()
      while length(f) <= 1 && length(g) <= 1
         f = rand(R, 0:5)
         g = rand(R, 0:5)
      end
      r, u, v = resx(f, g)

      @test u*f + v*g == r
      @test r == resultant(f, g)

      h = rand(R, 0:5)
      r, u, v = resx(f*h, g*h)

      @test (u*f + v*g)*h == r
   end

#   TODO: Fix issue #293
#   Test will cause impossible inverse in the mean time
#
#   # Non-integral domain
#   Zn = ResidueRing(ZZ, 6)
#   R, x = PolynomialRing(Zn, "x")
#
#   for iter in 1:100
#      f = R()
#      g = R()
#      while length(f) <= 1 && length(g) <= 1
#         f = rand(R, 0:5, 0:5)
#         g = rand(R, 0:5, 0:5)
#      end
#      r, u, v = resx(f, g)
#
#      @test u*f + v*g == r
#      @test r == resultant(f, g)
#
#      h = R()
#      h = rand(R, 0:5, 0:5)
#      r, u, v = resx(f*h, g*h)
#
#      @test (u*f + v*g)*h == r
#   end
end

@testset "Generic.Poly.gcdx..." begin
   # Exact field
   R, x = PolynomialRing(QQ, "x")

   for iter in 1:100
      f = R()
      g = R()
      while length(f) <= 1 && length(g) <= 1
         f = rand(R, 0:5, -10:10)
         g = rand(R, 0:5, -10:10)
      end
      r, u, v = gcdx(f, g)

      @test u*f + v*g == r
      @test r == gcd(f, g)

      h = R()
      h = rand(R, 0:5, -10:10)
      r, u, v = gcdx(f*h, g*h)

      @test (u*f + v*g)*h == r
   end

   # Characteristic p ring
   Zn = ResidueRing(ZZ, 23)
   R, x = PolynomialRing(Zn, "x")

   for iter in 1:100
      f = R()
      g = R()
      while length(f) <= 1 && length(g) <= 1
         f = rand(R, 0:5, 0:22)
         g = rand(R, 0:5, 0:22)
      end
      r, u, v = gcdx(f, g)

      @test u*f + v*g == r
      @test r == gcd(f, g)

      h = rand(R, 0:5, 0:22)
      r, u, v = gcdx(f*h, g*h)

      @test (u*f + v*g)*h == r
   end

   # Characteristic p field
   R, x = PolynomialRing(GF(23), "x")

   for iter in 1:100
      f = R()
      g = R()
      while length(f) <= 1 && length(g) <= 1
         f = rand(R, 0:5)
         g = rand(R, 0:5)
      end
      r, u, v = gcdx(f, g)

      @test u*f + v*g == r
      @test r == gcd(f, g)

      h = rand(R, 0:5)
      r, u, v = gcdx(f*h, g*h)

      @test (u*f + v*g)*h == r
   end

   # Fake finite field of char 7, degree 2
   S, y = PolynomialRing(GF(7), "y")
   F = ResidueField(S, y^2 + 6y + 3)
   a = F(y)
   R, x = PolynomialRing(F, "x")

   for iter in 1:100
      f = R()
      g = R()
      while length(f) <= 1 && length(g) <= 1
         f = rand(R, 0:5, 0:1)
         g = rand(R, 0:5, 0:1)
      end
      r, u, v = gcdx(f, g)

      @test u*f + v*g == r
      @test r == gcd(f, g)

      h = rand(R, 0:5, 0:1)
      r, u, v = gcdx(f*h, g*h)

      @test (u*f + v*g)*h == r
   end
end

@testset "Generic.Poly.newton_representation..." begin
   # Exact ring
   R, x = PolynomialRing(ZZ, "x")

   for iter in 1:10
      f = rand(R, 0:10, -100:100)

      g = deepcopy(f)
      roots = BigInt[rand(ZZ, -10:10) for i in 1:length(f)]
      monomial_to_newton!(g.coeffs, roots)
      newton_to_monomial!(g.coeffs, roots)

      @test f == g
   end

   # Exact field
   R, x = PolynomialRing(QQ, "x")

   for iter in 1:10
      f = rand(R, 0:10, -100:100)

      g = deepcopy(f)
      roots = Rational{BigInt}[rand(QQ, -10:10) for i in 1:length(f)]
      monomial_to_newton!(g.coeffs, roots)
      newton_to_monomial!(g.coeffs, roots)

      @test f == g
   end

   # Inexact field
   R, x = PolynomialRing(RealField, "x")

   for iter in 1:10
      f = rand(R, 0:10, 0:1)

      g = deepcopy(f)
      roots = BigFloat[rand(RealField, 0:1) for i in 1:length(f)]
      monomial_to_newton!(g.coeffs, roots)
      newton_to_monomial!(g.coeffs, roots)

      @test isapprox(f, g)
   end

   # Characteristic p ring
   Zn = ResidueRing(ZZ, 23)
   R, x = PolynomialRing(Zn, "x")

   for iter in 1:10
      f = rand(R, 0:10, 0:22)

      g = deepcopy(f)
      roots = elem_type(Zn)[rand(Zn, 0:22) for i in 1:length(f)]
      monomial_to_newton!(g.coeffs, roots)
      newton_to_monomial!(g.coeffs, roots)

      @test f == g
   end

   # Characteristic p ring
   K = GF(23)
   R, x = PolynomialRing(K, "x")

   for iter in 1:10
      f = rand(R, 0:10)

      g = deepcopy(f)
      roots = elem_type(K)[rand(K) for i in 1:length(f)]
      monomial_to_newton!(g.coeffs, roots)
      newton_to_monomial!(g.coeffs, roots)

      @test f == g
   end

   # Non-integral domain
   Zn = ResidueRing(ZZ, 6)
   R, x = PolynomialRing(Zn, "x")

   for iter in 1:10
      f = rand(R, 0:10, 0:5)

      g = deepcopy(f)
      roots = elem_type(Zn)[rand(Zn, 0:5) for i in 1:length(f)]
      monomial_to_newton!(g.coeffs, roots)
      newton_to_monomial!(g.coeffs, roots)

      @test f == g
   end
end

@testset "Generic.Poly.interpolation..." begin
   # Exact ring
   R, x = PolynomialRing(ZZ, "x")

   for iter in 1:10
      p = R()
      while p == 0
         p = rand(R, 0:10, -10:10)
      end

      xs = BigInt[i for i in 1:length(p)]
      ys = [p(i) for i in 1:length(p)]

      f = interpolate(R, xs, ys)

      @test f == p
   end

   # Exact field
   R, x = PolynomialRing(QQ, "x")

   for iter in 1:10
      p = R()
      while p == 0
         p = rand(R, 0:10, -10:10)
      end

      xs = Rational{BigInt}[i for i in 1:length(p)]
      ys = [p(i) for i in 1:length(p)]

      f = interpolate(R, xs, ys)

      @test f == p
   end

   # Inexact field
   R, x = PolynomialRing(RealField, "x")

   for iter in 1:10
      p = R()
      while p == 0
         p = rand(R, 0:10, 0:1)
      end

      xs = BigFloat[i for i in 1:length(p)]
      ys = [p(i) for i in 1:length(p)]

      f = interpolate(R, xs, ys)

      @test isapprox(f, p)
   end

   # Characteristic p ring
   Zn = ResidueRing(ZZ, 23)
   R, x = PolynomialRing(Zn, "x")

   for iter in 1:10
      p = R()
      while p == 0
         p = rand(R, 0:10, 0:22)
      end

      xs = elem_type(Zn)[Zn(i) for i in 1:length(p)]
      ys = [p(i) for i in 1:length(p)]

      f = interpolate(R, xs, ys)

      @test f == p
   end

   # Characteristic p field
   K = GF(23)
   R, x = PolynomialRing(K, "x")

   for iter in 1:10
      p = R()
      while p == 0
         p = rand(R, 0:10)
      end

      xs = elem_type(K)[K(i) for i in 1:length(p)]
      ys = [p(i) for i in 1:length(p)]

      f = interpolate(R, xs, ys)

      @test f == p
   end

#   TODO: Fix issue #294 (if possible)
#   # Non-integral domain
#   Zn = ResidueRing(ZZ, 6)
#   R, x = PolynomialRing(Zn, "x")
#
#   for iter in 1:10
#      p = R()
#      while p == 0
#         p = rand(R, 0:10, 0:5)
#      end
#
#      xs = elem_type(Zn)[Zn(i) for i in 1:length(p)]
#      ys = [p(i) for i in 1:length(p)]
#
#      f = interpolate(R, xs, ys)
#
#      @test f == p
#   end
end

@testset "Generic.Poly.special..." begin
   # Exact ring
   R, x = PolynomialRing(ZZ, "x")

   for n in 10:20
      T = chebyshev_t(n, x)
      dT = derivative(T)
      ddT = derivative(dT)

      @test (1 - x^2)*ddT + n^2*T == x*dT

      U = chebyshev_u(n - 1, x)
      dU = derivative(U)
      ddU = derivative(dU)

      @test (1 - x^2)*ddU + (n-1)*(n+1)*U == 3*x*dU

      @test T^2 == 1 + (x^2 - 1)*U^2
   end

   # Exact field
   R, x = PolynomialRing(QQ, "x")

   for n in 10:20
      T = chebyshev_t(n, x)
      dT = derivative(T)
      ddT = derivative(dT)

      @test (1 - x^2)*ddT + n^2*T == x*dT

      U = chebyshev_u(n - 1, x)
      dU = derivative(U)
      ddU = derivative(dU)

      @test (1 - x^2)*ddU + (n-1)*(n+1)*U == 3*x*dU

      @test T^2 == 1 + (x^2 - 1)*U^2
   end

   # Inexact field
   R, x = PolynomialRing(RealField, "x")

   for n in 10:20
      T = chebyshev_t(n, x)
      dT = derivative(T)
      ddT = derivative(dT)

      @test (1 - x^2)*ddT + n^2*T == x*dT

      U = chebyshev_u(n - 1, x)
      dU = derivative(U)
      ddU = derivative(dU)

      @test (1 - x^2)*ddU + (n-1)*(n+1)*U == 3*x*dU

      @test T^2 == 1 + (x^2 - 1)*U^2
   end

   # Characteristic p ring
   Zn = ResidueRing(ZZ, 23)
   R, x = PolynomialRing(Zn, "x")

   for n in 10:20
      T = chebyshev_t(n, x)
      dT = derivative(T)
      ddT = derivative(dT)

      @test (1 - x^2)*ddT + n^2*T == x*dT

      U = chebyshev_u(n - 1, x)
      dU = derivative(U)
      ddU = derivative(dU)

      @test (1 - x^2)*ddU + (n-1)*(n+1)*U == 3*x*dU

      @test T^2 == 1 + (x^2 - 1)*U^2
   end

   # Characteristic p field
   R, x = PolynomialRing(GF(23), "x")

   for n in 10:20
      T = chebyshev_t(n, x)
      dT = derivative(T)
      ddT = derivative(dT)

      @test (1 - x^2)*ddT + n^2*T == x*dT

      U = chebyshev_u(n - 1, x)
      dU = derivative(U)
      ddU = derivative(dU)

      @test (1 - x^2)*ddU + (n-1)*(n+1)*U == 3*x*dU

      @test T^2 == 1 + (x^2 - 1)*U^2
   end

   # Non-integral domain
   Zn = ResidueRing(ZZ, 6)
   R, x = PolynomialRing(Zn, "x")

   for n in 10:20
      T = chebyshev_t(n, x)
      dT = derivative(T)
      ddT = derivative(dT)

      @test (1 - x^2)*ddT + n^2*T == x*dT

      U = chebyshev_u(n - 1, x)
      dU = derivative(U)
      ddU = derivative(dU)

      @test (1 - x^2)*ddU + (n-1)*(n+1)*U == 3*x*dU

      @test T^2 == 1 + (x^2 - 1)*U^2
   end
end

@testset "Generic.Poly.mul_karatsuba..." begin
   # Exact ring
   R, x = PolynomialRing(ZZ, "x")
   S, y = PolynomialRing(R, "y")
   T, z = PolynomialRing(S, "z")

   f = x + y + 2z^2 + 1

   @test mul_karatsuba(f^10, f^10) == mul_classical(f^10, f^10)
   @test mul_karatsuba(f^10, f^30) == mul_classical(f^10, f^30)
end

@testset "Generic.Poly.mul_ks..." begin
   # Exact ring
   R, x = PolynomialRing(ZZ, "x")
   S, y = PolynomialRing(R, "y")
   T, z = PolynomialRing(S, "z")

   f = x + y + 2z^2 + 1

   @test mul_ks(f^10, f^10) == mul_classical(f^10, f^10)
   @test mul_ks(f^10, f^30) == mul_classical(f^10, f^30)
end

@testset "Generic.Poly.remove_valuation..." begin
   # Exact ring
   R, x = PolynomialRing(ZZ, "x")

   @test_throws ErrorException remove(R(1), R(0))
   @test_throws ErrorException remove(R(1), R(-1))
   @test_throws ErrorException remove(R(0), R(1))
   @test_throws ErrorException remove(R(0), R(2))

   for iter = 1:10
      d = true
      f = R()
      g = R()
      while d
         f = R()
         g = R()
         while iszero(f) || iszero(g) || isunit(g)
           f = rand(R, 0:10, -10:10)
           g = rand(R, 0:10, -10:10)
         end

         d, q = divides(f, g)
         if d
           @test g * q == f
         end
      end

      s = rand(0:10)

      v, q = remove(f*g^s, g)

      @test valuation(f*g^s, g) == s
      @test q == f
      @test v == s

      v, q = divides(f*g, f)

      @test v
      @test q == g

      if length(f) > 1
         v, q = divides(f*g + 1, f)

         @test !v
      end
   end

   # Exact field
   R, x = PolynomialRing(QQ, "x")

   @test_throws ErrorException remove(R(1), R(0))
   @test_throws ErrorException remove(R(1), R(1))
   @test_throws ErrorException remove(R(0), R(x))
   @test_throws ErrorException remove(R(1), R(2))

   for iter = 1:10
      d = true
      f = R()
      g = R()
      while d
         f = R()
         g = R()
         while f == 0 || g == 0 || isunit(g)
            f = rand(R, 0:10, -10:10)
            g = rand(R, 0:10, -10:10)
         end

         d, q = divides(f, g)
      end

      s = rand(0:10)

      v, q = remove(f*g^s, g)

      @test valuation(f*g^s, g) == s
      @test q == f
      @test v == s

      v, q = divides(f*g, f)

      @test v
      @test q == g

      if length(f) > 1
         v, q = divides(f*g + 1, f)

         @test !v
      end
   end

   # Characteristic p ring
   Zn = ResidueRing(ZZ, 23)
   R, x = PolynomialRing(Zn, "x")

   for iter = 1:10
      d = true
      f = R()
      g = R()
      while d
         f = R()
         g = R()
         while f == 0 || g == 0 || isunit(g)
            f = rand(R, 0:10, 0:22)
            g = rand(R, 0:10, 0:22)
         end

         d, q = divides(f, g)
      end

      s = rand(0:10)

      v, q = remove(f*g^s, g)

      @test valuation(f*g^s, g) == s
      @test q == f
      @test v == s

      v, q = divides(f*g, f)

      @test v
      @test q == g

      if length(f) > 1
         v, q = divides(f*g + 1, f)

         @test !v
      end
   end

   # Characteristic p field
   R, x = PolynomialRing(GF(23), "x")

   for iter = 1:10
      d = true
      f = R()
      g = R()
      while d
         f = R()
         g = R()
         while f == 0 || g == 0 || isunit(g)
            f = rand(R, 0:10)
            g = rand(R, 0:10)
         end

         d, q = divides(f, g)
      end

      s = rand(0:10)

      v, q = remove(f*g^s, g)

      @test valuation(f*g^s, g) == s
      @test q == f
      @test v == s

      v, q = divides(f*g, f)

      @test v
      @test q == g

      if length(f) > 1
         v, q = divides(f*g + 1, f)

         @test !v
      end
   end
end

@testset "Generic.Poly.square_root..." begin
   # Exact ring
   S, x = PolynomialRing(ZZ, "x")
   for iter = 1:10
      f = rand(S, 0:20, -20:20)

      p = f^2

      @test issquare(p)

      q = sqrt(f^2)

      @test q^2 == f^2

      q = sqrt(f^2, false)

      @test q^2 == f^2

      if f != 0
         @test_throws ErrorException sqrt(f^2*x)
      end
   end

   # Exact field
   S, x = PolynomialRing(QQ, "x")
   for iter = 1:10
      f = rand(S, 0:20, -20:20)

      p = f^2

      @test issquare(p)

      q = sqrt(f^2)

      @test q^2 == f^2

      q = sqrt(f^2, false)

      @test q^2 == f^2

      if f != 0
         @test_throws ErrorException sqrt(f^2*x)
      end
   end

   # Characteristic p field
   for p in [2, 7, 19, 65537, ZZ(2), ZZ(7), ZZ(19), ZZ(65537)]
      R = ResidueField(ZZ, p)

      S, x = PolynomialRing(R, "x")
      
      for iter = 1:10
         f = rand(S, 0:20, 0:Int(p))
         
         s = f^2
         
         @test issquare(s)

         q = sqrt(f^2)

         @test q^2 == f^2

         q = sqrt(f^2, false)

         @test q^2 == f^2

         if f != 0
            @test_throws ErrorException sqrt(f^2*x)
         end
      end
   end
end

@testset "Generic.Poly.generic_eval..." begin
   R, x = PolynomialRing(ZZ, "x")

   for iter in 1:10
      f = rand(R, 0:2, -100:100)
      g = rand(R, 0:2, -100:100)
      h = rand(R, 0:2, -100:100)

      @test f(g(h)) == f(g)(h)
   end

   R, x = PolynomialRing(ZZ, "x")

   f = x
   b = a = QQ(13)
   for i in 1:5
      g = x^2 + rand(R, 0:1, -1:1)
      f = g(f)
      b = g(b)

      @test b == f(a)
   end
end

@testset "Generic.Poly.change_base_ring..." begin
   Zx, x = PolynomialRing(ZZ,'x')
   @test 1 == map_coeffs(sqrt, x^0)
   p = Zx([i for i in 1:10])
   q = Zx([i for i in 10:-1:1])
   pq = p * q
   for R in [QQ,GF(2),GF(13),ZZ]
      pR = change_base_ring(R, p)
      qR = change_base_ring(R, q, parent = parent(pR))
      @test parent(qR) === parent(pR)
      pqR = change_base_ring(R, pq, parent = parent(pR))
      @test pR * qR == pqR
   end

   ps = map_coeffs(z -> z^2, p)
   @test ps == Zx([i^2 for i in 1:10])

   f = x^2 + 3x^3 + 2x^6
   @test map_coeffs(one, f) == x^2 + x^3 + x^6
   f2 = map_coeffs(t -> t+2, f)
   @test f2 == 3x^2 + 5x^3 + 4x^6
   for i in [0, 1, 4, 5]
      @test coeff(f2, i) !== coeff(f, i)
   end

   F = GF(11)
   P, y = PolynomialRing(F, 'x')
   @test map_coeffs(t -> F(t) + 2, f) == 3y^2 + 5y^3 + 4y^6
end

@testset "Generic.Poly.printing..." begin
   M = MatrixAlgebra(ZZ, 3)
   _, x = M['x']
   @test string(M(-1)*x) isa String
end