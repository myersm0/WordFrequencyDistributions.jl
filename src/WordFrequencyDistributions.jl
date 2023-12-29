
module WordFrequencyDistributions

using StatsBase
using Match
using Chain
import SparseArrays
import Lazy

abstract type CheckStyle end
struct Safe <: CheckStyle end
struct Fast <: CheckStyle end
export CheckStyle, Safe, Fast

include("corpora.jl")
export Corpus, getindex, sample, permute, occursin, occurrences, m⃗, M, intervals

include("zipf.jl")
export ZipfRank

include("empirical.jl")
export ω, V, N, f, p, g

include("estimators.jl")
export ZipfianEstimator, Zipf, GaleSampson, NaranBalasub
export CharacteristicEstimator, Yule, Simpson, Guiraud, Sichel, Honore, Herdan, ZipfSize
export ExpectationEstimator, BinomialExpectation, PoissonExpectation

end

