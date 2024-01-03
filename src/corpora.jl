
@kwdef struct Corpus{T <: Integer}
	source::Vector{T}
	ω::Vector{String}
	ωmap::Dict{String, T} = Dict{String, T}(w => i for (i, w) in enumerate(ω))
	V::Int = length(ω)
	N::Int = length(source)
	f::Ref{Union{Nothing, Vector{Int}}} = nothing        # occurence counts for each type
	spectrum::Ref{Union{Nothing, Vector{Int}}} = nothing # tabulation of occurrence counts
	m⃗::Ref{Union{Nothing, Vector{Int}}} = nothing        # the indices of non-zero spectra
end

"""
    Corpus{T}(text)

Initialize a `Corpus{T}` from a vector of strings `text`. The token count should
not exceed `typemax(T)`.
"""
function Corpus{T}(text::Vector{String}) where T <: Integer
	N = length(text)
	ω = unique(text)
	length(ω) <= typemax(T) || error("Number of unique words exceeds typemax for Corpus{$(T)}")
	V = length(ω)
	ωmap = Dict{String, T}(w => i for (i, w) in enumerate(ω))
	word_indices = [ωmap[w] for w in text]
	return Corpus{T}(source = word_indices, ω = ω)
end

"""
    Corpus(text)

Initialize a `Corpus{UInt16}` from a vector of strings `text`.
"""
Corpus(text::Vector{String}) = Corpus{UInt16}(text)

"""
    getindex(c, rng)

Turn `Corpus c` into a smaller corpus using only its tokens in `rng`.
"""
function Base.getindex(
		c::Corpus{T}, rng::Union{AbstractVector{<: Integer}, AbstractRange{<: Integer}}
	) where T <: Integer
	source = c.source[rng]
	w_indices = sort(unique(source))
	ranks = denserank(source)
	ω = c.ω[w_indices]
	return Corpus{T}(source = ranks, ω = ω)
end

"""
    getindex(c, w)

Get a binary occurrence vector of the word `w` in `Corpus c`.
"""
function Base.getindex(c::Corpus, w::String)
	return c.source .== c.ωmap[w]
end

"""
    sample(c, args...; kwargs...)

Make a new `Corpus` by randomly sampling the tokens from `c`.
"""
function StatsBase.sample(c::Corpus, args...; kwargs...)
	return c[sample(1:N(c), args...; kwargs...)]
end

"""
    sample(c, args...; kwargs...)

Make a new `Corpus` by shuffling all the tokens from `c`.
"""
function permute(c::Corpus)
	return sample(c, N(c); replace = false)
end

Base.occursin(w::String, c::Corpus) = haskey(c.ωmap, w)

"""
    intervals(c; k)

Get `k` (default: 20) equispaced points from 1 to N(c)`.
"""
function intervals(c::Corpus{T}; k::Int = 20) where T
	step_size = N(c) ÷ k
	step_size > 0 || error(DomainError)
	rem = N(c) % k
	rng = range(step_size, step_size * k, k) |> collect .|> T
	rng[k:-1:(k - rem + 1)] .+= rem:-1:1
	return rng
end

"""
	 partition(c; k, endpoints)

Partition `c::Corpus` into a `Vector{Corpus}` of length `k` (by default, 40). Or supply 
a vector of predefined `endpoints` for the partitions, in which case `k` is ignored.
"""
function partition(
		c::Corpus; k::Int = 20, endpoints::Vector{<: Integer} = intervals(c; k = k)
	)
	return [c[1 + (i == 1 ? 0 : endpoints[i - 1]):endpoints[i]] for i in eachindex(endpoints)]
end

function Base.show(io::IO, mime::MIME"text/plain", c::Corpus)
	print(io, "Corpus with $(N(c)) tokens, $(V(c)) types")
end

function recover(c::Corpus)
	return [c.ω[i] for i in c.source]
end

function Base.:(==)(c1::Corpus, c2::Corpus)
	return recover(c1) == recover(c2)
end


# ===== lazy field initializers ================================================

function f(c::Corpus)
	isnothing(c.f[]) && (c.f[] = counts(c.source))
	return c.f[]
end

function spectrum(c::Corpus)
	isnothing(c.spectrum[]) && (c.spectrum[] = counts(f(c)))
	return c.spectrum[]
end

function m⃗(c::Corpus)
	isnothing(c.m⃗[]) && (c.m⃗[] = findall(spectrum(c) .!= 0))
	return c.m⃗[]
end

function M(c::Corpus)
	return m⃗(c)[end]
end


