using LoadFlint
using Test
using Libdl

# Just successfully loading LoadFlint is a good first test

@testset "LoadFlint" begin
    @test occursin("libgmp", LoadFlint.libgmp)
    @test occursin("libflint", LoadFlint.libflint)

    l = dllist()
    @test length(filter(x->occursin("libflint", x), l)) == 1
    x = Ptr{Nothing}(0)
    @test (x = ccall((:flint_malloc,LoadFlint.libflint), Ptr{Nothing}, (UInt,), 8)) != C_NULL
    @test ccall((:flint_free,LoadFlint.libflint), Nothing ,(Ptr{Nothing},),x) == nothing

    # TODO maybe test fmpz?
end
