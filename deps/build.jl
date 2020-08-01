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
# there must be some libgmp loaded for libflint
libgmp = filter(x->occursin(r"libgmp[.-]", x), dllist())[1]
libmpfr = filter(x->occursin(r"libmpfr[.-]", x), dllist())[1]

""")
   end

elseif VERSION < v"1.3.0-rc4"

   using Pkg, BinaryProvider

   # This does not work on julia >= 1.3, but there we use the *jll package anyway.
   ver = Pkg.API.__installed(PKGMODE_MANIFEST)["FLINT_jll"]

   # Parse some basic command-line arguments
   const verbose = "--verbose" in ARGS

   # GMP and MPFR might not be needed on unix as julia should have those loaded already
   # but on windows flint will not load without them so we leave them here for simplicity
   dependencies = [
     # This has to be in sync with the jll packages (using generate_build.jl and build_tarballs.jl from Yggdrasil)
     "build_GMP.v6.1.2.jl",
     "build_MPFR.v4.0.2.jl",
   ]

   if ver == v"2.6.0+0"
     push!(dependencies, "build_FLINT.v2.6.0.jl")
   elseif ver == v"2.6.2+0"
     push!(dependencies, "build_FLINT.v2.6.2.jl")
   else
     throw(error("Flint version $ver not supported for julia version <= 1.3"))
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

