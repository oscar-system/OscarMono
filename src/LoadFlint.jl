module LoadFlint

using Libdl

if VERSION > v"1.3.0-rc4"
  # this should do the dlopen vor 1.3 and later
  using flint_jll
else
  deps_dir = joinpath(@__DIR__, "..", "deps")
  include(joinpath(deps_dir,"deps.jl"))
end

const __isthreaded = Ref(false)

function __init__()
  if VERSION < v"1.3.0-rc4"
    # this does the dlopen for 1.0-1.2
    check_deps()
  end

  l = dllist()
  f = filter(x->occursin("libflint", x), l)
  if length(f) != 1
    error("there should be exactly one libflint, but we have: ", f)
  end

  tmp = Sys.iswindows() ? "libgmp-10" : "libgmp."
  f = filter(x->occursin(tmp, x), l)
  if length(f) != 1
    # TODO:
    # at the moment there doesnt seem to be a way to avoid this
    # because julia comes with libgmp
    # and GMP_jll will load another libgmp
    @warn("there should be exactly one libgmp, but we have: ", f)
  end
  global libgmp = f[1]

  if !Sys.iswindows() && !__isthreaded[]
    # variable libflint comes from deps file or flint_jll
    flint_handle = dlopen(libflint,RTLD_NOLOAD)
    #to match the global gmp ones
    fm = dlsym(flint_handle, :__flint_set_memory_functions)
    ccall(fm, Nothing,
      (Ptr{Nothing},Ptr{Nothing},Ptr{Nothing},Ptr{Nothing}),
        cglobal(:jl_malloc),
        cglobal(:jl_calloc),
        cglobal(:jl_realloc),
        cglobal(:jl_free))
  end      
end

end # module
