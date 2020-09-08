function benchmark_minpoly_integers()
   print("benchmark_minpoly_integers ... ")
   M = MatrixSpace(FlintZZ, 80, 80)()
   
   for i in 1:40
      for j in 1:40
         r = rand(-20:20)
         M[i, j] = r
         M[40 + i, 40 + j] = deepcopy(r)
      end
   end

   for i in 1:10
      similarity!(M, rand(1:80), fmpz(rand(-3:3)))
   end

   tt = @elapsed minpoly(PolynomialRing(FlintZZ, "x")[1], M)
   println("$tt")
end

