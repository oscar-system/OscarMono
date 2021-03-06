using BinaryProvider # requires BinaryProvider 0.3.0 or later

# Parse some basic command-line arguments
const verbose = "--verbose" in ARGS
const prefix = Prefix(get([a for a in ARGS if a != "--verbose"], 1, joinpath(@__DIR__, "usr")))
products = [
    LibraryProduct(prefix, ["libflint"], :libflint),
]

# Download binaries from hosted location
bin_prefix = "https://github.com/JuliaBinaryWrappers/FLINT_jll.jl/releases/download/FLINT-v2.6.3+0"

# Listing of files generated by BinaryBuilder:
download_info = Dict(
    Linux(:aarch64, libc=:glibc) => ("$bin_prefix/FLINT.v2.6.3.aarch64-linux-gnu.tar.gz", "4b18b7604e89cb590dad2bd799b8656ad01bd2243dba55f594e98ad53bbc41e9"),
    Linux(:aarch64, libc=:musl) => ("$bin_prefix/FLINT.v2.6.3.aarch64-linux-musl.tar.gz", "9f9654432778026f7124fc0693effdb1543590670e8eda16b23609ca5f625990"),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf) => ("$bin_prefix/FLINT.v2.6.3.armv7l-linux-gnueabihf.tar.gz", "a54d8b4b824a12a6b7740fc75e61bab51c3b000dcd11812c7ca6eb8c11b3dcb0"),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf) => ("$bin_prefix/FLINT.v2.6.3.armv7l-linux-musleabihf.tar.gz", "22afb927dc492cafad3734773bea0fe28609d5d64db23214c59fbdd53b5d3b9a"),
    Linux(:i686, libc=:glibc) => ("$bin_prefix/FLINT.v2.6.3.i686-linux-gnu.tar.gz", "944c80b90c7dd074dfd215f89a83d294bdd8e2574dd4bd1caa5ddaf704dd1350"),
    Linux(:i686, libc=:musl) => ("$bin_prefix/FLINT.v2.6.3.i686-linux-musl.tar.gz", "928773f9e7ab730172f60e9d2829b924d7c0e389b30db0f48d363223ad6cc82a"),
    Windows(:i686) => ("$bin_prefix/FLINT.v2.6.3.i686-w64-mingw32.tar.gz", "30f9602d766274e7e70c73a9c32bb13a1f38fdd0da37572e357b429f6ff14f1b"),
    Linux(:powerpc64le, libc=:glibc) => ("$bin_prefix/FLINT.v2.6.3.powerpc64le-linux-gnu.tar.gz", "a54af32c5d037088edfee8b9e0216f29418cb6d2d56b10795e6f294c8d523c67"),
    MacOS(:x86_64) => ("$bin_prefix/FLINT.v2.6.3.x86_64-apple-darwin14.tar.gz", "aa7be84ebc3c2fc47854916a77135297a0044dd5eb4bf735f89f746ef99adb9e"),
    Linux(:x86_64, libc=:glibc) => ("$bin_prefix/FLINT.v2.6.3.x86_64-linux-gnu.tar.gz", "e6dea82485f16668a3fa81e753f1354a4af9651db339adf64ea8459ebaff9cce"),
    Linux(:x86_64, libc=:musl) => ("$bin_prefix/FLINT.v2.6.3.x86_64-linux-musl.tar.gz", "0f744830aedfd72e85ab1d33ab5a30d27962a2a649ef5685f981f846682debff"),
    FreeBSD(:x86_64) => ("$bin_prefix/FLINT.v2.6.3.x86_64-unknown-freebsd11.1.tar.gz", "fca5d76fae20fe79238354bf0bac7cc2721c288cf5a2333d2d0d004f08399217"),
    Windows(:x86_64) => ("$bin_prefix/FLINT.v2.6.3.x86_64-w64-mingw32.tar.gz", "e47b0721a8cd491fe49ed4d5a1bdc4cf5022eecb70ea763f1bce0a152db1551e"),
)

# Install unsatisfied or updated dependencies:
unsatisfied = any(!satisfied(p; verbose=verbose) for p in products)
dl_info = choose_download(download_info, platform_key_abi())
if dl_info === nothing && unsatisfied
    # If we don't have a compatible .tar.gz to download, complain.
    # Alternatively, you could attempt to install from a separate provider,
    # build from source or something even more ambitious here.
    error("Your platform (\"$(Sys.MACHINE)\", parsed as \"$(triplet(platform_key_abi()))\") is not supported by this package!")
end

# If we have a download, and we are unsatisfied (or the version we're
# trying to install is not itself installed) then load it up!
if unsatisfied || !isinstalled(dl_info...; prefix=prefix)
    # Download and install binaries
    install(dl_info...; prefix=prefix, force=true, verbose=verbose)
end

# Write out a deps.jl file that will contain mappings for our products
write_deps_file(joinpath(@__DIR__, "deps.jl"), products, verbose=verbose)
