module LoadFlint

greet() = print("Hello World!")

using Libdl


const pkgdir = realpath(joinpath(dirname(@__DIR__)))
const libdir = joinpath(pkgdir, "deps", "usr", "lib")
const bindir = joinpath(pkgdir, "deps", "usr", "bin")
if Sys.iswindows()
   libgmp = joinpath(pkgdir, "deps", "usr", "bin", "libgmp-10")
   libflint = joinpath(pkgdir, "deps", "usr", "bin", "libflint")
else
   libgmp = joinpath(pkgdir, "deps", "usr", "lib", "libgmp")
   libflint = joinpath(pkgdir, "deps", "usr", "lib", "libflint")
end

const __isthreaded = Ref(false)

function __init__()
  global libflint, libgmp

  l = dllist()

  f = findall(x->occursin("flint", x), l)
  new_flint = true
  if length(f) == 1
    global libflint = l[f[1]]
    new_flint = false
  else
    length(f) == 0 || error("too many flint")
  end

  f = findall(x->occursin("libgmp", x), l)
  new_gmp = true
  if length(f) == 1
    global libgmp = l[f[1]]
    new_gmp = false
  else
    length(f) == 0 || error("too many gmp")
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
