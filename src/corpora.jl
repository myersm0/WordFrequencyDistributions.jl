
@kwdef struct Corpus
	source::Vector{String}
	ω::Vector{String}
	occurrences::NamedVector{BitVector}
	V::Int = length(ω)
	N::Int = V == 0 ? 0 : length(occurrences[1])
	f::NamedVector{Int} = NamedArray([sum(x) for x in occurrences], ω)
	spectrum::Vector{Int} = counts(f)
	m = findall(spectrum .!= 0)
	M = m[end]
end

function Corpus(v::Vector{String})
	ω = unique(v)
	occurrences = NamedArray([v .== w for w in ω], ω)
	return Corpus(source = v, ω = ω, occurrences = occurrences)
end

function Base.getindex(
		c::Corpus, rng::Union{AbstractVector{T}, AbstractRange{T}}
	) where T <: Integer
	source = c.source[rng]
	ω = unique(source)
	occurrences = NamedArray([c.occurrences[w][rng] for w in ω], ω)
	return Corpus(source = source, ω = ω, occurrences = occurrences)
end

function StatsBase.sample(c::Corpus, args...; kwargs...)
	inds = sample(1:N(c), args...; kwargs...)
	return c[inds]
end

Base.occursin(w::String, c::Corpus) = haskey(c.occurrences.dicts[1], w)

function Base.:(==)(c1::Corpus, c2::Corpus)
	return ω(c1) == ω(c2) && c1.occurrences == c2.occurrences
end

occurrences(w::String, c::Corpus) = c.occurrences[w]


