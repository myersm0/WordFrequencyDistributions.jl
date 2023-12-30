
@kwdef struct Corpus{T <: Integer}
	source::Vector{T}
	ω::Vector{String}
	occurrences::SparseArrays.SparseMatrixCSC{Bool, T}
	ωmap::Dict{String, T} = Dict{String, T}(w => i for (i, w) in enumerate(ω))
	V::T = length(ω)
	N::T = length(source)
	f::Ref{Union{Nothing, Vector{T}}} = nothing        # occurence counts for each type
	spectrum::Ref{Union{Nothing, Vector{T}}} = nothing # a tabulation of occurrence counts
	m⃗::Ref{Union{Nothing, Vector{T}}} = nothing        # the indices of non-zero spectra
end

"""
    Corpus{T}(text)

Initialize a `Corpus{T}` from a vector of strings `text`. The token count should
not exceed `typemax(T)`.
"""
function Corpus{T}(text::Vector{String}) where T <: Integer
	N = length(text)
	N <= typemax(T) || error("Token count exceeds typemax for Corpus{$(T)}")
	ω = unique(text)
	V = length(ω)
	ωmap = Dict{String, T}(w => i for (i, w) in enumerate(ω))
	word_indices = [ωmap[w] for w in text]
	occurrences = SparseArrays.sparse(word_indices, 1:N, trues(N))
	return Corpus{T}(source = word_indices, ω = ω, occurrences = occurrences)
end

"""
    Corpus(text)

Initialize a `Corpus{Int32}` from a vector of strings `text`.
"""
Corpus(text::Vector{String}) = Corpus{Int32}(text)

"""
    getindex(c, rng)

Turn `Corpus c` into a smaller corpus using only its tokens in `rng`.
"""
function Base.getindex(
		c::Corpus{T}, rng::Union{AbstractVector{<: Integer}, AbstractRange{<: Integer}}
	) where T <: Integer
	source = c.source[rng]
	w_indices = unique(source)
	ω = c.ω[w_indices]
	occurrences = c.occurrences[w_indices, rng]
	return Corpus{T}(source = source, ω = ω, occurrences = occurrences)
end

"""
    getindex(c, w)

Get the sparse occurrence vector of the word `w` in `Corpus c`.
"""
function Base.getindex(c::Corpus, w::String)
	return c.occurrences[c.ωmap[w], :]
end

"""
    getindex(c, w)

Get a sparse occurrence matrix of a set of words from `Corpus c`.
"""
function Base.getindex(c::Corpus, w⃗::Vector{String})
	return c.occurrences[[c.ωmap[w] for w in w⃗], :]
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

"""
	 partition(c; nchunks, chunk_size)

Partition `c::Corpus` into a `Vector{Corpus}` of length `nchunks` (by default, 40).
"""
function partition(c::Corpus; nchunks::Int = 40, chunk_size::Int = N(c) ÷ nchunks)
	return [c[((i - 1) * chunk_size + 1):min(N(c), i * chunk_size)] for i in 1:nchunks]
end

Base.occursin(w::String, c::Corpus) = haskey(c.ωmap, w)

occurrences(c::Corpus) = c.occurrences
occurrences(w::String, c::Corpus) = c[w]

"""
    intervals(c; nsteps = 20)

Get `nsteps` equispaced points from 1 to N(c)`.
"""
function intervals(c::Corpus{T}; nsteps = 20) where T
	step_size = T(round(N(c) / nsteps))
	rng = range(step_size, step_size * nsteps, nsteps) |> collect .|> Int
	rng[end] = N(c)
	return rng
end

function Base.show(io::IO, mime::MIME"text/plain", c::Corpus)
	print(io, "Corpus with $(N(c)) tokens, $(V(c)) types")
end


# ===== lazy field initializers ================================================

function f(c::Corpus)
	isnothing(c.f[]) && (c.f[] = sum(c.occurrences; dims = 2)[:])
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


