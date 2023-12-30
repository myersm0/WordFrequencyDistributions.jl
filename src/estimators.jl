
abstract type Estimator end

# ===== Zipfian estimators =====
abstract type ZipfianEstimator <: Estimator end
struct Zipf <: ZipfianEstimator end
struct GaleSampson <: ZipfianEstimator end
struct NaranBalasub <: ZipfianEstimator end

function V(::ZipfianEstimator, m::Int, c::Corpus; kwargs...) end

function V(::Zipf, m::Int, c::Corpus)
	return V(c) / (m * (m + 1))
end

"Gale and Sampson (1.12)"
function V(::GaleSampson, m::Int, c::Corpus)
	mp(m::Int, c::Corpus) = m⃗(c)[findlast(m⃗(c) .< m)]
	mf(m::Int, c::Corpus) = m⃗(c)[findfirst(m⃗(c) .> m)]
	m in m⃗(c) || return NaN
	m == 1 && return V(1, c)
	m == M(c) && return 2V(m, c) / (2m - mp(m, c))
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
struct ZipfSize <: CharacteristicEstimator end

function C(::CharacteristicEstimator, c::Corpus; kwargs...) end

"Yule (1.15)"
function C(::Yule, c::Corpus)
	return 1e4 * sum(m^2 * V(m, c) - N(c) for m in m(c)) / N(c)^2
end

"Simpson (1.16)"
function C(::Simpson, c::Corpus)
	return sum(V(m, c) * (m / N(c)) * ((m - 1) / (N(c) - 1)) for m in m(c))
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

# TODO
function C(::ZipfSize, c::Corpus) end

# ===== interpolation, extrapolation for population estimates =====
abstract type ExpectationEstimator <: Estimator end
struct BinomialExpectation <: ExpectationEstimator end
struct PoissonExpectation <: ExpectationEstimator end

"Expected number of terms with frequency `m` in a corpus of N′ tokens"
function V(::ExpectationEstimator, c::Corpus; n::Int) end

"Expected vocabulary size in a corpus of N′ tokens"
function V(::ExpectationEstimator, m::Int, c::Corpus; n::Int) end

"(2.41)"
function V(::BinomialExpectation, m::Int, c::Corpus; n::Int)
	ratio = n / N(c)
	ratio < 1 || error(DomainError)
	return sum(
		V(k, c) * binomial(BigInt(k), m) * ratio^m * (1 - ratio)^(k - m) 
		for k in filter(k -> k >= m, m⃗(c))
	)
end

"(2.42)"
function V(::BinomialExpectation, c::Corpus; n::Int)
	ratio = n / N(c)
	ratio < 1 || error(DomainError)
	return V(c) - sum(V(m, c) * (1 - ratio)^m for m in m⃗(c))
end

"(2.53)"
function V(::PoissonExpectation, c::Corpus; n::Int)
	c′ = c[1:n]
	return sum(1 - exp(-N(c) * p(i, c′)) for i in 1:V(c′))
end

# TODO
# Ρ (growth rate, 2.20)
# CL (coef. of loss, 2.26)
# Good-Turing (2.27, 2.36 - 2.37)





