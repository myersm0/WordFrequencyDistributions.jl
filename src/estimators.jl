
abstract type Estimator end

# ===== Zipfian estimators =====
abstract type ZipfianEstimator <: Estimator end
struct Zipf <: ZipfianEstimator end
struct GaleSampson <: ZipfianEstimator end
struct NaranBalasub <: ZipfianEstimator end

function V(::ZipfianEstimator, m::Integer, c::Corpus; kwargs...) end

function V(::Zipf, m::Integer, c::Corpus)
	return V(c) / (m * (m + 1))
end

"Gale and Sampson (1.12)"
function V(::GaleSampson, m::Integer, c::Corpus)
	mp(m::Integer, c::Corpus) = m⃗(c)[findlast(m⃗(c) .< m)]
	mf(m::Integer, c::Corpus) = m⃗(c)[findfirst(m⃗(c) .> m)]
	m in m⃗(c) || return NaN
	m == 1 && return V(1, c)
	m == M(c) && return 2V(m, c) / (2m - mp(m, c))
	return 2V(m, c) / (mf(m, c) - mp(m, c))
end

"Naranan and Balasubrahmanyan (1.14)"
function V(::NaranBalasub, m::Integer, c::Corpus; C::Real, μ::Real, γ::Real)
	return C * exp(-μ / m) / m^γ
end


# ===== "characteristic constants" C =====
abstract type CharacteristicEstimator <: Estimator end
struct Yule <: CharacteristicEstimator end
struct Simpson <: CharacteristicEstimator end
struct Guiraud <: CharacteristicEstimator end
struct Brunet <: CharacteristicEstimator end
struct Sichel <: CharacteristicEstimator end
struct Honore <: CharacteristicEstimator end
struct Herdan <: CharacteristicEstimator end
struct ZipfSize <: CharacteristicEstimator end

function C(::CharacteristicEstimator, c::Corpus; kwargs...) end

"Yule (1.15)"
function C(::Yule, c::Corpus)
	return 1e4 * (sum(m^2 * V(m, c) for m in m⃗(c)) - N(c)) / N(c)^2
end

"Simpson (1.16)"
function C(::Simpson, c::Corpus)
	return sum(V(m, c) * (m / N(c)) * ((m - 1) / (N(c) - 1)) for m in m⃗(c))
end

"Guiraud (1.17)"
function C(::Guiraud, c::Corpus)
	return V(c) / sqrt(N(c))
end

"Brunet (1.18)"
function C(::Brunet, c::Corpus; a::Real = 0.17)
	return N(c)^(V(c)^-a)
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

"Baayen's Zipf size characteristic (p. 80)"
function C(::ZipfSize, c::Corpus; k::Int = 20)::Int
	endpoints = intervals(c; k = k)
	l = [
		loss(
			MSEr(), c[1:t];
			y = (m, c) -> V(m, c),
			yhat = (m, _) -> V(BinomialExpectation(), c; t = t) / (m * (m + 1))
		) for t in endpoints
	]
	return endpoints[argmin(l)]
end


# ===== interpolation, extrapolation for population estimates =====
abstract type ExpectationEstimator <: Estimator end
struct BinomialExpectation <: ExpectationEstimator end
struct PoissonExpectation <: ExpectationEstimator end
struct SampleExpectation <: ExpectationEstimator end
struct HubertLabbe <: ExpectationEstimator end
struct GoodTuring <: ExpectationEstimator end

"Expected number of terms in a corpus of `N(c)` tokens at text-time `t`"
function V(::ExpectationEstimator, c::Corpus; t::Integer) end

"Expected number of terms with frequency `m` in a corpus of `N(c)` tokens at text-time `t`"
function V(::ExpectationEstimator, m::Integer, c::Corpus; t::Integer) end

"(2.41)"
function V(::BinomialExpectation, m::Integer, c::Corpus; t::Integer)
	ratio = t / N(c)
	log_ratio = log(ratio)
	log_one_minus_ratio = log1p(-ratio)
	log_terms = [
		log(V(k, c)) +
		loggamma(k + 1) - loggamma(m + 1) - loggamma(k - m + 1) +
		m * log_ratio +
		(k - m) * log_one_minus_ratio
		for k in filter(k -> k >= m, m⃗(c))
	]
	return exp(logsumexp(log_terms))
end

# helper for the above
function logsumexp(log_values)
	 maxlog = maximum(log_values)
	 return maxlog + log(sum(exp(x - maxlog) for x in log_values))
end

"(2.42)"
function V(::BinomialExpectation, c::Corpus; t::Integer)
	ratio = t / N(c)
	return V(c) - sum(V(m, c) * (1 - ratio)^m for m in m⃗(c))
end

"(2.53)"
function V(::PoissonExpectation, c::Corpus; t::Integer)
	t < N(c) || error("Interpolation via PoissonExpectation requires t < N(c)")
	c′ = c[1:t]
	return sum(1 - exp(-N(c) * p(i, c′)) for i in 1:V(c′))
end

"Approximation of expected vocabulary size; valid only if sample is not LNRE (2.25)"
function V(::SampleExpectation, c::Corpus)
	return sum(1 - exp(-f(i, c)) for i in 1:V(c))
end

"Coefficient of loss (2.26)"
function CL(c::Corpus)
	return (V(c) - V(SampleExpectation(), c)) / V(c)
end

"Vocabulary growth rate (section 2.5)"
function P(e::ExpectationEstimator, c::Corpus; kwargs...)
	return V(e, 1, c; kwargs...) / N(c)
end

"Good-Turing estimate of adjusted sample frequency (2.27)"
function f(::GoodTuring, e::ExpectationEstimator, i::Integer, c::Corpus; kwargs...)
	m = f(i, c)
	m < M(c) || error("Good-Turing doesn't work on the token with Zipf rank 1")
	return (m + 1) * V(e, m + 1, c; kwargs...) / V(e, m, c; kwargs...)
end

"Hubert and Labbe partition-based adjustment (5.8)"
function V(::HubertLabbe, c::Corpus; p::Real, t::Int)
	ratio = t / N(c)
	return p * ratio * V(c) + (1 - p) * sum(V(m, c) * (1 - (1 - ratio)^m) for m in m⃗(c))
end

function V(::HubertLabbe, m::Int, c::Corpus; p::Real, t::Int)
	ratio = t / N(c)
	return p * ratio * V(m, c) + (1 - p) * V(BinomialExpectation(), m, c; t = t)
end




