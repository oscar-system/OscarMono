using BinaryProvider # requires BinaryProvider 0.3.0 or later

# Parse some basic command-line arguments
const verbose = "--verbose" in ARGS
const prefix = Prefix(get([a for a in ARGS if a != "--verbose"], 1, joinpath(@__DIR__, "usr")))
products = [
    LibraryProduct(prefix, ["libreadline"], :libreadline),
]

# Download binaries from hosted location
bin_prefix = "https://github.com/benlorenz/readlineBuilder/releases/download/v8.0"

# Listing of files generated by BinaryBuilder:
download_info = Dict(
    Linux(:aarch64, libc=:glibc) => ("$bin_prefix/readline.v8.0.0.aarch64-linux-gnu.tar.gz", "c8824af52797b435fc7992d5c217f99e6e618f42440a3bea9e5edad29ce168e7"),
    Linux(:aarch64, libc=:musl) => ("$bin_prefix/readline.v8.0.0.aarch64-linux-musl.tar.gz", "5e1ea90d66acfc9c5c643a8835700ff112bc8e54f4aaab43e9b5fb4f7b0458b4"),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf) => ("$bin_prefix/readline.v8.0.0.arm-linux-gnueabihf.tar.gz", "2132c40f452fe8a574e76cbc9ffbdb388253595dd3bb9a4a1ced9ea3101149e9"),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf) => ("$bin_prefix/readline.v8.0.0.arm-linux-musleabihf.tar.gz", "5732c3f526dd7433152ece852984f70d6e305f3c1340d0c59b41342f939f7320"),
    Linux(:i686, libc=:glibc) => ("$bin_prefix/readline.v8.0.0.i686-linux-gnu.tar.gz", "c09da1a51002492f534e65dad8594162b2cfe1af249f53bdc86a08066c61ccf7"),
    Linux(:i686, libc=:musl) => ("$bin_prefix/readline.v8.0.0.i686-linux-musl.tar.gz", "b02ab861e7da295c6381fd5a96741b720e82ef874ccbe87d66792338b027635e"),
    Linux(:powerpc64le, libc=:glibc) => ("$bin_prefix/readline.v8.0.0.powerpc64le-linux-gnu.tar.gz", "e9c665964f77d18e680a1f4f3412bc567dde79a852ae272f193e0932e3f99d47"),
    MacOS(:x86_64) => ("$bin_prefix/readline.v8.0.0.x86_64-apple-darwin14.tar.gz", "65a031389517c62c582afc9cc25e2d0413b3fe58a02d02e39a02a28bcedc9d85"),
    Linux(:x86_64, libc=:glibc) => ("$bin_prefix/readline.v8.0.0.x86_64-linux-gnu.tar.gz", "7c81840317c8b83be0a96665f36e4b899f71734b5001a925e4a9ea2bc62feb2f"),
    Linux(:x86_64, libc=:musl) => ("$bin_prefix/readline.v8.0.0.x86_64-linux-musl.tar.gz", "54c1bbcd69b37d4b46ed5e79c6ab18ff530e9f8e994b0611cffbb8e89d589f47"),
    FreeBSD(:x86_64) => ("$bin_prefix/readline.v8.0.0.x86_64-unknown-freebsd11.1.tar.gz", "9337640aa729f1fbfe3d04233d1b613399c686341e1c6bbb7ec2ef2e7d0b40e0"),
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
