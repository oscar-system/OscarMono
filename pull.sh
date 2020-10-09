#!/bin/sh
# pull changes to the selected subproject(s)
set -e

projects='
https://github.com/oscar-system/LoadFlint.jl
https://github.com/Nemocas/AbstractAlgebra.jl
https://github.com/Nemocas/Nemo.jl
https://github.com/thofma/Hecke.jl
https://github.com/oscar-system/GAP.jl
https://github.com/oscar-system/Polymake.jl
https://github.com/oscar-system/libsingular-julia
https://github.com/oscar-system/libpolymake-julia
https://github.com/oscar-system/Singular.jl
https://github.com/oscar-system/Oscar.jl
'

for url in ${projects}
do
    proj=$(basename ${url})
    echo "== pulling ${proj} ==="
    git subtree pull --prefix ${proj} ${url} master
done
