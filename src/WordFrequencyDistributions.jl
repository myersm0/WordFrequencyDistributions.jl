
module WordFrequencyDistributions

using NamedArrays
using StatsBase
using Match
using Chain
import Lazy

abstract type CheckStyle end
struct Safe <: CheckStyle end
struct Fast <: CheckStyle end
export CheckStyle, Safe, Fast

include("corpora.jl")
export Corpus, getindex, sample, occursin, occurrences, f, m, M, spectrum

include("zipf.jl")
export ZipfRank

include("empirical.jl")
export ω, V, N, f, p, g

include("estimators.jl")
export GaleSampson, NaranBalasub, Yule, Simpson, Guiraud, Sichel, Honore, Herdan
export C

end
