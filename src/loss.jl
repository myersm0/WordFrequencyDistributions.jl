
abstract type LossFunction end
struct MSE <: LossFunction end
struct MSEr <: LossFunction end
struct C1 <: LossFunction end
struct C2 <: LossFunction end
struct C3 <: LossFunction end

function loss(
		::LossFunction, c::Corpus; 
		y::Function, yhat::Function, spectra::Union{AbstractVector, AbstractRange} = 1:15
	)
end

function loss(
		::MSE, c::Corpus; 
		y::Function, yhat::Function, spectra::Union{AbstractVector, AbstractRange} = 1:15
	)
	return mean((yhat(m, c) - y(m, c))^2 for m in intersect(spectra, m⃗(c)))
end

function loss(
		::MSEr, c::Corpus; 
		y::Function, yhat::Function, spectra::Union{AbstractVector, AbstractRange} = 1:15
	)
	return mean(((yhat(m, c) - y(m, c)) / V(c))^2 for m in intersect(spectra, m⃗(c)))
end

"(3.65)"
function loss(::C1, c::Corpus)
	return abs(E(BinomialExpectation(), c) - V(c)) + abs(E(BinomialExpectation() ,1, c)) - V(1, c)
end

"(3.66)"
function loss(::C2, c::Corpus; r::Int)
	return (1 / (r + 2)) * (
		(V(c) - E(BinomialExpectation(), c))^2 +
		sum((V(m, c) - V(BinomialExpectation(), m, c))^2 for m in intersect(1:r, m⃗(c))) +
		sum(V(m, c) - V(BinomialExpectation(), m, c) for m in setdiff(m⃗(c), 1:r))^2
	)
end

"like C2, but 'augmented with an extra term to keep the number of tokens balanced' (3.67)"
function loss(::C3, c::Corpus; r::Int)
	return (1 / (r + 2)) * (
		(V(c) - E(BinomialExpectation(), c))^2 +
		sum((V(m, c) - V(BinomialExpectation(), m, c))^2 for m in intersect(1:r, m⃗(c))) +
		sum(V(m, c) - V(BinomialExpectation(), m, c) for m in setdiff(m⃗(c), 1:r))^2
		(N(c) - sum(m * V(BinomialExpectation(), m, c) for m in m⃗(c)))^2
	)
end

