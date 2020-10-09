# little helper script
#   
#
#  TODO:
#  - teach pull/push to work on only a single sub repository

import Pkg

repos = [
         "https://github.com/oscar-system/LoadFlint.jl"
         "https://github.com/Nemocas/AbstractAlgebra.jl"
         "https://github.com/Nemocas/Nemo.jl"
         "https://github.com/thofma/Hecke.jl"
         "https://github.com/oscar-system/GAP.jl"
         "https://github.com/oscar-system/Polymake.jl"
         "https://github.com/oscar-system/libsingular-julia"
         "https://github.com/oscar-system/libpolymake-julia"
         "https://github.com/oscar-system/Singular.jl"
         "https://github.com/oscar-system/Oscar.jl"
       ]

function usage()
    println("""
        Usage:
          julia mono.jl create   -- perform the initial import of all repositories
          julia mono.jl pull     -- pull all our separate repositories
          julia mono.jl push     -- push out to all our separate repositories
          julia mono.jl dev      -- dev all subpackages
        """)
    exit(1)
end

length(ARGS) > 0 || usage()

if ARGS[1] == "create"
    for url in repos
        prefix = basename(url)
        println("importing $(prefix)")
        run(`git subtree add --prefix $(prefix) $(url) master`)
    end

elseif ARGS[1] == "pull"
    for url in repos
        prefix = basename(url)
        println("pulling $(prefix)")
        run(`git subtree pull --prefix $(prefix) -m "merging $(prefix) commits" $(url) master`)
    end

elseif ARGS[1] == "push"
    for url in repos
        prefix = basename(url)
        println("TODO push")
    end

elseif ARGS[1] == "dev"
    # make sure to call develop  in the correct order, to avoid pulling in
    # other versions of our packages unnecessarily
    Pkg.develop(path="AbstractAlgebra.jl")
    Pkg.develop(path="LoadFlint.jl")
    Pkg.develop(path="Nemo.jl")
    Pkg.develop(path="Hecke.jl")
    Pkg.develop(path="GAP.jl")
    Pkg.develop(path="Polymake.jl")
    Pkg.develop(path="Singular.jl")
    Pkg.develop(path="Oscar.jl")
    
    # TODO: take care of the JLLs for libsingular-julia and libpolymake-julia
    # (and possibly more like polymake_jll, FLINT_jll, ...)
else
    usage()
end
