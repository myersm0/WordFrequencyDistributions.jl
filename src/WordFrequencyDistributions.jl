
module WordFrequencyDistributions

using NamedArrays
using StatsBase
using Match
using Chain

abstract type CheckStyle end
struct Safe <: CheckStyle end
struct Fast <: CheckStyle end

include("corpora.jl")
include("empirical.jl")
include("estimators.jl")

end
