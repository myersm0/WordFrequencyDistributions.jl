
module WordFrequencyDistributions

using Chain
using StatsBase

abstract type CheckStyle end
struct Safe <: CheckStyle end
struct Fast <: CheckStyle end
export CheckStyle, Safe, Fast

include("corpora.jl")
export Corpus, getindex, sample, permute, occursin, occurrences, m⃗, M, spectrum
export intervals, partition

include("zipf.jl")
export ZipfRank

include("empirical.jl")
export ω, V, N, f, p, g

include("estimators.jl")
export ZipfianEstimator, Zipf, GaleSampson, NaranBalasub
export CharacteristicEstimator, Yule, Simpson, Guiraud, Brunet
export Sichel, Honore, Herdan, ZipfSize
export ExpectationEstimator, BinomialExpectation, PoissonExpectation, SampleExpectation
export HubertLabbe
export C, CL, P, GoodTuring

include("dispersion.jl")
export dispersion

include("loss.jl")
export LossFunction, MSE, MSEr, C1, C2, C3
export loss

end

