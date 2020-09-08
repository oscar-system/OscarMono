using Pkg
using polymake_jll
using libcxxwrap_julia_jll

# we need to adjust the test-driver to running from the callable library
open(joinpath("test","run_testcases"), write=true) do out
    open(joinpath(polymake_jll.artifact_dir,"share","polymake","scripts","run_testcases")) do in
        for line in eachline(in, keep=true) # keep so the new line isn't chomped
            if startswith(line,"use Polymake")
                write(out,"use Getopt::Long;\n")
            end
            write(out, line)
        end
    end
end

# configure libpolymake-julia with artifact dirs
run(`cmake \
     -DPolymake_PREFIX=$(ENV["POLYMAKE_DEPS_TREE"]) \
     -DJlCxx_DIR=$(libcxxwrap_julia_jll.artifact_dir)/lib/cmake/JlCxx \
     -DCMAKE_INSTALL_PREFIX=$(pwd())/test/install \
     -DCMAKE_BUILD_TYPE=Release \
     -S . -B build`);

# add override
open("$(joinpath(Pkg.depots1(),"artifacts","Overrides.toml"))", "a") do io
    pkgid = Base.identify_package("libpolymake_julia_jll")
    write(io, """
              [$(pkgid.uuid)]
              libpolymake_julia = "$(joinpath(pwd(),"test","install"))"
              """)
end;

