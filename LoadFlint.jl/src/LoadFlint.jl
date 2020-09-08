module LoadFlint

using Libdl

if VERSION > v"1.3.0-rc4"
  # this should do the dlopen for 1.3 and later
  # and imports the libxxx variables
  using GMP_jll
  using MPFR_jll
  using FLINT_jll
else
  deps_dir = joinpath(@__DIR__, "..", "deps")
  include(joinpath(deps_dir,"deps.jl"))
end

libflint_handle = C_NULL

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

  # the [.-] at the end is important to avoid matching libgmpxx
  f = filter(x->occursin(r"libgmp[.-]", x), dllist())
  if length(f) == 0
    error("there must be at least one libgmp loaded.")
  elseif length(f) > 1
    # at the moment there doesnt seem to be a way to avoid this
    # because julia comes with libgmp
    # and GMP_jll will load another libgmp
    @debug("there should be exactly one libgmp, but we have: ", f)
  end

  # variable libflint comes from deps file or flint_jll
  global libflint_handle = dlopen(libflint,RTLD_NOLOAD)

  if !Sys.iswindows() && !__isthreaded[]
    #to match the global gmp ones
    fm = dlsym(libflint_handle, :__flint_set_memory_functions)
    ccall(fm, Nothing,
      (Ptr{Nothing},Ptr{Nothing},Ptr{Nothing},Ptr{Nothing}),
        cglobal(:jl_malloc),
        cglobal(:jl_calloc),
        cglobal(:jl_realloc),
        cglobal(:jl_free))
  end      
end

end # module
