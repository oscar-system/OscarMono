module LoadFlint

using Libdl

const pkgdir = realpath(joinpath(dirname(@__DIR__)))
const libdir = joinpath(pkgdir, "deps", "usr", "lib")
const bindir = joinpath(pkgdir, "deps", "usr", "bin")
if Sys.iswindows()
   libgmp = joinpath(bindir, "libgmp-10")
   libflint = joinpath(bindir, "libflint")
else
   libgmp = joinpath(libdir, "libgmp")
   libflint = joinpath(libdir, "libflint")
end

const __isthreaded = Ref(false)

function __init__()
  global libflint, libgmp

  l = dllist()

  f = filter(x->occursin("libflint", x), l)
  new_flint = true
  if length(f) == 1
    global libflint = f[1]
    new_flint = false
  elseif length(f) > 0
    error("too many flint")
  end

  tmp = Sys.iswindows() ? "libgmp-10" : "libgmp"
  f = filter(x->occursin(tmp, x), l)
  new_gmp = true
  if length(f) == 1
    global libgmp = f[1]
    new_gmp = false
  elseif length(f) > 0
    error("too many gmp")
  end

  if new_gmp && !Sys.iswindows() && !__isthreaded[]
    lf = dllist(libgmp)
    fm = dlsym(lf, :__gmp_set_memory_functions)
    ccall(fm, Nothing,
            (Ptr{Nothing},Ptr{Nothing},Ptr{Nothing}),
            cglobal(:jl_gc_counted_malloc),
            cglobal(:jl_gc_counted_realloc_with_old_size),
            cglobal(:jl_gc_counted_free_with_size))
  end          

  if new_flint && !Sys.iswindows() && !__isthreaded[]
    lf = dlopen(libflint)
    fm = dlsym(lf, :__flint_set_memory_functions)
    #to match the global gmp ones
    ccall(fm, Nothing,
      (Ptr{Nothing},Ptr{Nothing},Ptr{Nothing},Ptr{Nothing}),
        cglobal(:jl_malloc),
        cglobal(:jl_calloc),
        cglobal(:jl_realloc),
        cglobal(:jl_free))
  end      
end

end # module
