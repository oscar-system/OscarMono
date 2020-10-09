#!/bin/sh
set -e
set -x

git subtree add --prefix LoadFlint.jl https://github.com/oscar-system/LoadFlint.jl master
git subtree add --prefix AbstractAlgebra.jl https://github.com/Nemocas/AbstractAlgebra.jl master
git subtree add --prefix Nemo.jl https://github.com/Nemocas/Nemo.jl master
git subtree add --prefix Hecke.jl https://github.com/thofma/Hecke.jl master
git subtree add --prefix GAP.jl https://github.com/oscar-system/GAP.jl master
git subtree add --prefix Polymake.jl https://github.com/oscar-system/Polymake.jl master
git subtree add --prefix libsingular-julia https://github.com/oscar-system/libsingular-julia master
git subtree add --prefix libpolymake-julia https://github.com/oscar-system/libpolymake-julia master
git subtree add --prefix Singular.jl https://github.com/oscar-system/Singular.jl master
git subtree add --prefix Oscar.jl https://github.com/oscar-system/Oscar.jl master
