
"""
    dispersion(c; k = 40, kwargs...)

Get a `BitMatrix` representing the dispersion of `c`'s vocabulary over `k` 
equally sized partitions. The result will be of dimensions `V(c) x k`.

Rather than specifying `k`, you may instead pass in a vector of `endpoints`.
(See `partition` for details.)
"""
function dispersion(c::Corpus; k::Int = 40, kwargs...)
	partitions = partition(c; k = k, kwargs...)
	return dispersion(partitions)
end

function dispersion(partitions::Vector{Corpus{T1, T2}}) where {T1, T2}
	return @chain partitions begin
		f.(_)
		hcat(_...)
		.!iszero.(_)
	end
end


