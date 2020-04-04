# this file is only for julia older than 1.3

using Libdl

if "FLINT_PATH" in keys(ENV)

   if VERSION >= v"1.3.0-rc4"
      error("please use Pkg Overrides.toml for custom flint installations in julia >= 1.3")
   end

   flint_path = ENV["FLINT_PATH"]
   if !isfile(flint_path)
      error("FLINT_PATH: file does not exists")
   end

   open(joinpath(@__DIR__,"deps.jl"), "w") do f
      println(f, """
using Libdl
libflint = "$flint_path"
if Libdl.dlopen_e(libflint) in (C_NULL, nothing)
    error("$(libflint) cannot be opened, Please check FLINT_PATH environment variable and re-run Pkg.build("LoadFlint"), then restart Julia.")
end
""")
   end

elseif VERSION < v"1.3.0-rc4"

   using BinaryProvider

   # Parse some basic command-line arguments
   const verbose = "--verbose" in ARGS

   dependencies = [
     # This has to be in sync with the jll packages (using generate_build.jl and build_tarballs.jl from Yggdrasil)
     "build_FLINT.v0.0.1.jl",
    ]
    # GMP is not needed on unix as julia should have those loaded already
   if Sys.iswindows()
       pushfirst!(dependencies,"build_MPFR.v4.0.2.jl")
       pushfirst!(dependencies,"build_GMP.v6.1.2.jl")
   end

   const prefix = Prefix(get([a for a in ARGS if a != "--verbose"], 1, joinpath(@__DIR__, "usr")))

   products = []

   # Execute the build scripts for the dependencies in an isolated module to avoid overwriting
   # any variables/constants here
   for file in dependencies
       build_file = joinpath(@__DIR__, file)
       m = @eval module $(gensym()); include($build_file); end
       append!(products, m.products)
   end

   write_deps_file(joinpath(@__DIR__, "deps.jl"), Array{Product,1}(products), verbose=verbose)

end

# we do libgmp manually to avoid loading the one from BinaryBuilder and the julia one
open(joinpath(@__DIR__,"deps.jl"), "a") do f
   println(f, """
f = filter(x->occursin(r"libgmp(-10|\\.)", x), dllist())
libgmp = f[1]
""")
end
