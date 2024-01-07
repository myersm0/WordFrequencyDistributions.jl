
abstract type LossFunction end

# ===== MSE and relative MSE loss, defined in Baayen chapters 1 and 2 ==========
abstract type MSELoss end
struct MSE <: MSELoss end
struct MSEr <: MSELoss end

function loss(
		::MSELoss, c::Corpus; 
		y::Function, yhat::Function, spectra::Union{AbstractVector, AbstractRange} = m⃗(c)[1:15]
	)
end

function loss(
		::MSE, c::Corpus; 
		y::Function, yhat::Function, spectra::Union{AbstractVector, AbstractRange} = m⃗(c)[1:15]
	)
	return mean((yhat(m, c) - y(m, c))^2 for m in spectra)
end

function loss(
		::MSEr, c::Corpus; 
		y::Function, yhat::Function, spectra::Union{AbstractVector, AbstractRange} = m⃗(c)[1:15]
	)
	return mean(((yhat(m, c) - y(m, c)) / V(c))^2 for m in spectra)
end


# ===== cost functions defined in Baayen chapter 3, Parametric Models ==========
abstract type ParametricLoss end
struct C1 <: ParametricLoss end
struct C2 <: ParametricLoss end
struct C3 <: ParametricLoss end

function loss(::ParametricLoss, c::Corpus; r::Int, e::Estimator) end

"(3.65)"
function loss(::C1, c::Corpus; r::Int, e::Estimator)
	return abs(V(e, c) - V(c)) + sum(abs(V(e, m, c) - V(m, c)) for m in m⃗(c)[1:r])
end

"(3.66)"
function loss(::C2, c::Corpus; r::Int, e::Estimator)
	return (1 / (r + 2)) * (
		(V(c) - E(e, c))^2 +
		sum((V(m, c) - V(e, m, c))^2 for m in m⃗(c)[1:r]) +
		sum(V(m, c) - V(e, m, c) for m in m⃗(c)[r + 1:end])^2
	)
end

"like C2, but 'augmented with an extra term to keep the number of tokens balanced' (3.67)"
function loss(::C3, c::Corpus; r::Int, e::Estimator)
	return (1 / (r + 2)) * (
		(V(c) - E(e, c))^2 +
		sum((V(m, c) - V(e, m, c))^2 for m in m⃗(c)[1:r]) +
		sum(V(m, c) - V(e, m, c) for m in m⃗(c)[r + 1:end])^2 +
		(N(c) - sum(m * V(e, m, c) for m in m⃗(c)))^2
	)
end

