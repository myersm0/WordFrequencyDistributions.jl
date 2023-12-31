
abstract type LossFunction end
struct MSE <: LossFunction end
struct MSEr <: LossFunction end

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

