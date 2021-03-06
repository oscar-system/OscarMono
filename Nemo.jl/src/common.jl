###############################################################################
#
#   Random generation
#
###############################################################################

rand(x::Union{AnticNumberField,FlintIntegerRing}, v) =
    rand(Random.GLOBAL_RNG, x, v)

rand(x::Union{FlintPuiseuxSeriesRing,FlintPuiseuxSeriesField}, v1, v2, v...) =
    rand(Random.GLOBAL_RNG, x, v1, v2, v...)

rand(x::FmpzLaurentSeriesRing, v1, v...) = rand(Random.GLOBAL_RNG, x, v1, v...)
