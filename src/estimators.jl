
abstract type Estimator end

# ===== Zipfian smoothers =====
abstract type ZipfianEstimator <: Estimator end
struct GaleSampson <: ZipfianEstimator end
struct NaranBalasub <: ZipfianEstimator end

function V(::ZipfianEstimator, m::Int, c::Corpus; kwargs...) end

"Gale and Sampson (1.12)"
function V(::GaleSampson, m::Int, c::Corpus)
	mp(m::Int, c::Corpus) = c.m[findfirst(0 .< c.m .< m)]
	mf(m::Int, c::Corpus) = c.m[findfirst(0 .> c.m .> m)]
	m == 1 && return V(1, c)
	m == c.M && return 2V(m, c) / (2m - mp(m, c))
	return 2V(m, c) / (mf(m, c) - mp(m, c))
end

"Naranan and Balasubrahmanyan (1.14)"
function V(::NaranBalasub, m::Int, c::Corpus; C::Real, μ::Real, γ::Real)
	return C * exp(-μ / m) / m^γ
end


# ===== "characteristic constants" C =====
abstract type CharacteristicEstimator <: Estimator end
struct Yule <: CharacteristicEstimator end
struct Simpson <: CharacteristicEstimator end
struct Guiraud <: CharacteristicEstimator end
struct Sichel <: CharacteristicEstimator end
struct Honore <: CharacteristicEstimator end
struct Herdan <: CharacteristicEstimator end

function C(::CharacteristicEstimator, c::Corpus; kwargs...) end

"Yule (1.15)"
function C(::Yule, c::Corpus)
	return 1e4 * sum(m^2 * V(m, c) - N(c) for m in c.m) / N(c)^2
end

"Simpson (1.16)"
function C(::Simpson, c::Corpus)
	return sum(V(m, c) * (m / N(c)) * ((m - 1) / (N(c) - 1)) for m in c.m)
end

"Guiraud (1.17)"
function C(::Guiraud, c::Corpus)
	return V(c) / sqrt(N(c))
end

"Sichel's proportion of dis legomena"
function C(::Sichel, c::Corpus)
	return V(2, c) / V(c)
end

"Honore (1.20)"
function C(::Honore, c::Corpus)
	return 100 * log(N(c)) / (1 - (V(1, c) / V(c)))
end

"Herdan (1.21)"
function C(::Herdan, c::Corpus; a::Real)
	return a * N^(log(V(c)) / log(N(c)))
end



